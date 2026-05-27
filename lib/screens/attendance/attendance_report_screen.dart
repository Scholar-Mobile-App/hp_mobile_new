import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  Map<String, dynamic>? _reportData;
  Map<String, dynamic>? _employeeInfo;
  bool _isLoading = true;
  String? _error;
  String? _infoMessage;
  String _selectedMonth = '';
  late DateTime _currentMonthDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonthDate = DateTime(now.year, now.month);
    _selectedMonth = DateFormat('yyyy-MM').format(_currentMonthDate);
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _infoMessage = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.originalToken ?? user?.token ?? '';

      if (user == null || token.isEmpty) {
        throw Exception('User not logged in');
      }

      final apiService = ApiService();
      await apiService.loadCookies();
      final response = await apiService.fetchEmployeeAttendanceMonthlyReport(
        userId: user.id,
        subInstituteId: user.subInstituteId,
        token: token,
        month: _selectedMonth,
      );

      if (response['status'] == 1 && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        setState(() {
          _reportData = data;
          _infoMessage = null;
          if (data['employee'] != null) {
            _employeeInfo = Map<String, dynamic>.from(data['employee']);
          }
        });
      } else {
        setState(() {
          _reportData = null;
          _infoMessage = response['message'] ?? 'No attendance data available for this month';
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _infoMessage = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changeMonth(bool forward) {
    if (forward) {
      _currentMonthDate = DateTime(_currentMonthDate.year, _currentMonthDate.month + 1);
    } else {
      _currentMonthDate = DateTime(_currentMonthDate.year, _currentMonthDate.month - 1);
    }
    _selectedMonth = DateFormat('yyyy-MM').format(_currentMonthDate);
    _fetchReport();
  }

  void _goToCurrentMonth() {
    final now = DateTime.now();
    _currentMonthDate = DateTime(now.year, now.month);
    _selectedMonth = DateFormat('yyyy-MM').format(_currentMonthDate);
    _fetchReport();
  }

  String _formatMonthDisplay() {
    return DateFormat('MMMM yyyy').format(_currentMonthDate);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red.shade700;
      case 'weekend':
        return Colors.grey.shade600;
      case 'incomplete':
        return Colors.orange.shade700;
      case 'holiday':
        return Colors.purple.shade600;
      case 'leave':
        return Colors.blue.shade600;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'weekend':
        return Icons.weekend;
      case 'incomplete':
        return Icons.access_time;
      case 'holiday':
        return Icons.celebration;
      case 'leave':
        return Icons.beach_access;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildSummaryCard(String label, dynamic value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? '0',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCard(dynamic day) {
    final status = day['status']?.toString() ?? '';
    final color = _getStatusColor(status);
    final isPresentOrIncomplete = status == 'present' || status == 'incomplete';

    return InkWell(
      onTap: () => _showDayDetails(day),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(DateTime.parse(day['date'])),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    day['day_name']?.toString().substring(0, 3) ?? '',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getStatusIcon(status), size: 14, color: color),
                            const SizedBox(width: 4),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (day['is_late'] == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'LATE',
                            style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isPresentOrIncomplete && (day['punchin_time'] != null || day['punchout_time'] != null)) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${day['punchin_time'] ?? '--:--'} → ${day['punchout_time'] ?? '--:--'}',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    if (day['working_hours'] != null)
                      Text(
                        'Hours: ${day['working_hours']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(dynamic day) {
    final status = day['status']?.toString() ?? '';
    final color = _getStatusColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(DateTime.parse(day['date'])),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(status), size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Shift Time', day['shift_time'] ?? 'N/A'),
            _buildDetailRow('Punch In', day['punchin_time'] ?? 'N/A'),
            _buildDetailRow('Punch Out', day['punchout_time'] ?? 'N/A'),
            _buildDetailRow('Working Hours', day['working_hours'] ?? 'N/A'),
            _buildDetailRow('Late Arrival', day['is_late'] == true ? 'Yes' : 'No'),
            if (day['leave'] != null) _buildDetailRow('Leave', day['leave'].toString()),
            if (day['holiday_name'] != null) _buildDetailRow('Holiday', day['holiday_name'].toString()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2A6D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    if (_reportData == null) return const SizedBox.shrink();
    final summary = _reportData!['summary'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Monthly Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D)),
          ),
        ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.88,
          children: [
            _buildSummaryCard('Total Days', summary['total_days'], Colors.indigo, Icons.calendar_month),
            _buildSummaryCard('Working', summary['working_days'], Colors.teal, Icons.work),
            _buildSummaryCard('Present', summary['present_days'], Colors.green, Icons.check_circle),
            _buildSummaryCard('Absent', summary['absent_days'], Colors.red, Icons.cancel),
            _buildSummaryCard('Late', summary['late_days'], Colors.orange, Icons.access_time),
            _buildSummaryCard('Leave', summary['leave_days'], Colors.blue, Icons.beach_access),
            _buildSummaryCard('Holiday', summary['holiday_days'], Colors.purple, Icons.celebration),
            _buildSummaryCard('Weekend', summary['weekend_days'], Colors.grey, Icons.weekend),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    if (_reportData == null) return const SizedBox.shrink();

    final dailyList = (_reportData!['daily_report'] as List<dynamic>?) ?? [];
    final Map<String, dynamic> dayMap = {};
    for (final d in dailyList) {
      if (d['date'] != null) dayMap[d['date']] = d;
    }

    final year = _currentMonthDate.year;
    final month = _currentMonthDate.month;
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = firstOfMonth.weekday; // 1 = Monday ... 7 = Sunday

    final List<Widget> cells = [];

    // Weekday headers
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (final w in weekdays) {
      cells.add(
        Center(
          child: Text(
            w,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
        ),
      );
    }

    // Leading empty cells
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(Container());
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(year, month, day));
      final dayData = dayMap[dateStr];
      final status = (dayData != null ? dayData['status']?.toString() : '') ?? '';
      final color = _getStatusColor(status);
      final isToday = dateStr == todayStr;

      cells.add(
        GestureDetector(
          onTap: dayData != null ? () => _showDayDetails(dayData) : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: status.isNotEmpty ? color.withOpacity(0.13) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: isToday ? Border.all(color: const Color(0xFFFF6A00), width: 2) : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 4,
                  right: 5,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isToday ? const Color(0xFFFF6A00) : (status.isNotEmpty ? color : Colors.black87),
                    ),
                  ),
                ),
                if (status.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(_getStatusIcon(status), size: 14, color: color),
                    ),
                  ),
                if (dayData != null && dayData['is_late'] == true)
                  Positioned(
                    bottom: 3,
                    left: 3,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Calendar View',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D)),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final items = [
      ['Present', Colors.green],
      ['Absent', Colors.red.shade700],
      ['Late', Colors.orange.shade700],
      ['Weekend', Colors.grey.shade600],
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Wrap(
        spacing: 12,
        children: items.map((item) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: item[1] as Color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Text(item[0] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 26, color: Color(0xFF1F2A6D)),
            onPressed: () => _changeMonth(false),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _goToCurrentMonth,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFFF6A00).withOpacity(0.12), const Color(0xFFFF6A00).withOpacity(0.06)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFFFF6A00)),
                    const SizedBox(width: 8),
                    Text(
                      _formatMonthDisplay(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2A6D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 26, color: Color(0xFF1F2A6D)),
            onPressed: () => _changeMonth(true),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard() {
    final emp = _reportData?['employee'] ?? _employeeInfo;
    if (emp == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F2A6D), Color(0xFF2E3A8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Employee', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            emp['name']?.toString() ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No attendance data for ${_formatMonthDisplay()}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'The selected month has no recorded attendance entries.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _goToCurrentMonth,
              icon: const Icon(Icons.today),
              label: const Text('Go to Current Month'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchReport,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F2A6D)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_reportData == null) return;

    final pdf = pw.Document();

    final employee = _reportData!['employee'];
    final summary = _reportData!['summary'] ?? {};
    final dailyReport = (_reportData!['daily_report'] as List<dynamic>?) ?? [];

    final headers = ['Date', 'Day', 'Status', 'In', 'Out', 'Hours', 'Late'];

    final List<pw.TableRow> rows = [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: headers.map((h) => pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(h, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
        )).toList(),
      ),
    ];

    for (final day in dailyReport) {
      rows.add(pw.TableRow(
        children: [
          _pdfCell(day['date'] ?? '', 7),
          _pdfCell(day['day_name'] ?? '', 7),
          _pdfCell(day['status']?.toString().toUpperCase() ?? '', 7),
          _pdfCell(day['punchin_time'] ?? '-', 7),
          _pdfCell(day['punchout_time'] ?? '-', 7),
          _pdfCell(day['working_hours'] ?? '-', 7),
          _pdfCell(day['is_late'] == true ? 'Yes' : 'No', 7),
        ],
      ));
    }

    // Compact horizontal + vertical summary (4 columns x 2 rows)
    final summaryTable = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(children: [
          _pdfSummaryCell('Total Days', summary['total_days']),
          _pdfSummaryCell('Working', summary['working_days']),
          _pdfSummaryCell('Present', summary['present_days']),
          _pdfSummaryCell('Absent', summary['absent_days']),
        ]),
        pw.TableRow(children: [
          _pdfSummaryCell('Late', summary['late_days']),
          _pdfSummaryCell('Leave', summary['leave_days']),
          _pdfSummaryCell('Holiday', summary['holiday_days']),
          _pdfSummaryCell('Weekend', summary['weekend_days']),
        ]),
      ],
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Attendance Report - ${_selectedMonth}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('${employee?['name'] ?? ''}', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 10),

              pw.Text('Summary', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              summaryTable,

              pw.SizedBox(height: 12),
              pw.Text('Daily Report', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),

              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1.3),
                    1: pw.FlexColumnWidth(1.0),
                    2: pw.FlexColumnWidth(1.1),
                    3: pw.FlexColumnWidth(1.0),
                    4: pw.FlexColumnWidth(1.0),
                    5: pw.FlexColumnWidth(1.0),
                    6: pw.FlexColumnWidth(0.7),
                  },
                  children: rows,
                ),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await pdf.save();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/attendance_report_${_selectedMonth.replaceAll('-', '')}.pdf');
    await file.writeAsBytes(bytes);

    // Open file directly (fixes FileUriExposedException on Android 7+)
    await OpenFilex.open(file.path);
  }

  pw.Widget _pdfCell(String text, double fontSize) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(text, style: pw.TextStyle(fontSize: fontSize)),
    );
  }

  pw.Widget _pdfSummaryCell(String label, dynamic value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text(value?.toString() ?? '0', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _reportData != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F2A6D),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchReport,
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _downloadPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildMonthSelector(),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6A00)),
                    ),
                  )
                : _error != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildEmployeeCard(),
                            const SizedBox(height: 16),
                            _buildErrorState(),
                          ],
                        ),
                      )
                    : hasData
                        ? RefreshIndicator(
                            onRefresh: _fetchReport,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildEmployeeCard(),
                                  const SizedBox(height: 16),
                                  _buildSummarySection(),
                                  const SizedBox(height: 20),
                                  _buildCalendarView(),
                                  _buildLegend(),
                                  const SizedBox(height: 30),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildEmployeeCard(),
                                const SizedBox(height: 16),
                                _buildNoDataState(),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
