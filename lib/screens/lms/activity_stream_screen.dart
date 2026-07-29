import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/activity_stream.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../widgets/network_avatar.dart';

class ActivityStreamScreen extends StatefulWidget {
  const ActivityStreamScreen({super.key});

  @override
  State<ActivityStreamScreen> createState() => _ActivityStreamScreenState();
}

class _ActivityStreamScreenState extends State<ActivityStreamScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  ActivityStreamData? _data;
  String? _error;

  static const _sectionKeys = ['today', 'upcoming', 'recent', 'observer'];
  static const _sectionLabels = ['Today', 'Upcoming', 'Recent', 'Observer'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _sectionKeys.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) {
      setState(() => _error = 'Your session has expired. Please sign in again.');
      return;
    }
    try {
      final service = ApiService();
      await service.loadCookies();
      final result = await service.fetchActivityStream(
        user,
        auth.originalToken ?? user.token,
      );
      if (mounted) setState(() => _data = result);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Task Activity Stream',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF173B67),
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFBFD0E4),
          indicatorColor: const Color(0xFF67C6E3),
          indicatorWeight: 3,
          tabs: _sectionLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_data == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_data == null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    return Column(
      children: [
        if (_data!.todayTitle.isNotEmpty)
          Container(
            width: double.infinity,
            color: const Color(0xFFE8F2FA),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              _data!.todayTitle,
              style: const TextStyle(
                color: Color(0xFF173B67),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: _sectionKeys.map(_buildSection).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String key) {
    final items = _data!.sections[key]?.items ?? const [];
    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 150),
                Icon(Icons.inbox_outlined, size: 52, color: Color(0xFF94A3B8)),
                SizedBox(height: 12),
                Center(child: Text('No activities found')),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _ActivityCard(item: items[index]),
            ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityStreamItem item;

  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7EAF0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkAvatar(
              image: item.imageUrl,
              radius: 24,
              backgroundColor: const Color(0xFFE4EEF8),
              iconColor: const Color(0xFF326B9B),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Chip(label: _displayStatus(item.status), color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.priority.isNotEmpty)
                        _Chip(
                          label: item.priority,
                          color: _priorityColor(item.priority),
                          icon: Icons.flag_outlined,
                        ),
                      if (item.isCompliance)
                        const _Chip(
                          label: 'Compliance',
                          color: Color(0xFF2563EB),
                          icon: Icons.shield_outlined,
                        ),
                      if (item.approvalStatus?.isNotEmpty == true)
                        _Chip(
                          label: _displayStatus(item.approvalStatus!),
                          color: _statusColor(item.approvalStatus!),
                          icon: Icons.fact_check_outlined,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Meta(icon: Icons.event_outlined, text: _formatDate(item.date)),
                  if (item.allocatedUser.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    _Meta(
                      icon: Icons.person_outline,
                      text: 'Assigned to ${item.allocatedUser}',
                    ),
                  ],
                  if (item.allocatedBy.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    _Meta(
                      icon: Icons.person_add_alt_outlined,
                      text: 'By ${item.allocatedBy}',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String value) {
    if (value.isEmpty) return 'Date not available';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  static String _displayStatus(String value) => value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  static Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'completed':
      case 'approved':
        return const Color(0xFF15803D);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'in-progress':
      case 'in_progress':
      case 'in progress':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF64748B);
    }
  }

  static Color _priorityColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF2563EB);
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Chip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 54, color: Color(0xFF94A3B8)),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
