import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu.dart';
import '../../models/lms/assessment_model.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';

class AssessmentListScreen extends StatefulWidget {
  final MenuItem menuItem;

  const AssessmentListScreen({super.key, required this.menuItem});

  @override
  State<AssessmentListScreen> createState() => _AssessmentListScreenState();
}

class _AssessmentListScreenState extends State<AssessmentListScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _assessments = [];
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String? _error;

  List<Map<String, dynamic>> get _filteredAssessments {
    return _assessments.where((assessment) {
      final title = (assessment['title'] ?? '').toString().toLowerCase();
      final subject = (assessment['subject'] ?? '').toString().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          subject.contains(_searchQuery.toLowerCase());

      final status = (assessment['status'] ?? '').toString();
      final matchesStatus = _selectedStatus == 'All' || status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
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
          _assessments = [];
          _error = null;
          _isLoading = false;
        });
        return;
      }

      final apiService = ApiService();
      await apiService.loadCookies();

      List<Map<String, dynamic>> assessments = [];
      try {
        final realAssessments = await apiService.fetchAiGeneratedAssessments(user, token);

        assessments = realAssessments.map((a) {
          final paperName = a.paperName ?? 'Assessment';
          final closeDate = a.closeDate ?? '';
          final totalQ = a.totalQues ?? 0;

          String status = 'Pending';
          final now = DateTime.now();
          final close = (a.closeDate != null && a.closeDate!.isNotEmpty) ? DateTime.tryParse(a.closeDate!) : null;
          final open = (a.openDate != null && a.openDate!.isNotEmpty) ? DateTime.tryParse(a.openDate!) : null;
          if (close != null && now.isAfter(close)) {
            status = 'Completed';
          } else if (open != null && now.isBefore(open)) {
            status = 'Pending';
          } else if (a.questions.isNotEmpty) {
            status = 'Pending';
          }

          return {
            'id': a.id,
            'title': paperName,
            'subject': a.questions.isNotEmpty ? (a.questions.first.paperCategory ?? 'General') : 'General',
            'standard': '',
            'status': status,
            'score': null,
            'due_date': closeDate,
            'total_questions': totalQ,
            'attempts': 0,
            'raw_assessment': a,
          };
        }).toList();
      } catch (e) {
        debugPrint('Real assessment fetch failed: $e');
        rethrow;
      }

      if (mounted) {
        setState(() {
          _assessments = assessments;
          _error = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading assessments: $e');
      if (mounted) {
        setState(() {
          _assessments = [];
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAssessment(Map<String, dynamic> assessment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentDetailScreen(assessment: assessment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAssessments;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.menuItem.menuName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1F2A6D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAssessments,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1F2A6D).withOpacity(0.06), const Color(0xFF3B82F6).withOpacity(0.02)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search assessments by title or subject',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF1F2A6D)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF1F2A6D), width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', 'Pending', 'In Progress', 'Completed'].map((status) {
                        final isSelected = _selectedStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedStatus = status),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1F2A6D) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF1F2A6D) : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F2A6D)))
                  : _error != null
                      ? _buildErrorState()
                      : filtered.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadAssessments,
                              color: const Color(0xFF1F2A6D),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  return _buildAssessmentCard(filtered[index]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            const Text(
              'No assessments found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D)),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedStatus != 'All'
                  ? 'Try adjusting your search or filters'
                  : 'Assessments will appear here once available',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to load assessments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D)),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAssessments,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2A6D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> assessment) {
    final title = (assessment['title'] ?? 'Assessment').toString();
    final subject = (assessment['subject'] ?? '').toString();
    final standard = (assessment['standard'] ?? '').toString();
    final status = (assessment['status'] ?? 'Pending').toString();
    final score = assessment['score'];
    final dueDate = (assessment['due_date'] ?? '').toString();
    final totalQ = assessment['total_questions'] ?? 0;
    final attempts = assessment['attempts'] ?? 0;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'Completed':
        statusColor = const Color(0xFF059669);
        statusLabel = 'Completed';
        break;
      case 'In Progress':
        statusColor = const Color(0xFFD97706);
        statusLabel = 'In Progress';
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusLabel = 'Pending';
    }

    final bool hasScore = score != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
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
                    Icons.quiz,
                    color: Color(0xFF1F2A6D),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2A6D),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (subject.isNotEmpty || standard.isNotEmpty)
                        Text(
                          [subject, standard].where((s) => s.isNotEmpty).join(' • '),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == 'Completed'
                            ? Icons.check_circle
                            : status == 'In Progress'
                                ? Icons.timelapse
                                : Icons.schedule,
                        size: 15,
                        color: statusColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (hasScore)
                  _buildInfoChip(Icons.emoji_events, '$score%', const Color(0xFFB45309)),
                _buildInfoChip(Icons.format_list_numbered, '$totalQ Qs', Colors.grey[700]!),
                _buildInfoChip(Icons.history, '$attempts attempt${attempts == 1 ? '' : 's'}', Colors.grey[700]!),
                if (dueDate.isNotEmpty)
                  _buildInfoChip(Icons.event, 'Due $dueDate', status == 'Pending' ? const Color(0xFFDC2626) : Colors.grey[700]!),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToAssessment(assessment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  status == 'Completed'
                      ? 'View Results'
                      : status == 'In Progress'
                          ? 'Continue Assessment'
                          : 'Start Assessment',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AssessmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> assessment;

  const AssessmentDetailScreen({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final title = assessment['title'] ?? 'Assessment';
    final subject = assessment['subject'] ?? '';
    final standard = assessment['standard'] ?? '';
    final status = assessment['status'] ?? 'Pending';
    final score = assessment['score'];
    final dueDate = assessment['due_date'] ?? 'N/A';
    final totalQ = assessment['total_questions'] ?? 0;
    final attempts = assessment['attempts'] ?? 0;

    final rawAssessment = assessment['raw_assessment'] as Assessment?;
    final description = rawAssessment?.paperDesc ?? '';
    final attemptAllowed = rawAssessment?.attemptAllowed ?? '';
    final numQuestions = rawAssessment?.questions.length ?? totalQ;

    final bool isCompleted = status == 'Completed';
    final bool inProgress = status == 'In Progress';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1F2A6D),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F2A6D), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1F2A6D).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [subject, standard].where((s) => s.isNotEmpty).join(' • '),
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isCompleted && score != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: CircularProgressIndicator(
                                  value: (score as num) / 100,
                                  strokeWidth: 9,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$score%',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'SCORE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Assessment Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2A6D),
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Due Date', dueDate),
            _buildDetailRow('Total Questions', '$numQuestions'),
            _buildDetailRow('Attempts Made', '$attempts'),
            _buildDetailRow('Status', status),
            if (attemptAllowed.isNotEmpty) _buildDetailRow('Attempts Allowed', attemptAllowed),
            if (score != null) _buildDetailRow('Your Best Score', '$score%'),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2A6D)),
              ),
              const SizedBox(height: 8),
              Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final raw = assessment['raw_assessment'] as Assessment?;
                  if (raw != null && raw.questions.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssessmentPlayerScreen(assessment: raw),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Assessment player / results coming soon')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                ),
                child: Text(
                  isCompleted
                      ? 'Retake Assessment'
                      : inProgress
                          ? 'Resume Assessment'
                          : 'Begin Assessment',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isCompleted)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to List', style: TextStyle(color: Color(0xFF1F2A6D))),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class AssessmentPlayerScreen extends StatefulWidget {
  final Assessment assessment;

  const AssessmentPlayerScreen({super.key, required this.assessment});

  @override
  State<AssessmentPlayerScreen> createState() => _AssessmentPlayerScreenState();
}

