import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/job_role_task.dart';
import '../../../models/job_role_skill.dart';
import '../../../models/job_role_kaba.dart';
import '../../../models/jobrole.dart';
import '../../../services/auth_provider.dart';
import '../../../services/api_service.dart';

class JobRoleDetailScreen extends StatefulWidget {
  final JobRole jobRole;

  const JobRoleDetailScreen({Key? key, required this.jobRole}) : super(key: key);

  @override
  _JobRoleDetailScreenState createState() => _JobRoleDetailScreenState();
}

class _JobRoleDetailScreenState extends State<JobRoleDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<JobRoleTask>? _tasks;
  JobRoleKABA? _kaba;
  List<JobRoleSkill>? _skills;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchJobRoleDetails();
  }

  Future<void> _fetchJobRoleDetails() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) throw Exception('No user available');
      final token = auth.originalToken ?? user.token;

      // Fetch all 3 APIs in parallel
      final results = await Future.wait([
        _apiService.fetchJobRoleTasks(user, token, widget.jobRole.jobrole, widget.jobRole.id),
        _apiService.fetchJobRoleKABA(user, widget.jobRole.id),
        _apiService.fetchJobRoleSkills(user, token, widget.jobRole.jobrole),
      ]);

      setState(() {
        _tasks = results[0] as List<JobRoleTask>;
        _kaba = results[1] as JobRoleKABA;
        _skills = results[2] as List<JobRoleSkill>;
        _isLoading = false;
      });
    } catch (e) {
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
        title: Text(widget.jobRole.jobrole),
        backgroundColor: Color(0xFF1F2A6D),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading job role details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchJobRoleDetails,
                          child: Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF6A00),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      Container(
                        color: Color(0xFF1F2A6D),
                        child: TabBar(
                          isScrollable: true,
                          indicatorColor: Color(0xFFFF6A00),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
                          tabs: [
                            Tab(text: 'Basic Info'),
                            Tab(text: 'Tasks (${_tasks?.length ?? 0})'),
                            Tab(text: 'KABA'),
                            Tab(text: 'Skills (${_skills?.length ?? 0})'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildBasicInfoTab(),
                            _buildTasksTab(),
                            _buildKABATab(),
                            _buildSkillsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Role Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2A6D),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildDetailRow('Industry', widget.jobRole.industries),
                  _buildDetailRow('Department', widget.jobRole.department),
                  if (widget.jobRole.subDepartment != null && widget.jobRole.subDepartment!.isNotEmpty)
                    _buildDetailRow('Sub-Department', widget.jobRole.subDepartment!),
                  if (widget.jobRole.description != null && widget.jobRole.description!.isNotEmpty)
                    _buildDetailRow('Description', widget.jobRole.description!),
                  if (widget.jobRole.education != null && widget.jobRole.education!.isNotEmpty)
                    _buildDetailRow('Education', widget.jobRole.education!),
                  if (widget.jobRole.experience != null && widget.jobRole.experience!.isNotEmpty)
                    _buildDetailRow('Experience', widget.jobRole.experience!),
                  if (widget.jobRole.training != null && widget.jobRole.training!.isNotEmpty)
                    _buildDetailRow('Training', widget.jobRole.training!),
                  if (widget.jobRole.relatedJobrole != null && widget.jobRole.relatedJobrole!.isNotEmpty)
                    _buildDetailRow('Related Job Roles', widget.jobRole.relatedJobrole!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    if (_tasks == null || _tasks!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tasks available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _tasks!.length,
      itemBuilder: (context, index) {
        final task = _tasks![index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 3,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6A00).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.task,
                        color: Color(0xFFFF6A00),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.task,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2A6D),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildTaskDetail('Critical Work Function', task.criticalWorkFunction),
                _buildTaskDetail('Type', task.taskType),
                _buildTaskDetail('Created by', '${task.firstName} ${task.lastName}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKABATab() {
    if (_kaba == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No KABA data available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _kaba!.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2A6D),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _kaba!.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          if (_kaba!.skill.isNotEmpty) ...[
            _buildKABASection('Skills', _kaba!.skill),
            SizedBox(height: 16),
          ],
          if (_kaba!.knowledge.isNotEmpty) ...[
            _buildKABASection('Knowledge', _kaba!.knowledge),
            SizedBox(height: 16),
          ],
          if (_kaba!.ability.isNotEmpty) ...[
            _buildKABASection('Abilities', _kaba!.ability),
            SizedBox(height: 16),
          ],
          if (_kaba!.attitude.isNotEmpty) ...[
            _buildKABASection('Attitude', _kaba!.attitude),
            SizedBox(height: 16),
          ],
          if (_kaba!.behaviour.isNotEmpty) ...[
            _buildKABASection('Behaviour', _kaba!.behaviour),
          ],
        ],
      ),
    );
  }

  Widget _buildKABASection(String title, List<KABAItem> items) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForCategory(title),
                  color: Color(0xFFFF6A00),
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2A6D),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...items.map((item) => _buildKABAItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildKABAItem(KABAItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2A6D),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Category: ${item.category} • Sub-Category: ${item.subCategory} • Level: ${item.proficiencyLevel}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    if (_skills == null || _skills!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No skills available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _skills!.length,
      itemBuilder: (context, index) {
        final skill = _skills![index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 3,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF1F2A6D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.star,
                        color: Color(0xFF1F2A6D),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        skill.skillTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2A6D),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildSkillDetail('Category', skill.category),
                _buildSkillDetail('Sub-Category', skill.subCategory),
                _buildSkillDetail('Proficiency Level', skill.proficiencyLevel),
                _buildSkillDetail('Skill Code', skill.skillCode),
                SizedBox(height: 8),
                Text(
                  skill.skillDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6A00),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'skills':
        return Icons.build;
      case 'knowledge':
        return Icons.school;
      case 'abilities':
        return Icons.accessibility;
      case 'attitude':
        return Icons.sentiment_satisfied;
      case 'behaviour':
        return Icons.people;
      default:
        return Icons.category;
    }
  }
}