import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import 'courses_list_screen.dart';

class MyLearningDashboardScreen extends StatefulWidget {
  final MenuItem menuItem;

  const MyLearningDashboardScreen({super.key, required this.menuItem});

  @override
  State<MyLearningDashboardScreen> createState() => _MyLearningDashboardScreenState();
}

class _MyLearningDashboardScreenState extends State<MyLearningDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _progressData;
  Map<String, dynamic>? _calendarData;
  List<Map<String, dynamic>> _enrolledCourses = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.originalToken ?? user?.token ?? '';

      if (user == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final apiService = ApiService();
      await apiService.loadCookies();

      final progress = await apiService.fetchSkillDevelopmentProgress(user, token);

      Map<String, dynamic>? calendar;
      try {
        calendar = await apiService.fetchSkillDevelopmentCalendar(user, token);
      } catch (e) {
        debugPrint('Calendar fetch failed (non-fatal): $e');
      }

      // Load enrolled courses using the dedicated enrolled_courses API
      List<Map<String, dynamic>> enrolled = [];
      try {
        final enrolledResult = await apiService.fetchEnrolledCourses(user, token);
        enrolled = enrolledResult
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } catch (e) {
        debugPrint('Enrolled courses fetch failed (non-fatal): $e');
      }

      if (mounted) {
        setState(() {
          _progressData = progress;
          _calendarData = calendar;
          _enrolledCourses = enrolled;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading learning dashboard: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load learning dashboard: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final skillProgress = _progressData?['data']?['skill_progress'] as List<dynamic>? ?? [];
    final overall = _progressData?['data']?['overall'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.menuItem.menuName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F2A6D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1F2A6D).withOpacity(0.05),
                        const Color(0xFF3B82F6).withOpacity(0.015),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverallProgressCard(overall),
                          const SizedBox(height: 24),
                          _buildEnrolledCoursesSection(),
                          const SizedBox(height: 24),
                          const Text(
                            'Skill Progress',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D)),
                          ),
                          const SizedBox(height: 12),
                          if (skillProgress.isEmpty)
                            _buildEmptySkills()
                          else
                            ...skillProgress.map((item) => _buildSkillCard(Map<String, dynamic>.from(item))).toList(),
                          const SizedBox(height: 24),
                          _buildCalendarSection(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F2A6D)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgressCard(Map<String, dynamic> overall) {
    final overallPct = (overall['overall_progress_percentage'] ?? 0).toDouble();
    final totalSkills = overall['total_skills'] ?? 0;
    final inProgress = overall['skills_in_progress'] ?? 0;
    final avg = (overall['average_progress'] ?? 0).toDouble();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1F2A6D), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Overall Learning Progress',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: overallPct / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Text(
                  '${overallPct.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Skills', '$totalSkills'),
                _buildStatItem('In Progress', '$inProgress'),
                _buildStatItem('Avg Progress', '${avg.toStringAsFixed(0)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildEnrolledCoursesSection() {
    if (_enrolledCourses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Enrolled Courses',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'You have not enrolled in any courses yet.\nExplore the Courses List to get started!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Enrolled Courses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D)),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full courses list (user can use filter there)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoursesListScreen(menuItem: widget.menuItem),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._enrolledCourses.take(5).map((course) => _buildEnrolledCourseTile(course)).toList(),
        if (_enrolledCourses.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ ${(_enrolledCourses.length - 5)} more enrolled courses',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildEnrolledCourseTile(Map<String, dynamic> course) {
    final title = (course['display_name'] ?? course['subject_name'] ?? course['title'] ?? 'Course').toString();
    final standard = (course['standard_name'] ?? course['standard_id']?.toString() ?? '').toString();
    final jobrole = (course['jobrole'] ?? '').toString();
    final category = (course['subject_category'] ?? course['content_category'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1F2A6D),
          child: const Icon(Icons.school, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [standard, jobrole, category].where((s) => s.isNotEmpty).join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Open full courses list for now (can enhance to course detail later)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoursesListScreen(menuItem: widget.menuItem),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skill) {
    final name = skill['skill_name'] ?? 'Skill';
    final sub = skill['sub_category'] ?? '';
    final pct = (skill['progress_percentage'] ?? 0).toDouble();
    final level = skill['proficiency_level'] ?? '';
    final completed = skill['courses_completed'] ?? 0;
    final total = skill['total_courses'] ?? 0;
    final status = (skill['status'] ?? '').toString().toLowerCase();

    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'in-progress':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      if (sub.isNotEmpty)
                        Text(sub, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(pct >= 100 ? Colors.green : const Color(0xFF3B82F6)),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('$level', style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$completed of $total courses completed',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySkills() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: const Text('No skill progress data available yet.', style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildCalendarSection() {
    final events = _calendarData?['data']?['events'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learning Calendar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D)),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: events.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No upcoming learning events this month.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : Column(
                    children: events.map((e) {
                      final ev = Map<String, dynamic>.from(e);
                      return ListTile(
                        leading: const Icon(Icons.event, color: Color(0xFF1F2A6D)),
                        title: Text(ev['title'] ?? 'Event'),
                        subtitle: Text('${ev['date'] ?? ''} ${ev['time'] ?? ''}'),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }
}
