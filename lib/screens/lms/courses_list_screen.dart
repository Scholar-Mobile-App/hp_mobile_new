import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import 'enrollment_success_dialog.dart';
import 'course_detail_screen.dart';

class CoursesListScreen extends StatefulWidget {
  final MenuItem menuItem;

  const CoursesListScreen({super.key, required this.menuItem});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _courses = [];

  // Search & Filter state
  String _searchQuery = '';
  Set<String> _selectedCategories = {};
  bool _showOnlyEnrolled = false;
  bool _isSearching = false;

  List<Map<String, dynamic>> get _filteredCourses {
    return _courses.where((course) {
      final title = (course['subject_name'] ?? '').toString().toLowerCase();
      final standard = (course['standard_name'] ?? '').toString().toLowerCase();
      final jobrole = (course['jobrole'] ?? '').toString().toLowerCase();
      final category = (course['content_category'] ?? '').toString();

      final matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          standard.contains(_searchQuery.toLowerCase()) ||
          jobrole.contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategories.isEmpty ||
          _selectedCategories.contains(category);

      final matchesEnrolled = !_showOnlyEnrolled ||
          ((course['enrollment_status'] ?? '').toString().toLowerCase() == 'enrolled');

      return matchesSearch && matchesCategory && matchesEnrolled;
    }).toList();
  }

  List<String> get _allCategories {
    return _courses
        .map((c) => (c['content_category'] ?? '').toString())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.originalToken ?? user?.token ?? '';

      if (user == null) {
        setState(() {
          _courses = [];
          _isLoading = false;
        });
        return;
      }

      final apiService = ApiService();
      await apiService.loadCookies();

      final result = await apiService.fetchLmsCourses(user, token);
      setState(() {
        _courses = result
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading LMS courses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load courses: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        setState(() {
          _courses = [];
          _isLoading = false;
        });
      }
    }
  }

  void _showFilterBottomSheet() {
    final categories = _allCategories;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Courses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2A6D),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategories.clear();
                            _showOnlyEnrolled = false;
                          });
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Categories',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = _selectedCategories.contains(cat);
                      return FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedCategories.add(cat);
                            } else {
                              _selectedCategories.remove(cat);
                            }
                          });
                          setState(() {});
                        },
                        selectedColor: const Color(0xFFFF6A00).withOpacity(0.2),
                        checkmarkColor: const Color(0xFFFF6A00),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Show only Enrolled courses'),
                    value: _showOnlyEnrolled,
                    activeColor: const Color(0xFFFF6A00),
                    onChanged: (val) {
                      setModalState(() {
                        _showOnlyEnrolled = val;
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2A6D),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleEnroll(Map<String, dynamic> course) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final token = auth.originalToken ?? user?.token ?? '';

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User session not found')),
      );
      return;
    }

    final subjectId = _getNum(course, ['subject_id', 'id'], 0).toInt();
    final standardId = _getNum(course, ['standard_id'], 0).toInt();

    if (subjectId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid course data')),
      );
      return;
    }

    try {
      final apiService = ApiService();
      await apiService.loadCookies();

      await apiService.enrollInCourse(
        subjectId: subjectId,
        standardId: standardId,
        courseId: subjectId,
        user: user,
        token: token,
      );

      // Update local data so the card immediately shows as enrolled
      final index = _courses.indexWhere((c) =>
          _getNum(c, ['subject_id', 'id'], 0) == subjectId);

      if (index != -1) {
        setState(() {
          _courses[index]['enrollment_status'] = 'enrolled';
        });
      }

      // Show beautiful celebratory animation
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => EnrollmentSuccessDialog(
            courseName: _getString(course, ['subject_name'], 'this course'),
            onStartLearning: () => _openCourseDetail(course),
          ),
        );
      }
    } catch (e) {
      debugPrint('Enroll error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enrollment failed: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _openCourseDetail(Map<String, dynamic> course) async {
    final subjectId = _getNum(course, ['subject_id', 'id'], 0).toInt();
    final standardId = _getNum(course, ['standard_id'], 0).toInt();
    final courseName = _getString(course, ['subject_name', 'title'], 'Course');

    if (subjectId == 0 || standardId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid course data')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6A00))),
    );

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.originalToken ?? user?.token ?? '';

      if (user == null) throw Exception('Session not found');

      final apiService = ApiService();
      await apiService.loadCookies();

      final result = await apiService.fetchCourseChapters(
        subjectId: subjectId,
        standardId: standardId,
        user: user,
        token: token,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Navigate to detail screen with the data
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              subjectId: subjectId,
              standardId: standardId,
              courseName: courseName,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load course: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search courses...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text(
                widget.menuItem.menuName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        backgroundColor: const Color(0xFF1F2A6D),
        elevation: 0,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: _showFilterBottomSheet,
                ),
                if (_selectedCategories.isNotEmpty || _showOnlyEnrolled)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6A00),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1F2A6D).withOpacity(0.08),
              const Color(0xFF2E3A8C).withOpacity(0.04),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6A00)))
            : _courses.isEmpty
                ? _buildEmptyState()
                : _buildCoursesList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create/enroll flow
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enroll in new courses - Coming soon')),
          );
        },
        backgroundColor: const Color(0xFFFF6A00),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No courses available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new courses',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    final coursesToShow = _filteredCourses;

    if (coursesToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No courses match your search/filter',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedCategories.clear();
                  _showOnlyEnrolled = false;
                  _isSearching = false;
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coursesToShow.length,
      itemBuilder: (context, index) {
        final course = coursesToShow[index];
        return _buildCourseCard(course);
      },
    );
  }

  // Helper to safely get string value trying multiple possible keys
  String _getString(Map<String, dynamic> map, List<String> keys, [String fallback = '']) {
    for (final key in keys) {
      if (map[key] != null) {
        return map[key].toString();
      }
    }
    return fallback;
  }

  // Helper to get numeric value trying multiple keys
  num _getNum(Map<String, dynamic> map, List<String> keys, [num fallback = 0]) {
    for (final key in keys) {
      final val = map[key];
      if (val != null) {
        if (val is num) return val;
        return num.tryParse(val.toString()) ?? fallback;
      }
    }
    return fallback;
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    // Real API keys from /lms/course_master response
    final title = _getString(course, ['subject_name', 'title', 'name', 'course_name'], 'Untitled Course');
    final standard = _getString(course, ['standard_name', 'standard'], '');
    final jobrole = _getString(course, ['jobrole', 'job_role'], '');
    final category = _getString(course, ['content_category', 'category'], '');
    final enrollmentStatus = _getString(course, ['enrollment_status', 'status'], '');
    final subjectId = _getNum(course, ['subject_id', 'id'], 0);

    final isEnrolled = enrollmentStatus.toLowerCase() == 'enrolled';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2A6D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Color(0xFF1F2A6D),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2A6D),
                        ),
                      ),
                      if (standard.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          standard,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (jobrole.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'For: $jobrole',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isEnrolled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Enrolled',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (category.isNotEmpty)
                  _buildInfoChip(Icons.category, category),
                if (subjectId > 0)
                  _buildInfoChip(Icons.tag, 'ID: ${subjectId.toInt()}'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (isEnrolled) {
                    await _openCourseDetail(course);
                  } else {
                    await _handleEnroll(course);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEnrolled ? 'Continue Learning' : 'View / Enroll',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
