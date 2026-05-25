import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedLeaveType;
  Map<String, dynamic>? _selectedLeaveTypeData;
  DateTime? _fromDate;
  DateTime? _toDate;
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  double _totalDays = 0;

  String _dayType = 'Full Day';
  DateTime? _halfDayDate;
  String? _halfDaySlot;

  List<Map<String, dynamic>> _leaveTypeOptions = [];
  bool _isLoadingLeaveTypes = true;
  String? _leaveTypesError;

  final List<String> _leaveTypes = [
    'Casual Leave',
    'Sick Leave',
    'Earned Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Bereavement Leave',
    'Compensatory Off',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
  }

  Future<void> _loadLeaveTypes() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final token = auth.originalToken ?? user?.token;

    if (user == null || token == null) {
      setState(() {
        _isLoadingLeaveTypes = false;
        _leaveTypesError = 'User not logged in';
      });
      return;
    }

    try {
      final apiService = ApiService();
      await apiService.loadCookies();
      final types = await apiService.fetchLeaveTypes(
        subInstituteId: user.subInstituteId,
        token: token,
      );
      setState(() {
        _leaveTypeOptions = types;
        _isLoadingLeaveTypes = false;
      });
    } catch (e) {
      debugPrint('Failed to load leave types: $e');
      setState(() {
        _leaveTypesError = 'Failed to load leave types';
        _isLoadingLeaveTypes = false;
      });
    }
  }

  void _calculateDays() {
    if (_dayType == 'Half Day') {
      setState(() {
        _totalDays = 0.5;
      });
      return;
    }

    if (_fromDate != null && _toDate != null) {
      final difference = _toDate!.difference(_fromDate!).inDays + 1;
      setState(() {
        _totalDays = difference > 0 ? difference.toDouble() : 0;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime now = DateTime.now();
    final DateTime from = _fromDate ?? now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate 
          ? (_fromDate ?? now) 
          : (_toDate ?? from),                    // ← FIX: use From Date as fallback for To Date
      firstDate: isFromDate 
          ? now.subtract(const Duration(days: 30)) 
          : from,                                 // ← To Date cannot be before From Date
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = _fromDate;
          }
        } else {
          _toDate = picked;
        }
      });
      _calculateDays();
    }
  }

  Future<void> _selectHalfDayDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _halfDayDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _halfDayDate = picked;
      });
      _calculateDays();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dayType == 'Full Day') {
      if (_fromDate == null || _toDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select from and to dates')),
        );
        return;
      }
    } else {
      if (_halfDayDate == null || _halfDaySlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time slot for half day')),
        );
        return;
      }
    }

    if (_selectedLeaveTypeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid leave type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.originalToken ?? user?.token;

      if (user == null || token == null) {
        throw Exception('User not logged in');
      }

      final apiService = ApiService();
      await apiService.loadCookies();

      final dateFormat = DateFormat('yyyy-MM-dd');

      final leaveTypeId = (_selectedLeaveTypeData!['id'] ?? _selectedLeaveTypeData!['leave_type_id']).toString();

      final dayType = _dayType == 'Full Day' ? 'full' : 'half';
      final slot = _dayType == 'Half Day'
          ? (_halfDaySlot == 'First Half' ? 'first' : 'second')
          : null;

      String fromDateStr;
      String toDateStr;

      if (_dayType == 'Full Day') {
        fromDateStr = dateFormat.format(_fromDate!);
        toDateStr = dateFormat.format(_toDate!);
      } else {
        fromDateStr = dateFormat.format(_halfDayDate!);
        toDateStr = dateFormat.format(_halfDayDate!);
      }

      await apiService.applyLeave(
        subInstituteId: user.subInstituteId,
        token: token,
        userId: user.id,
        leaveTypeId: leaveTypeId,
        dayType: dayType,
        fromDate: fromDateStr,
        toDate: toDateStr,
        slot: slot,
        comment: _reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Leave application submitted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit leave: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Apply Leave',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F2A6D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1F2A6D).withOpacity(0.08), const Color(0xFF2E3A8C).withOpacity(0.04)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Leave Request',
                  style: TextStyle(
                    color: Color(0xFF1F2A6D),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in the details below to apply for leave',
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
                const SizedBox(height: 24),

                _buildLeaveTypeDropdown(),
                const SizedBox(height: 20),

                _buildDayTypeSelector(),
                const SizedBox(height: 16),

                if (_dayType == 'Full Day')
                  Row(
                    children: [
                      Expanded(child: _buildDatePicker('From Date', _fromDate, true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDatePicker('To Date', _toDate, false)),
                    ],
                  )
                else
                  _buildHalfDaySection(),

                const SizedBox(height: 20),

                _buildDaysCard(),
                const SizedBox(height: 20),

                _buildReasonField(),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitLeave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Submit Leave Application',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Leave Type',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D)),
        ),
        const SizedBox(height: 6),
        if (_isLoadingLeaveTypes)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Loading leave types...'),
              ],
            ),
          )
        else if (_leaveTypesError != null)
          Text(_leaveTypesError!, style: const TextStyle(color: Colors.red))
        else
          DropdownButtonFormField<String>(
            value: _selectedLeaveType,
            hint: const Text('Select leave type'),
            items: _leaveTypeOptions.map((type) {
              final name = type['leave_type']?.toString() ?? '';
              return DropdownMenuItem(value: name, child: Text(name));
            }).toList(),
            onChanged: (value) {
              final selected = _leaveTypeOptions.firstWhere(
                (t) => t['leave_type'] == value,
                orElse: () => {},
              );
              setState(() {
                _selectedLeaveType = value;
                _selectedLeaveTypeData = selected.isNotEmpty ? selected : null;
              });
            },
            validator: (value) => value == null ? 'Please select a leave type' : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, bool isFrom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D))),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _selectDate(context, isFrom),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 15,
                      color: date == null ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A6D).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2A6D).withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Days',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6A00),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _totalDays == 0.5 ? '0.5 Day (Half)' : '$_totalDays ${ _totalDays == 1 ? 'Day' : 'Days'}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _reasonController,
          maxLines: 4,
          minLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Please provide a reason';
            if (value.trim().length < 10) return 'Reason must be at least 10 characters';
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Enter reason for leave...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 1.5)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildDayTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Day Type',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _dayType = 'Full Day';
                      _halfDayDate = null;
                      _halfDaySlot = null;
                    });
                    _calculateDays();
                  },
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _dayType == 'Full Day' ? const Color(0xFFFF6A00) : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Full Day Leave',
                        style: TextStyle(
                          color: _dayType == 'Full Day' ? Colors.white : const Color(0xFF1F2A6D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _dayType = 'Half Day';
                      _fromDate = null;
                      _toDate = null;
                    });
                    _calculateDays();
                  },
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _dayType == 'Half Day' ? const Color(0xFFFF6A00) : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Half Day Leave',
                        style: TextStyle(
                          color: _dayType == 'Half Day' ? Colors.white : const Color(0xFF1F2A6D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHalfDaySection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D)),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _selectHalfDayDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _halfDayDate == null ? 'Select Date' : _formatDate(_halfDayDate),
                              style: TextStyle(
                                fontSize: 15,
                                color: _halfDayDate == null ? Colors.grey[500] : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time Slot',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D)),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _halfDaySlot,
                    hint: const Text('Select slot'),
                    items: const [
                      DropdownMenuItem(value: 'First Half', child: Text('First Half')),
                      DropdownMenuItem(value: 'Second Half', child: Text('Second Half')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _halfDaySlot = value;
                      });
                      _calculateDays();
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
