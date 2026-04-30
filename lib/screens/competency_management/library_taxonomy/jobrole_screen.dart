import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../models/jobrole.dart';
import '../../../models/job_role_task.dart';
import '../../../models/job_role_skill.dart';
import '../../../models/job_role_kaba.dart';
import '../../../services/auth_provider.dart';
import '../../../services/api_service.dart';

class JobRoleScreen extends StatefulWidget {
  const JobRoleScreen({Key? key}) : super(key: key);

  @override
  _JobRoleScreenState createState() => _JobRoleScreenState();
}

class _JobRoleScreenState extends State<JobRoleScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<JobRole> allJobRoles = [];
  List<JobRole> filteredJobRoles = [];
  String? _selectedDepartment;
  List<String> _departments = [];

  @override
  void initState() {
    super.initState();
    _fetchJobRoles();
    _fetchDepartments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchJobRoles() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) throw Exception('No user available');
      final token = auth.originalToken ?? user.token;

      final data = await _apiService.fetchJobRoles(user, token);
      setState(() {
        allJobRoles = data.map((json) => JobRole.fromJson(json)).toList();
        filteredJobRoles = _applyFilters();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching job roles: $e')),
      );
    }
  }

  List<JobRole> _applyFilters() {
    return allJobRoles.where((jobRole) {
      bool matchesSearch = _searchQuery.isEmpty ||
          jobRole.jobrole.toLowerCase().contains(_searchQuery) ||
          jobRole.department.toLowerCase().contains(_searchQuery) ||
          (jobRole.description ?? '').toLowerCase().contains(_searchQuery);
      bool matchesDepartment = _selectedDepartment == null || jobRole.department == _selectedDepartment;
      return matchesSearch && matchesDepartment;
    }).toList();
  }

  Future<void> _fetchDepartments() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) throw Exception('No user available');
      final token = auth.originalToken ?? user.token;

      final data = await _apiService.fetchJobRolesByDepartment(user, token);
      setState(() {
        _departments = data.keys.toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching departments: $e')),
      );
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        filteredJobRoles = _applyFilters();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Roles'),
        backgroundColor: Color(0xFF1F2A6D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search job roles',
                prefixIcon: Icon(Icons.search, color: Color(0xFF1F2A6D)),
                suffixIcon: IconButton(
                  icon: Icon(Icons.filter_list, color: Color(0xFF1F2A6D)),
                  onPressed: _showDepartmentFilter,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFFF6A00), width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredJobRoles.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredJobRoles.length,
                    itemBuilder: (context, index) {
                      final jobRole = filteredJobRoles[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Color(0xFFE8F4FD)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            leading: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFF1F2A6D).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.business_center,
                                color: Color(0xFF1F2A6D),
                                size: 28,
                              ),
                            ),
                            title: Text(
                              jobRole.jobrole,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF1F2A6D),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.apartment, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text(
                                      jobRole.department,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.factory, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text(
                                      jobRole.industries,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                if (jobRole.description != null && jobRole.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      jobRole.description!.length > 100
                                          ? '${jobRole.description!.substring(0, 100)}...'
                                          : jobRole.description!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFFFF6A00).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFFFF6A00),
                                size: 16,
                              ),
                            ),
                            onTap: () {
                              // Navigate to job role detail screen if needed
                              _showJobRoleDetails(context, jobRole);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showJobRoleDetails(BuildContext context, JobRole jobRole) {
    debugPrint('Showing job role details for: ${jobRole.jobrole}');
    showDialog(
      context: context,
      builder: (context) => JobRoleDetailDialog(jobRole: jobRole),
    );
  }

  void _showDepartmentFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Department'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                title: Text('All'),
                onTap: () {
                  setState(() {
                    _selectedDepartment = null;
                    filteredJobRoles = _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
              ..._departments.map((dept) => ListTile(
                title: Text(dept),
                onTap: () {
                  setState(() {
                    _selectedDepartment = dept;
                    filteredJobRoles = _applyFilters();
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6A00),
            ),
          ),
          SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

class JobRoleDetailDialog extends StatefulWidget {
  final JobRole jobRole;

  const JobRoleDetailDialog({Key? key, required this.jobRole}) : super(key: key);

  @override
  _JobRoleDetailDialogState createState() => _JobRoleDetailDialogState();
}

class _JobRoleDetailDialogState extends State<JobRoleDetailDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<JobRoleTask>? _tasks;
  JobRoleKABA? _kaba;
  List<JobRoleSkill>? _skills;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('JobRoleDetailDialog initState called');
    _fetchJobRoleDetails();
  }

  Future<void> _fetchJobRoleDetails() async {
    try {
      debugPrint('Starting to fetch job role details for: ${widget.jobRole.jobrole}');
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) throw Exception('No user available');
      final token = auth.originalToken ?? user.token;
      debugPrint('Using token: $token');

      // Fetch all 3 APIs in parallel
      debugPrint('Calling 3 APIs in parallel');
      final results = await Future.wait([
        _apiService.fetchJobRoleTasks(user, token, widget.jobRole.jobrole, widget.jobRole.id),
        _apiService.fetchJobRoleKABA(user, widget.jobRole.id),
        _apiService.fetchJobRoleSkills(user, token, widget.jobRole.jobrole),
      ]);

      debugPrint('All 3 APIs completed successfully');
      setState(() {
        _tasks = results[0] as List<JobRoleTask>;
        _kaba = results[1] as JobRoleKABA;
        _skills = results[2] as List<JobRoleSkill>;
        _isLoading = false;
        debugPrint('State updated: tasks=${_tasks?.length}, kaba=${_kaba?.title}, skills=${_skills?.length}');
      });
    } catch (e) {
      debugPrint('Error fetching job role details: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.jobRole.jobrole,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2A6D),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Divider(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : DefaultTabController(
                          length: 4,
                          child: Column(
                            children: [
                              TabBar(
                                isScrollable: true,
                                tabs: [
                                  Tab(text: 'Basic Info'),
                                  Tab(text: 'Tasks (${_tasks?.length ?? 0})'),
                                  Tab(text: 'KABA'),
                                  Tab(text: 'Skills (${_skills?.length ?? 0})'),
                                ],
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
    );
  }

  Widget _buildTasksTab() {
    if (_tasks == null || _tasks!.isEmpty) {
      return Center(child: Text('No tasks available'));
    }

    return ListView.builder(
      itemCount: _tasks!.length,
      itemBuilder: (context, index) {
        final task = _tasks![index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.task,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('Critical Work Function: ${task.criticalWorkFunction}'),
                Text('Type: ${task.taskType}'),
                Text('Created by: ${task.firstName} ${task.lastName}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKABATab() {
    if (_kaba == null) {
      return Center(child: Text('No KABA data available'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _kaba!.title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(_kaba!.description),
          SizedBox(height: 16),
          if (_kaba!.skill.isNotEmpty) ...[
            Text('Skills:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._kaba!.skill.map((item) => _buildKABAItem(item)),
          ],
          if (_kaba!.knowledge.isNotEmpty) ...[
            SizedBox(height: 16),
            Text('Knowledge:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._kaba!.knowledge.map((item) => _buildKABAItem(item)),
          ],
          if (_kaba!.ability.isNotEmpty) ...[
            SizedBox(height: 16),
            Text('Abilities:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._kaba!.ability.map((item) => _buildKABAItem(item)),
          ],
          if (_kaba!.attitude.isNotEmpty) ...[
            SizedBox(height: 16),
            Text('Attitude:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._kaba!.attitude.map((item) => _buildKABAItem(item)),
          ],
          if (_kaba!.behaviour.isNotEmpty) ...[
            SizedBox(height: 16),
            Text('Behaviour:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._kaba!.behaviour.map((item) => _buildKABAItem(item)),
          ],
        ],
      ),
    );
  }

  Widget _buildKABAItem(KABAItem item) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Category: ${item.category}'),
            Text('Sub-Category: ${item.subCategory}'),
            Text('Proficiency Level: ${item.proficiencyLevel}'),
            SizedBox(height: 4),
            Text(item.description),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsTab() {
    if (_skills == null || _skills!.isEmpty) {
      return Center(child: Text('No skills available'));
    }

    return ListView.builder(
      itemCount: _skills!.length,
      itemBuilder: (context, index) {
        final skill = _skills![index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.skillTitle,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Category: ${skill.category}'),
                Text('Sub-Category: ${skill.subCategory}'),
                Text('Proficiency Level: ${skill.proficiencyLevel}'),
                Text('Code: ${skill.skillCode}'),
                SizedBox(height: 4),
                Text(skill.skillDescription),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6A00),
            ),
          ),
          SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}