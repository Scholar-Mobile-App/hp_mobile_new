import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';
import '../../services/travel_visit_service.dart';

const _purposes = <String, IconData>{
  'Client Visit': Icons.business_center,
  'Site Visit': Icons.apartment,
  'Installation': Icons.build,
  'Maintenance': Icons.settings,
  'Collection': Icons.credit_card,
  'Delivery': Icons.inbox_outlined,
  'Meeting': Icons.groups,
  'Other': Icons.more_horiz,
};

// Emoji, not Material icons: the released app's icon font has no vehicle icons and a
// Shorebird patch cannot add any. Emoji are drawn by the phone's own font.
const _vehicles = <String, Object>{
  'Two Wheeler': '🏍️',
  'Four Wheeler': '🚗',
  'Public Transport': '🚌',
  'Walking': '🚶',
  'Other': Icons.more_horiz,
};

// The app's brand palette (same as My Attendance).
const _navy = Color(0xFF1F2A6D);
const _navyLight = Color(0xFF2E3A8C);
const _accent = Color(0xFF2F80FF); // the app's secondary blue
const _accentLight = Color(0xFF8DBBFF);
const _slate = Color(0xFF475569);
const _slateLight = Color(0xFF64748B);
const _pageBg = Color(0xFFF8F9FA);

/// Travel Visit: start a trip, let the phone record its route about once a
/// minute, end the trip. Tracking lives in [TravelTracker] (a singleton), so
/// leaving this screen does not stop it.
class TravelVisitScreen extends StatefulWidget {
  const TravelVisitScreen({super.key});

  @override
  State<TravelVisitScreen> createState() => _TravelVisitScreenState();
}

class _TravelVisitScreenState extends State<TravelVisitScreen> {
  final _tracker = TravelTracker.instance;
  String _purpose = _purposes.keys.first;
  String _vehicle = _vehicles.keys.first;

