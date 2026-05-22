import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final int subjectId;
  final int standardId;
  final String courseName;

  const CourseDetailScreen({
    super.key,
    required this.subjectId,
    required this.standardId,
    required this.courseName,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _courseData;
  List<dynamic> _chapters = [];
  Map<String, dynamic> _contentData = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourseChapters();
  }

  Future<void> _loadCourseChapters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.originalToken ?? user?.token ?? '';

      if (user == null) throw Exception('User session not found');

      final apiService = ApiService();
      await apiService.loadCookies();

      final result = await apiService.fetchCourseChapters(
        subjectId: widget.subjectId,
        standardId: widget.standardId,
        user: user,
        token: token,
      );

      final rawContentData = result['content_data'];
      final parsedContentData = (rawContentData is Map)
          ? Map<String, dynamic>.from(rawContentData)
          : <String, dynamic>{};

      setState(() {
        _courseData = result;
        _chapters = (result['data'] is List) ? List<dynamic>.from(result['data']) : [];
        _contentData = parsedContentData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading course chapters: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.courseName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F2A6D),
        elevation: 0,
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
            : _error != null
                ? _buildErrorState()
                : _buildContent(),
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
            Text('Failed to load course', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCourseChapters,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_chapters.isEmpty) {
      return const Center(
        child: Text('No chapters available for this course.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chapters.length,
      itemBuilder: (context, index) {
        final chapter = _chapters[index];
        final chapterId = chapter['id'].toString();
        final chapterContent = _contentData[chapterId];
        List<dynamic> contents = [];

        if (chapterContent is Map) {
          // Collect all arrays inside the chapter (PDF, bulk, Flash Cards, etc.)
          chapterContent.forEach((key, value) {
            if (value is List) {
              contents.addAll(value);
            }
          });
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book, color: Color(0xFF1F2A6D)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        chapter['chapter_name'] ?? 'Chapter',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2A6D),
                        ),
                      ),
                    ),
                  ],
                ),
                if (chapter['chapter_desc'] != null && chapter['chapter_desc'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 36),
                    child: Text(
                      chapter['chapter_desc'],
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 12),
                if (contents.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Resources',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  ...contents.map<Widget>((content) => _buildResourceTile(content)).toList(),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(left: 36, top: 8),
                    child: Text(
                      'No resources available yet',
                      style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResourceTile(Map<String, dynamic> content) {
    final title = content['title'] ?? 'Resource';
    final fileType = (content['file_type'] ?? '').toString().toLowerCase();
    final url = content['url']?.toString() ?? '';
    final filename = content['filename']?.toString() ?? '';

    // Use filename as fallback when url is null/empty (common in this API)
    final finalUrl = url.isNotEmpty ? url : filename;

    IconData icon = Icons.insert_drive_file;
    if (fileType.contains('pdf') || fileType == 'link') icon = Icons.picture_as_pdf;
    if (fileType.contains('video')) icon = Icons.play_circle_fill;

    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF6A00)),
      title: Text(title),
      subtitle: Text(fileType.toUpperCase()),
      trailing: const Icon(Icons.open_in_new, size: 20),
      onTap: () async {
        if (finalUrl.isNotEmpty) {
          final uri = Uri.parse(finalUrl);
          try {
            final launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            if (!launched && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not open: $finalUrl')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error opening link')),
              );
            }
          }
        }
      },
    );
  }
}
