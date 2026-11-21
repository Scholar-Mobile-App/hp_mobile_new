import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// One recorded position fix.
class TravelPoint {
  final double lat;
  final double lng;
  final double? accuracy;
  final double? speed;
  final DateTime recordedAt;

  TravelPoint({
    required this.lat,
    required this.lng,
    this.accuracy,
    this.speed,
    required this.recordedAt,
  });

  /// UTC ISO-8601, so the server reads the same instant whatever the phone's zone.
  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (accuracy != null) 'accuracy': accuracy,
        if (speed != null) 'speed': speed,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
      };

  factory TravelPoint.fromJson(Map<String, dynamic> j) => TravelPoint(
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        accuracy: (j['accuracy'] as num?)?.toDouble(),
        speed: (j['speed'] as num?)?.toDouble(),
        recordedAt: DateTime.parse(j['recorded_at'] as String),
      );
}

/// A trip as the server describes it.
class TravelVisit {
  final int id;
  final String visitNo;
  final String? purpose;
  final String? vehicleType;
  final String status;
  final DateTime startAt;
  final DateTime? endAt;
  final double distance;

  TravelVisit({
    required this.id,
    required this.visitNo,
    this.purpose,
    this.vehicleType,
    required this.status,
    required this.startAt,
    this.endAt,
    required this.distance,
  });

  bool get isOngoing => status == 'ongoing';

  /// Shown in the phone's own zone. The server's clock is UTC: a time that comes
  /// with an offset is used as is, and an older server's bare "2026-11-19 10:47:09"
  /// (no offset) is read as UTC rather than as the phone's local time, which is
  /// what showed trips starting hours early.
  static DateTime _parse(String s) {
    final iso = s.trim().replaceFirst(' ', 'T');
    final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(iso);
    return DateTime.parse(hasZone ? iso : '${iso}Z').toLocal();
  }

  factory TravelVisit.fromJson(Map<String, dynamic> j) => TravelVisit(
        id: (j['id'] as num).toInt(),
        visitNo: (j['visit_no'] ?? '').toString(),
        purpose: j['purpose'] as String?,
        vehicleType: j['vehicle_type'] as String?,
        status: (j['status'] ?? '').toString(),
        startAt: _parse(j['start_at'] as String),
        endAt: j['end_at'] == null ? null : _parse(j['end_at'] as String),
        distance: (j['distance'] as num?)?.toDouble() ?? 0,
      );
}

class TravelException implements Exception {
  final String message;
  TravelException(this.message);
  @override
  String toString() => message;
}

/// Calls /api/travel-visits. [token] is the Sanctum token (AuthProvider.originalToken).
class TravelVisitApi {
  final String token;
  TravelVisitApi(this.token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}/api/travel-visits$path').replace(queryParameters: query);

  Map<String, dynamic> _decode(http.Response r) {
    Map<String, dynamic> body = {};
    try {
      final d = json.decode(r.body);
      if (d is Map<String, dynamic>) body = d;
    } catch (_) {}
    if (r.statusCode >= 200 && r.statusCode < 300 && body['status'].toString() != '0') {
      return body;
    }
    throw TravelException((body['message'] ?? 'Request failed (${r.statusCode})').toString());
  }

  Future<Map<String, dynamic>> referenceData() async =>
      _decode(await http.get(_uri('/reference-data'), headers: _headers).timeout(ApiConfig.defaultTimeout));

  /// The caller's ongoing trip on the server, or null.
  Future<TravelVisit?> active() async {
    final body = _decode(await http.get(_uri('/active'), headers: _headers).timeout(ApiConfig.defaultTimeout));
    final d = body['data'];
    return d is Map<String, dynamic> ? TravelVisit.fromJson(d) : null;
  }