  TravelVisit? _active;
  List<TravelVisit> _history = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool _needsAlways = false;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _tracker.addListener(_onTracker);
    // Ticks the on-screen trip timer.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _active != null) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tracker.removeListener(_onTracker);
    _clock?.cancel();
    super.dispose();
  }

  void _onTracker() {
    if (!mounted) return;
    // The server ended it (web / another phone): the tracker stopped itself.
    if (_active != null && _tracker.visitId == null) {
      setState(() => _active = null);
      _load();
    } else {
      setState(() {});
    }
  }

  String? get _token {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return auth.originalToken ?? auth.currentUser?.token;
  }

  Future<void> _load() async {
    final token = _token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'You are signed out. Please log in again.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = TravelVisitApi(token);
      final results = await Future.wait([api.active(), api.mine()]);
      final active = results[0] as TravelVisit?;
      final history = results[1] as List<TravelVisit>;

      if (active != null && !(_tracker.isTracking && _tracker.visitId == active.id)) {
        // A trip is open on the server but this phone is not recording it
        // (app was restarted). Pick it back up if we are allowed to.
        if (await TravelPermissions.ensure() == null) {
          await _tracker.begin(token, active.id, resume: true);
        }
      }
      _needsAlways = active != null && !await TravelPermissions.hasAlways();

      if (!mounted) return;
      setState(() {
        _active = active;
        _history = history;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<Position> _currentPosition() => Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );

  Future<void> _start() async {
    final token = _token;
    if (token == null || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final problem = await TravelPermissions.ensure();
      if (problem != null) throw TravelException(problem);

      final pos = await _currentPosition();
      final address = await TravelPermissions.addressOf(pos.latitude, pos.longitude);
      final visit = await TravelVisitApi(token).start(
        at: pos,
        address: address,
        purpose: _purpose,
        vehicleType: _vehicle,
      );
      await _tracker.begin(token, visit.id, first: pos);
      _needsAlways = !await TravelPermissions.hasAlways();
      if (!mounted) return;
      setState(() => _active = visit);
      _toast('Trip started. Your location is being recorded.');
      _load();
    } on TravelException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('Could not start the trip: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end() async {
    final token = _token;
    final visit = _active;
    if (token == null || visit == null || _busy) return;

    final result = await showModalBottomSheet<({XFile selfie, String remarks})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => _EndTripSheet(visitNo: visit.visitNo),
    );
    if (result == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pos = await _currentPosition();
      final address = await TravelPermissions.addressOf(pos.latitude, pos.longitude);
      // Everything not yet delivered rides along, so the last stretch is not lost.
      await TravelVisitApi(token).end(
        visit.id,
        at: pos,
        selfiePath: result.selfie.path,
        remarks: result.remarks,
        address: address,
        appDistanceKm: _tracker.distanceKm,
        points: _tracker.takePending(),
      );
      await _tracker.stop();
      if (!mounted) return;
      setState(() => _active = null);
      _toast('Trip ended.');
      _load();
    } on TravelException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('Could not end the trip: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }

  // ── formatting ──────────────────────────────────────────────────────────

  String _clockText(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  String _shortDuration(Duration d) {
    final m = d.inMinutes;
    if (m < 1) return '<1m';
    final h = m ~/ 60;
    return h > 0 ? '${h}h ${m % 60}m' : '${m}m';
  }

  // ── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text('Travel Visit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: _navy,
        surfaceTintColor: _navy,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (_error != null) _errorBanner(_error!),
            if (_loading && _active == null && _history.isEmpty)
              const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()))
            else ...[
              if (_active != null) _activeCard(_active!, scheme) else _startCard(scheme),
              const SizedBox(height: 20),
              if (_active == null) _monthSummary(scheme),
              const SizedBox(height: 8),
              _historySection(scheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorBanner(String text) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: Colors.red.shade900, height: 1.3))),
          InkWell(onTap: () => setState(() => _error = null), child: Icon(Icons.close, size: 18, color: Colors.red.shade700)),
        ]),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))],
      );

  // ── start ───────────────────────────────────────────────────────────────

  Widget _startCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _navy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.location_on, color: _navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Start a new trip', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _navy, fontWeight: FontWeight.w700)),
                Text('Location is recorded every minute', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          _label('Purpose of visit'),
          _optionGrid(_purposes, _purpose, (v) => setState(() => _purpose = v), scheme, columns: 4),
          const SizedBox(height: 18),
          _label('Vehicle'),
          _optionGrid(_vehicles, _vehicle, (v) => setState(() => _vehicle = v), scheme, columns: 5, short: _vehicleShort),
          const SizedBox(height: 18),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _busy ? null : _start,
              icon: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_circle_outline_rounded, size: 26),
              label: Text(_busy ? 'Starting trip…' : 'Start trip', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      );

  static const _vehicleShort = {
    'Two Wheeler': '2 Wheeler',
    'Four Wheeler': '4 Wheeler',
    'Public Transport': 'Transit',
    'Walking': 'Walk',
    'Other': 'Other',
  };

  /// Icon tiles in a fixed grid: eight purposes fit in two rows instead of five.
  Widget _optionGrid(
    Map<String, Object> options,
    String selected,
    ValueChanged<String> onPick,
    ColorScheme scheme, {
    required int columns,
    Map<String, String> short = const {},
  }) {
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: columns >= 5 ? 0.85 : 1.0,
      children: options.entries.map((e) {
        final on = e.key == selected;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onPick(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            decoration: BoxDecoration(
              color: on ? _navy : const Color(0xFFF1F3F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: on ? _navy : Colors.transparent),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (e.value is IconData)
                Icon(e.value as IconData, size: 24, color: on ? _accentLight : Colors.grey.shade700)
              else
                Text(e.value as String, style: const TextStyle(fontSize: 22, height: 1.2)),
              const SizedBox(height: 6),
              Text(
                short[e.key] ?? e.key,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  color: on ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── trip in progress ────────────────────────────────────────────────────

  Widget _activeCard(TravelVisit v, ColorScheme scheme) {
    final locationOff = _tracker.locationOff;
    final tracking = _tracker.isTracking && _tracker.visitId == v.id && !locationOff;
    final elapsed = DateTime.now().difference(v.startAt);
    final offline = _tracker.lastError != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tracking ? [_navy, _navyLight] : [_slate, _slateLight],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            _PulseDot(active: tracking),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tracking ? 'Trip in progress' : (locationOff ? 'Location is off' : 'Trip open · not recording'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(offline ? Icons.cloud_off_outlined : Icons.check_circle_outline, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(offline ? 'Will retry' : 'Synced', style: const TextStyle(color: Colors.white, fontSize: 11)),
              ]),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            [v.visitNo, if (v.purpose != null) v.purpose!].join('  ·  '),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              _clockText(elapsed.isNegative ? Duration.zero : elapsed),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Center(child: Text('Started ${DateFormat('hh:mm a').format(v.startAt)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12))),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _activeStat(Icons.show_chart, '${_tracker.distanceKm.toStringAsFixed(2)} km', 'Distance')),
            const SizedBox(width: 12),
            Expanded(child: _activeStat(Icons.location_on, '${_tracker.pointCount}', 'Locations')),
          ]),
          if (locationOff) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.warning, size: 20, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Turn on your location. Your route is not being recorded while it is off.',
                      style: TextStyle(fontSize: 12, height: 1.3, color: Colors.red.shade900, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => TravelPermissions.requestEnableLocation(openSettings: true),
                    child: const Text('Turn on location'),
                  ),
                ),
              ]),
            ),
          ],
          if (offline && !locationOff) ...[
            const SizedBox(height: 10),
            Text(_tracker.lastError!, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
          ],
          if (_needsAlways) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.info_outline, size: 18, color: _slate),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Set location to "Allow all the time" so the route keeps recording with the screen off.',
                      style: TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await TravelPermissions.requestAlways();
                      final ok = await TravelPermissions.hasAlways();
                      if (mounted) setState(() => _needsAlways = !ok);
                    },
                    child: const Text('Allow all the time'),
                  ),
                ),
              ]),
            ),
          ],
          if (!tracking && !locationOff) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
              onPressed: _busy ? null : _load,
              icon: const Icon(Icons.location_on),
              label: const Text('Resume recording'),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _busy ? null : _end,
              icon: _busy
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _navy))
                  : const Icon(Icons.flag_outlined),
              label: Text(_busy ? 'Please wait…' : 'End trip', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeStat(IconData icon, String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
          ]),
        ]),
      );

  // ── summary + history ───────────────────────────────────────────────────

  Widget _monthSummary(ColorScheme scheme) {
    final now = DateTime.now();
    final month = _history.where((v) => v.startAt.year == now.year && v.startAt.month == now.month).toList();
    final km = month.fold<double>(0, (a, v) => a + v.distance);

    Widget tile(IconData icon, String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(children: [
              Icon(icon, color: _accent),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ]),
            ]),
          ),
        );

    return Row(children: [
      tile(Icons.event_outlined, '${month.length}', 'Trips this month'),
      const SizedBox(width: 12),
      tile(Icons.trending_up, '${km.toStringAsFixed(1)} km', 'Distance this month'),
    ]);
  }

  Widget _historySection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
          child: Text('My trips', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: _navy)),
        ),
        if (_history.isEmpty && !_loading)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: _cardDecoration(),
            child: Center(
              child: Column(children: [
                Icon(Icons.location_on, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('No trips yet', style: TextStyle(color: Colors.grey.shade600)),
              ]),
            ),
          )
        else
          ..._history.map((v) => _historyTile(v, scheme)),
      ],
    );
  }

  Widget _historyTile(TravelVisit v, ColorScheme scheme) {
    final ongoing = v.isOngoing;
    final color = ongoing ? _accent : Colors.green.shade700;
    final end = v.endAt ?? DateTime.now();
    final span = end.difference(v.startAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(children: [
        // Date badge.
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: _navy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(DateFormat('dd').format(v.startAt), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _navy)),
            Text(DateFormat('MMM').format(v.startAt).toUpperCase(), style: const TextStyle(fontSize: 11, color: _accent, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v.purpose ?? 'Trip', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              '${DateFormat('hh:mm a').format(v.startAt)}'
              '${v.endAt != null ? ' – ${DateFormat('hh:mm a').format(v.endAt!)}' : ' – now'}'
              '  ·  ${_shortDuration(span)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(v.visitNo, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${v.distance.toStringAsFixed(2)} km', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(ongoing ? 'Ongoing' : 'Completed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ),
        ]),
      ]),
    );
  }
}

