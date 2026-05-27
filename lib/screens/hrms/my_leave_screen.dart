import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import 'apply_leave_screen.dart';

class MyLeaveScreen extends StatefulWidget {
  const MyLeaveScreen({super.key});

  @override
  State<MyLeaveScreen> createState() => _MyLeaveScreenState();
}

class _MyLeaveScreenState extends State<MyLeaveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  List<Map<String, dynamic>> _allLeaves = [];
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> get _filteredLeaves {
    if (_selectedFilter == 'All') return _allLeaves;
    return _allLeaves.where((leave) => leave['status'] == _selectedFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLeaveData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final token = auth.originalToken ?? user?.token;

    if (user == null || token == null) {
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
      return;
    }

    try {
      final apiService = ApiService();
      await apiService.loadCookies();

      final leaves = await apiService.fetchMyLeaves(
        subInstituteId: user.subInstituteId,
        token: token,
        userId: user.id,
      );

      final mapped = leaves.map((item) {
        final from = item['from_date']?.toString() ?? '';
        final to = item['to_date']?.toString() ?? '';
        final dayTypeStr = item['day_type']?.toString() ?? '1';

        double days;
        if (dayTypeStr == '0.5') {
          days = 0.5;
        } else {
          try {
            final f = DateTime.parse(from);
            final t = DateTime.parse(to);
            days = (t.difference(f).inDays + 1).toDouble();
            if (days < 0) days = 0;
          } catch (_) {
            days = 1;
          }
        }

        String rawStatus = (item['status']?.toString() ?? 'pending').toLowerCase().trim();
        final status = rawStatus.isNotEmpty
            ? rawStatus[0].toUpperCase() + rawStatus.substring(1)
            : 'Pending';

        String appliedOn = '';
        final created = item['created_at']?.toString();
        if (created != null && created.isNotEmpty) {
          appliedOn = created.split(' ').first;
        }

        final map = <String, dynamic>{
          'id': item['id'],
          'leaveType': item['leave_type_name']?.toString() ?? 'Leave',
          'fromDate': from,
          'toDate': to,
          'days': days,
          'reason': item['comment']?.toString() ?? '',
          'status': status,
          'appliedOn': appliedOn,
        };

        if (status.toLowerCase() == 'rejected') {
          map['rejectionReason'] = item['hr_remarks']?.toString() ?? item['hod_comment']?.toString();
        }

        return map;
      }).toList();

      setState(() {
        _allLeaves = mapped;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load leave data: $e');
      setState(() {
        _error = 'Failed to load leave data';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Pending':
        return const Color(0xFFFF6A00);
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
        return Icons.check_circle;
      case 'Pending':
        return Icons.access_time;
      case 'Rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDays(dynamic d) {
    if (d == 0.5) return '0.5 day (Half)';
    final days = (d is num) ? d : 1;
    return '${days} ${days == 1 ? 'day' : 'days'}';
  }

  void _showLeaveDetails(Map<String, dynamic> leave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildLeaveDetailSheet(leave),
    );
  }

  Widget _buildLeaveDetailSheet(Map<String, dynamic> leave) {
    final statusColor = _getStatusColor(leave['status']);
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leave['leaveType'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(leave['status']), size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(leave['status'], style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('From', _formatDisplayDate(leave['fromDate'])),
          _buildDetailRow('To', _formatDisplayDate(leave['toDate'])),
          _buildDetailRow('Total Days', _formatDays(leave['days'])),
          _buildDetailRow('Applied On', _formatDisplayDate(leave['appliedOn'])),
          const SizedBox(height: 12),
          const Text('Reason', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D))),
          const SizedBox(height: 4),
          Text(leave['reason'], style: const TextStyle(fontSize: 15)),
          if (leave['status'] == 'Rejected' && leave['rejectionReason'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rejection Reason', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                        Text(leave['rejectionReason']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (leave['status'] == 'Pending')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelLeave(leave['id']);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel Application'),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _cancelLeave(dynamic id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Leave?'),
        content: const Text('Are you sure you want to cancel this leave application?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _allLeaves.removeWhere((l) => l['id'] == id || l['id'].toString() == id.toString());
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave application cancelled')),
        );
      }
    }
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final statusColor = _getStatusColor(leave['status']);
    return InkWell(
      onTap: () => _showLeaveDetails(leave),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    leave['leaveType'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(leave['status']), size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        leave['status'],
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '${_formatDisplayDate(leave['fromDate'])} → ${_formatDisplayDate(leave['toDate'])}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2A6D).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatDays(leave['days']),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1F2A6D)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              leave['reason'],
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approvedCount = _allLeaves.where((l) => l['status'] == 'Approved').length;
    final pendingCount = _allLeaves.where((l) => l['status'] == 'Pending').length;
    final rejectedCount = _allLeaves.where((l) => l['status'] == 'Rejected').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2A6D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _selectedFilter = 'All';
                  break;
                case 1:
                  _selectedFilter = 'Pending';
                  break;
                case 2:
                  _selectedFilter = 'Approved';
                  break;
                case 3:
                  _selectedFilter = 'Rejected';
                  break;
              }
            });
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1F2A6D).withOpacity(0.06), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1F2A6D)),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadLeaveData,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F2A6D)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            _buildSummaryCard('Approved', approvedCount.toString(), Colors.green, Icons.check_circle),
                            const SizedBox(width: 10),
                            _buildSummaryCard('Pending', pendingCount.toString(), const Color(0xFFFF6A00), Icons.access_time),
                            const SizedBox(width: 10),
                            _buildSummaryCard('Rejected', rejectedCount.toString(), Colors.red, Icons.cancel),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _filteredLeaves.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text('No ${_selectedFilter.toLowerCase()} leaves found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _filteredLeaves.length,
                                itemBuilder: (context, index) => _buildLeaveCard(_filteredLeaves[index]),
                              ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ApplyLeaveScreen()),
          );
          // Refresh list after returning from apply screen
          if (mounted) {
            _loadLeaveData();
          }
        },
        backgroundColor: const Color(0xFFFF6A00),
        icon: const Icon(Icons.add),
        label: const Text('Apply Leave'),
      ),
    );
  }
}