  Future<List<TravelVisit>> mine() async {
    final body = _decode(await http.get(_uri('', {'scope': 'mine'}), headers: _headers).timeout(ApiConfig.defaultTimeout));
    final list = body['data'];
    if (list is! List) return [];
    return list.map((e) => TravelVisit.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Starts the trip. The selfie and the remark are taken at the END, so none is
  /// needed here; [selfiePath] stays optional for a caller that has one.
  Future<TravelVisit> start({
    required Position at,
    String? selfiePath,
    String? address,
    String? purpose,
    String? vehicleType,
    String? remarks,
  }) async {
    final req = http.MultipartRequest('POST', _uri('/start'))
      ..headers.addAll({'Accept': 'application/json', 'Authorization': 'Bearer $token'})
      ..fields.addAll({
        'lat': at.latitude.toString(),
        'lng': at.longitude.toString(),
        'recorded_at': at.timestamp.toUtc().toIso8601String(),
        if (address != null) 'address': address,
        if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
        if (vehicleType != null && vehicleType.isNotEmpty) 'vehicle_type': vehicleType,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      });
    if (selfiePath != null) req.files.add(await http.MultipartFile.fromPath('selfie', selfiePath));

    // A photo is a bigger upload than the rest: allow longer on a slow connection.
    final streamed = await req.send().timeout(const Duration(seconds: 90));
    final r = await http.Response.fromStream(streamed);
    return TravelVisit.fromJson(Map<String, dynamic>.from(_decode(r)['data'] as Map));
  }

  /// Returns normally on success. Throws [TripEndedException] if the server says the trip is over.
  Future<void> sendPoints(int visitId, List<TravelPoint> points) async {
    final r = await http
        .post(_uri('/$visitId/points'), headers: _headers, body: json.encode({'points': points.map((p) => p.toJson()).toList()}))
        .timeout(ApiConfig.defaultTimeout);
    if (r.statusCode == 409) throw TripEndedException();
    _decode(r);
  }

  /// Ends the trip. [selfiePath] is the photo taken now - required, like the start
  /// one - and [remarks] is the end remark (the start remark is kept separately).
  Future<TravelVisit> end(
    int visitId, {
    required Position at,
    required String selfiePath,
    String? address,
    double? appDistanceKm,
    String? remarks,
    List<TravelPoint> points = const [],
  }) async {
    final req = http.MultipartRequest('POST', _uri('/$visitId/end'))
      ..headers.addAll({'Accept': 'application/json', 'Authorization': 'Bearer $token'})
      ..fields.addAll({
        'lat': at.latitude.toString(),
        'lng': at.longitude.toString(),
        'recorded_at': at.timestamp.toUtc().toIso8601String(),
        if (address != null) 'address': address,
        if (appDistanceKm != null) 'app_distance': appDistanceKm.toStringAsFixed(3),
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        // A multipart body has no neat array-of-objects: the points go as one JSON string.
        if (points.isNotEmpty) 'points_json': json.encode(points.map((p) => p.toJson()).toList()),
      });
    req.files.add(await http.MultipartFile.fromPath('selfie', selfiePath));

    final streamed = await req.send().timeout(const Duration(seconds: 90));
    final r = await http.Response.fromStream(streamed);
    return TravelVisit.fromJson(Map<String, dynamic>.from(_decode(r)['data'] as Map));
  }
}

class TripEndedException implements Exception {}

/// Records the phone's position for the trip in progress, every 30 seconds.
///
/// Why it is built like this:
///  * A position STREAM with an Android foreground-service notification (and the
///    iOS background-location mode) is what keeps the app alive and receiving
///    fixes with the screen off. A bare Timer is paused by the OS in background.
///  * The OS is asked for a fix every few seconds; out of those, the most accurate
///    one in each [interval] window is recorded. A fix worse than [_goodAccuracyM]
///    is not recorded, so the map is not drawn through GPS "jumps" - unless no good
///    fix has come for [_maxGap], so a weak-signal stretch still leaves a trace.
///  * The distance ignores GPS jitter (movement smaller than the fixes' own error,
///    e.g. while standing still) and impossible jumps (faster than [_maxSpeedMps]).
///  * Fixes go into a buffer that is saved to SharedPreferences and flushed to the
///    server after each fix. If the network is down they stay queued and are sent
///    with the next flush, in time order. The server ignores repeats, so a retry
///    can never double a point.
///  * The tracker is a singleton so leaving the screen does not stop the trip.
class TravelTracker extends ChangeNotifier {
  TravelTracker._();
  static final TravelTracker instance = TravelTracker._();

  /// One point is recorded per this window.
  static const Duration interval = Duration(seconds: 30);
  /// How often the OS is asked for a fix, so each window has a few to choose from.
  /// Every 10 s (not more often) to go easier on the battery.
  static const Duration _osInterval = Duration(seconds: 10);
  static const String _prefsKey = 'travel_tracker_state_v1';
  /// A fix at least this accurate is recorded as soon as its window is over.
  static const double _goodAccuracyM = 50;
  /// A fix less accurate than this is never used for the distance.
  static const double _maxAccuracyM = 100;
  /// With no good fix for this long, the best one seen is recorded anyway.
  static const Duration _maxGap = Duration(seconds: 60);
  /// About 250 km/h: a "move" faster than this between two fixes is a GPS glitch.
  static const double _maxSpeedMps = 70;
  /// Movement below this is never counted (the floor of the jitter filter).
  static const double _minMoveM = 10;

  TravelVisitApi? _api;
  int? visitId;
  StreamSubscription<Position>? _sub;
  final List<TravelPoint> _pending = [];
  /// Where the distance was last measured from (the last trusted fix).
  TravelPoint? _last;
  DateTime? _lastRecorded;
  /// The most accurate fix seen in the current window, not yet recorded.
  Position? _candidate;
  bool _flushing = false;

  StreamSubscription<ServiceStatus>? _statusSub;
  Timer? _offReminder;
  /// The phone's location switch is off while a trip is running.
  bool locationOff = false;
  static const int _offNotificationId = 7001;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  double distanceKm = 0;
  int pointCount = 0;
  String? lastError;

  bool get isTracking => visitId != null && _sub != null;

  /// Begin (or resume) tracking [id]. [token] is the Sanctum token.
  Future<void> begin(String token, int id, {Position? first, bool resume = false}) async {
    await stop(clearState: false);
    _api = TravelVisitApi(token);
    visitId = id;
    lastError = null;

    _candidate = null;
    if (!resume) {
      _pending.clear();
      _last = null;
      _lastRecorded = null;
      distanceKm = 0;
      pointCount = 0;
    } else {
      await _restore(id);
    }
    if (first != null) _record(first, force: true);

    _listen();
    _watchLocationSwitch();
    await _save();
    notifyListeners();
  }

  /// (Re)open the position stream. Reopened when location is switched back on,
  /// because a stream that was running when GPS was turned off may not recover.
  void _listen() {
    _sub?.cancel();

    final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: _osInterval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Travel visit in progress',
          notificationText: 'Your location is being recorded for this trip.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      settings = const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
    }

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (p) => _record(p),
      onError: (Object e) {
        // Usually "location services disabled": the status watcher below handles that.
        if (!locationOff) lastError = 'Location unavailable: $e';
        notifyListeners();
      },
    );
  }