/// "End trip": the end selfie (required) and an end remark, then confirm.
class _EndTripSheet extends StatefulWidget {
  final String visitNo;
  const _EndTripSheet({required this.visitNo});

  @override
  State<_EndTripSheet> createState() => _EndTripSheetState();
}

class _EndTripSheetState extends State<_EndTripSheet> {
  final _remarks = TextEditingController();
  XFile? _selfie;
  String? _error;

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _take() async {
    try {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (shot != null && mounted) setState(() {
        _selfie = shot;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not open the camera: $e');
    }
  }

  void _confirm() {
    if (_selfie == null) {
      setState(() => _error = 'Take a selfie to end the trip.');
      return;
    }
    Navigator.pop(context, (selfie: _selfie!, remarks: _remarks.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final shot = _selfie;
    return SafeArea(
      child: SingleChildScrollView(
        // Keeps the buttons above the keyboard while typing the remark.
        padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('End this trip?', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _navy, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${widget.visitNo}  ·  Your current location is saved as the end of the trip.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 18),
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFFF1F3F9),
                  child: shot == null
                      ? Icon(Icons.person_outline, size: 40, color: Colors.grey.shade500)
                      : Image.file(File(shot.path), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    shot == null ? 'A selfie is needed to end the trip.' : 'Looks good. You can retake it.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _navy,
                      side: const BorderSide(color: _navy),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _take,
                    icon: Icon(shot == null ? Icons.person_outline : Icons.refresh, size: 18),
                    label: Text(shot == null ? 'Take selfie' : 'Retake'),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _remarks,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Remarks (optional)',
                hintText: 'e.g. Work completed at site',
                filled: true,
                fillColor: const Color(0xFFF1F3F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            ],
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _navy, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _confirm,
              child: const Text('End trip'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep going')),
          ],
        ),
      ),
    );
  }
}

/// A dot that pulses while the trip is being recorded.
class _PulseDot extends StatefulWidget {
  final bool active;
  const _PulseDot({required this.active});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          if (widget.active)
            Container(
              width: 10 + 12 * _c.value,
              height: 10 + 12 * _c.value,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.5 * (1 - _c.value))),
            ),
          Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
        ]),
      ),
    );
  }
}
