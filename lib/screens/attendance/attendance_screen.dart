import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with TickerProviderStateMixin {
  DateTime? _punchInTime;
  DateTime? _punchOutTime;
  bool _isPunchedIn = false;
  String _currentTime = '';
  String _currentDate = '';
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String _totalHours = '00:00:00';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceStatus(showLoading: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      _currentDate = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());
    });
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Not punched';
    return DateFormat('hh:mm a').format(time);
  }

  String _calculateWorkingHours() {
    if (_punchInTime == null) return '0 hours';
    if (_punchOutTime != null) {
      return _formatTotalHours(_totalHours);
    }
    DateTime endTime = DateTime.now();
    Duration difference = endTime.difference(_punchInTime!);
    int totalMinutes = difference.inMinutes;
    int h = totalMinutes ~/ 60;
    int m = totalMinutes % 60;
    return '$h:$m hours';
  }

  void _loadAttendanceStatus({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isInitialLoading = true;
      });
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final token = auth.originalToken ?? user?.token;

    if (user == null || token == null) {
      setState(() {
        _isInitialLoading = false;
      });
      return;
    }

    try {
      final apiService = ApiService();
      await apiService.loadCookies();
      final data = await apiService.fetchAttendance(user, token);

      final attendanceData = data['attendanceData'] as List<dynamic>? ?? [];
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final todayEntry = attendanceData.firstWhere(
        (entry) => entry['day'] == today,
        orElse: () => null,
      );

      if (todayEntry != null) {
        if (todayEntry['punchin_time'] != null) {
          _punchInTime = DateTime.parse(todayEntry['punchin_time']);
        }
        if (todayEntry['punchout_time'] != null) {
          _punchOutTime = DateTime.parse(todayEntry['punchout_time']);
          _isPunchedIn = false;
        } else {
          _isPunchedIn = true;
        }
        _totalHours = todayEntry['timestamp_diff'] ?? '00:00:00';
      }

      setState(() {});
    } catch (e) {
      debugPrint('Failed to load attendance status: $e');
      // Don't show error snackbar on init, just keep default state
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _punchIn() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final token = auth.originalToken ?? user?.token;

    if (user == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ User not logged in'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      await apiService.loadCookies();
      await apiService.punchIn(user, token);
      setState(() {
        _punchInTime = DateTime.now();
        _isPunchedIn = true;
        _punchOutTime = null;
      });
      _animationController.forward().then((_) => _animationController.reverse());
      _loadAttendanceStatus(showLoading: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Successfully punched in at ${_formatTime(_punchInTime)}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      debugPrint('Punch in error: $e');
      final errorMessage = e.toString();
      if (errorMessage.contains('Already punch in')) {
        setState(() {
          _isPunchedIn = true;
          _punchInTime = DateTime.now(); // Approximate time
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ℹ️ You have already punched in'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to punch in: $errorMessage'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _punchOut() async {
    if (!_isPunchedIn) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final token = auth.originalToken ?? user?.token;

    if (user == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ User not logged in'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      await apiService.loadCookies();
      await apiService.punchOut(user, token);
      setState(() {
        _punchOutTime = DateTime.now();
        _isPunchedIn = false;
      });
      _animationController.forward().then((_) => _animationController.reverse());
      _loadAttendanceStatus(showLoading: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Successfully punched out at ${_formatTime(_punchOutTime)}'),
          backgroundColor: const Color(0xFF1F2A6D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      debugPrint('Punch out error: $e');
      final errorMessage = e.toString();
      if (errorMessage.contains('Cannot punch out') || errorMessage.contains('Not punched in')) {
        setState(() {
          _isPunchedIn = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ℹ️ You are not currently punched in'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to punch out: $errorMessage'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Attendance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1F2A6D),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isInitialLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6A00)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading attendance data...',
                    style: TextStyle(
                      color: Color(0xFF1F2A6D),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1F2A6D).withOpacity(0.05), const Color(0xFF2E3A8C).withOpacity(0.02)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Digital Clock
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6A00), Color(0xFFFF7A1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6A00).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentDate,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Status Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(
                             color: _getStatusColor().withOpacity(0.1),
                             borderRadius: BorderRadius.circular(50),
                           ),
                           child: Icon(
                             _getStatusIcon(),
                             color: _getStatusColor(),
                             size: 28,
                           ),
                         ),
                         const SizedBox(width: 16),
                         const Text(
                           'Current Status',
                           style: TextStyle(
                             color: Color(0xFF1F2A6D),
                             fontSize: 20,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 20),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                       decoration: BoxDecoration(
                         color: _getStatusColor().withOpacity(0.1),
                         borderRadius: BorderRadius.circular(25),
                       ),
                       child: Text(
                         _getStatusText(),
                         style: TextStyle(
                           color: _getStatusColor(),
                           fontSize: 18,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Punch Buttons
              Row(
                children: [
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _animation.value,
                          child: child,
                        );
                      },
                       child: ElevatedButton.icon(
                         onPressed: (_isPunchedIn || _isLoading || _punchOutTime != null) ? null : _punchIn,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.login, size: 28),
                        label: Text(
                          _isLoading ? 'Punching In...' : 'Punch In',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPunchedIn ? Colors.grey : const Color(0xFFFF6A00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _isPunchedIn ? 0 : 8,
                          shadowColor: const Color(0xFFFF6A00).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _animation.value,
                          child: child,
                        );
                      },
                      child: ElevatedButton.icon(
                        onPressed: (_isPunchedIn && !_isLoading) ? _punchOut : null,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.logout, size: 28),
                        label: Text(
                          _isLoading ? 'Punching Out...' : 'Punch Out',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPunchedIn ? const Color(0xFF1F2A6D) : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _isPunchedIn ? 8 : 0,
                          shadowColor: const Color(0xFF1F2A6D).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Today's Summary
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F2A6D), Color(0xFF2E3A8C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1F2A6D).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Today\'s Summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_punchInTime != null) ...[
                      _buildSummaryRow('Punch In Time', _formatTime(_punchInTime)),
                      if (_punchOutTime != null) ...[
                        const SizedBox(height: 12),
                        _buildSummaryRow('Punch Out Time', _formatTime(_punchOutTime)),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Total Hours', _calculateWorkingHours()),
                      ] else ...[
                        const SizedBox(height: 12),
                        _buildSummaryRow('Working Hours', _calculateWorkingHours()),
                      ],
                    ] else ...[
                      const Center(
                        child: Text(
                          'No attendance recorded today',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
    );
  }

  String _getStatusText() {
    if (_isPunchedIn) {
      return 'Currently Working';
    } else if (_punchOutTime != null) {
      return 'Punched Out';
    } else {
      return 'Not Clocked In';
    }
  }

  Color _getStatusColor() {
    if (_isPunchedIn) {
      return Colors.green;
    } else if (_punchOutTime != null) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    if (_isPunchedIn || _punchOutTime != null) {
      return Icons.check_circle;
    } else {
      return Icons.radio_button_unchecked;
    }
  }

  String _formatTotalHours(String diff) {
    List<String> parts = diff.split(':');
    int h = int.parse(parts[0]);
    int m = int.parse(parts[1]);
    return '$h:$m hours';
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}