  /// Tells the user - with a notification, since the app may be in the background -
  /// the moment the location switch goes off during a trip, and repeats every two
  /// minutes until it is back on.
  void _watchLocationSwitch() {
    _statusSub?.cancel();
    _statusSub = Geolocator.getServiceStatusStream().listen((status) => _onLocationSwitch(status == ServiceStatus.enabled));
    // It may already be off (resuming a trip after a restart).
    Geolocator.isLocationServiceEnabled().then((on) {
      if (visitId != null && !on) _onLocationSwitch(false);
    });
  }

  void _onLocationSwitch(bool enabled) {
    if (visitId == null) return;
    if (!enabled) {
      if (locationOff) return;
      locationOff = true;
      _alertLocationOff();
      _offReminder?.cancel();
      _offReminder = Timer.periodic(const Duration(minutes: 2), (_) => _alertLocationOff());
    } else {
      if (!locationOff) return;
      locationOff = false;
      _offReminder?.cancel();
      _offReminder = null;
      _notifications.cancel(_offNotificationId);
      lastError = null;
      _listen();
    }
    notifyListeners();
  }

  Future<void> _alertLocationOff() async {
    try {
      const channel = AndroidNotificationChannel(
        'travel_visit_alerts',
        'Travel visit alerts',
        description: 'Warns you when location is off during a travel visit.',
        importance: Importance.max,
      );
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await _notifications.show(
        _offNotificationId,
        'Turn on your location',
        'Your travel visit is in progress but location is off, so your route is not being recorded.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            ongoing: true,
            autoCancel: false,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Travel tracker: could not show the location-off notification: $e');
    }
  }

  /// A fix's horizontal error in metres; an unknown one (0 or less) counts as poor.
  static double _acc(Position p) => p.accuracy > 0 ? p.accuracy : _maxAccuracyM;

  void _record(Position p, {bool force = false}) {
    // Android can hand back a cached fix from before the trip: skip anything stale.
    if (!force && p.timestamp.isBefore(DateTime.now().subtract(const Duration(minutes: 2)))) return;

    if (!force) {
      // Keep the most accurate fix of the window; decide when the window is over.
      if (_candidate == null || _acc(p) <= _acc(_candidate!)) _candidate = p;
      final since = _lastRecorded == null ? interval : DateTime.now().difference(_lastRecorded!);
      // A small allowance, since the OS does not deliver exactly on the second.
      if (since < interval - const Duration(seconds: 2)) return;
      // A poor fix is held back (a better one may still come), up to [_maxGap].
      if (_acc(_candidate!) > _goodAccuracyM && since < _maxGap) return;
      p = _candidate!;
    }
    _candidate = null;
    _lastRecorded = DateTime.now();

    final point = TravelPoint(
      lat: p.latitude,
      lng: p.longitude,
      accuracy: p.accuracy,
      speed: p.speed < 0 ? null : p.speed,
      recordedAt: p.timestamp,
    );

    _addDistance(point);

    _pending.add(point);
    pointCount++;
    lastError = null;
    notifyListeners();
    unawaited(_save());
    unawaited(flush());
  }

  /// Adds the stretch from the last trusted fix to [point], if it is a real move.
  void _addDistance(TravelPoint point) {
    final acc = point.accuracy != null && point.accuracy! > 0 ? point.accuracy! : _maxAccuracyM;
    if (acc > _maxAccuracyM) return;          // too vague to measure from or to
    final last = _last;
    if (last == null) {
      _last = point;
      return;
    }

    final m = Geolocator.distanceBetween(last.lat, last.lng, point.lat, point.lng);
    final lastAcc = last.accuracy != null && last.accuracy! > 0 ? last.accuracy! : _maxAccuracyM;

    // Jitter: a move no bigger than the fixes' own error is noise (standing still
    // or crawling). [_last] stays put, so a slow real move is still counted in
    // full once it adds up past the threshold.
    final noise = [_minMoveM, acc, lastAcc].reduce((a, b) => a > b ? a : b);
    if (m < noise) return;

    // A jump faster than any vehicle is a bad fix: skip it, keep the old anchor.
    final secs = point.recordedAt.difference(last.recordedAt).inMilliseconds / 1000;
    if (secs > 0 && m / secs > _maxSpeedMps) return;

    distanceKm += m / 1000;
    _last = point;
  }

  /// Counts the last stretch, from the last recorded fix to where the trip ends.
  /// Distance only: the end position itself goes to the server with the end call.
  void addFinalPosition(Position p) {
    _addDistance(TravelPoint(
      lat: p.latitude,
      lng: p.longitude,
      accuracy: p.accuracy,
      speed: p.speed < 0 ? null : p.speed,
      recordedAt: p.timestamp,
    ));
    unawaited(_save());
    notifyListeners();
  }

  /// Send everything queued. Safe to call any time; a second call while one is running does nothing.
  Future<void> flush() async {
    if (_flushing || _api == null || visitId == null || _pending.isEmpty) return;
    _flushing = true;
    final batch = List<TravelPoint>.from(_pending);
    try {
      await _api!.sendPoints(visitId!, batch);
      _pending.removeRange(0, batch.length);
      lastError = null;
      await _save();
    } on TripEndedException {
      // Ended elsewhere (web/another device). Stop quietly.
      await stop();
      return;
    } catch (e) {
      lastError = 'Offline - will retry ($e)';
    } finally {
      _flushing = false;
      notifyListeners();
    }
  }

  /// Fixes still waiting to be sent: handed to the end call so the last stretch is not lost.
  List<TravelPoint> takePending() => List<TravelPoint>.from(_pending);

  Future<void> stop({bool clearState = true}) async {
    await _sub?.cancel();
    _sub = null;
    await _statusSub?.cancel();
    _statusSub = null;
    _offReminder?.cancel();
    _offReminder = null;
    locationOff = false;
    _notifications.cancel(_offNotificationId);
    if (clearState) {
      visitId = null;
      _pending.clear();
      _last = null;
      _lastRecorded = null;
      _candidate = null;
      try {
        (await SharedPreferences.getInstance()).remove(_prefsKey);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    if (visitId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        json.encode({
          'visit_id': visitId,
          'distance_km': distanceKm,
          'point_count': pointCount,
          'pending': _pending.map((p) => p.toJson()).toList(),
          'last': _last?.toJson(),
        }),
      );
    } catch (_) {}
  }

  Future<void> _restore(int id) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_prefsKey);
      if (raw == null) return;
      final m = json.decode(raw) as Map<String, dynamic>;
      if (m['visit_id'] != id) return;   // a different trip's leftovers
      distanceKm = (m['distance_km'] as num?)?.toDouble() ?? 0;
      pointCount = (m['point_count'] as num?)?.toInt() ?? 0;
      _pending
        ..clear()
        ..addAll(((m['pending'] as List?) ?? []).map((e) => TravelPoint.fromJson(Map<String, dynamic>.from(e as Map))));
      final last = m['last'];
      if (last is Map) _last = TravelPoint.fromJson(Map<String, dynamic>.from(last));
    } catch (e) {
      debugPrint('Travel tracker: could not restore state: $e');
    }
  }
}