class _AssessmentPlayerScreenState extends State<AssessmentPlayerScreen> {
  final Map<int, Set<int>> _selectedAnswers = {};
  bool _submitted = false;
  int _score = 0;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final questions = widget.assessment.questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.assessment.paperName ?? 'Assessment', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF1F2A6D),
          elevation: 0,
        ),
        body: const Center(child: Text('No questions available')),
      );
    }
    final q = questions[_currentIndex];
    final qSelected = _selectedAnswers[q.id] ?? <int>{};
    final progress = (_currentIndex + 1) / questions.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment.paperName ?? 'Assessment', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1F2A6D),
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('${_currentIndex + 1}/${questions.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: Colors.grey[200],
            color: const Color(0xFFFF6A00),
          ),
          if (_submitted)
            Container(
              width: double.infinity,
              color: const Color(0xFF059669),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text('Score: $_score%  •  Review answers below', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Question ${_currentIndex + 1} of ${questions.length}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text(q.description ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D), height: 1.35)),
                        const SizedBox(height: 20),
                        const Text('Select your answer(s)', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 10),
                        ...q.answers.map((ans) {
                          final isSelected = qSelected.contains(ans.id);
                          Color borderColor = Colors.grey.shade300;
                          Color iconColor = Colors.grey.shade400;
                          IconData icon = Icons.radio_button_unchecked;
                          if (_submitted) {
                            final isCorrect = ans.correctAnswer == 1;
                            if (isSelected && isCorrect) {
                              borderColor = const Color(0xFF059669);
                              iconColor = const Color(0xFF059669);
                              icon = Icons.check_circle;
                            } else if (isSelected && !isCorrect) {
                              borderColor = const Color(0xFFDC2626);
                              iconColor = const Color(0xFFDC2626);
                              icon = Icons.cancel;
                            } else if (!isSelected && isCorrect) {
                              borderColor = const Color(0xFF059669);
                              iconColor = const Color(0xFF059669);
                              icon = Icons.check_circle_outline;
                            }
                          } else if (isSelected) {
                            borderColor = const Color(0xFF1F2A6D);
                            iconColor = const Color(0xFF1F2A6D);
                            icon = Icons.check_circle;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: _submitted
                                  ? null
                                  : () {
                                      setState(() {
                                        final set = _selectedAnswers.putIfAbsent(q.id, () => <int>{});
                                        if (isSelected) {
                                          set.remove(ans.id);
                                        } else {
                                          set.add(ans.id);
                                        }
                                      });
                                    },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected && !_submitted ? const Color(0xFF1F2A6D).withOpacity(0.05) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Icon(icon, size: 22, color: iconColor),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        ans.answer ?? '',
                                        style: TextStyle(fontSize: 15, color: _submitted && !isSelected && ans.correctAnswer == 1 ? const Color(0xFF059669) : const Color(0xFF1F2A6D), fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentIndex--),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1F2A6D),
                        side: const BorderSide(color: Color(0xFF1F2A6D)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Previous', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentIndex < questions.length - 1) {
                        setState(() => _currentIndex++);
                      } else if (!_submitted) {
                        _submitAssessment(questions);
                      } else {
                        Navigator.of(context).pop(_score);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentIndex < questions.length - 1
                          ? 'Next'
                          : _submitted
                              ? 'Finish'
                              : 'Submit Assessment',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submitAssessment(List<Question> questions) {
    int correctCount = 0;
    for (final q in questions) {
      final selected = _selectedAnswers[q.id] ?? <int>{};
      final correctIds = q.answers.where((a) => a.correctAnswer == 1).map((a) => a.id).toSet();
      if (selected.length == correctIds.length && selected.containsAll(correctIds)) {
        correctCount++;
      }
    }
    final percent = questions.isNotEmpty ? (correctCount * 100 / questions.length).round() : 0;
    setState(() {
      _submitted = true;
      _score = percent;
    });
  }
}