/// Location permission + service checks, with a message the screen can show.
class TravelPermissions {
  /// Returns null when ready, otherwise what to tell the user.
  static Future<String?> ensure() async {
    // Permission first: the system "turn on location" prompt below needs it.
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) return 'Location permission is needed to record your trip.';
    if (perm == LocationPermission.deniedForever) {
      return 'Location permission is blocked. Enable it for this app in Settings.';
    }

    // Location (GPS) switched off: ask to turn it on right now, instead of failing.
    if (!await requestEnableLocation()) return 'Location is off. Turn it on to start a trip.';
    return null;
  }

  /// Gets the location switch turned on. An app cannot flip it silently - Android
  /// and iOS both forbid that - but asking for a position makes Android show its
  /// one-tap "Turn on location" dialog, so the user only taps OK. If that is
  /// declined, [openSettings] sends them to the location settings page.
  static Future<bool> requestEnableLocation({bool openSettings = false}) async {
    if (await Geolocator.isLocationServiceEnabled()) return true;
    try {
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)),
      );
    } catch (_) {
      // Declined or timed out: the check below decides.
    }
    if (await Geolocator.isLocationServiceEnabled()) return true;
    if (openSettings) await Geolocator.openLocationSettings();
    return false;
  }

  static Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  /// "Allow all the time" is what lets tracking continue with the screen off.
  static Future<bool> hasAlways() async => (await Geolocator.checkPermission()) == LocationPermission.always;

  static Future<void> requestAlways() async {
    // On Android 11+ the system sends the user to Settings for this one.
    await Geolocator.requestPermission();
    if (!await hasAlways()) await Geolocator.openAppSettings();
  }

  /// Best-effort street address; null when there is no network or no result.
  static Future<String?> addressOf(double lat, double lng) async {
    try {
      final marks = await Geocoding().placemarkFromCoordinates(lat, lng).timeout(const Duration(seconds: 8));
      if (marks.isEmpty) return null;
      final p = marks.first;
      final parts = [p.name, p.subLocality, p.locality, p.administrativeArea, p.postalCode]
          .where((s) => s != null && s.trim().isNotEmpty)
          .cast<String>()
          .toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
