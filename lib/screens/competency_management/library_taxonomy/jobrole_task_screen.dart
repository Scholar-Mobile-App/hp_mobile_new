import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/job_role_task_table.dart';
import '../../../services/auth_provider.dart';
import '../../../services/api_service.dart';

class JobRoleTaskScreen extends StatefulWidget {
  final String sector;

  const JobRoleTaskScreen({Key? key, required this.sector}) : super(key: key);

  @override
  _JobRoleTaskScreenState createState() => _JobRoleTaskScreenState();
}

class _JobRoleTaskScreenState extends State<JobRoleTaskScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<JobRoleTaskTable> allTasks = [];
  List<JobRoleTaskTable> filteredTasks = [];
  bool _isLoading = true;
  String? _error;

  // Filter sets
  Set<String> selectedTracks = {};
  Set<String> selectedJobRoles = {};
  Set<String> selectedCriticalWorkFunctions = {};
  Set<String> selectedTaskTypes = {};

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    debugPrint('JobRoleTaskScreen: Starting to fetch tasks for sector: ${widget.sector}');
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) throw Exception('No user available');
      final token = auth.originalToken ?? user.token;
      debugPrint('JobRoleTaskScreen: User token: $token');
      debugPrint('JobRoleTaskScreen: User subInstituteId: ${user.subInstituteId}');

      debugPrint('JobRoleTaskScreen: Calling fetchJobRoleTasksTable API');
      final tasks = await _apiService.fetchJobRoleTasksTable(user, sector: widget.sector);
      debugPrint('JobRoleTaskScreen: API call completed, received ${tasks.length} tasks');

      setState(() {
        allTasks = tasks;
        filteredTasks = _applyFilters();
        _isLoading = false;
      });
      debugPrint('JobRoleTaskScreen: Applied filters, showing ${filteredTasks.length} tasks');
      debugPrint('JobRoleTaskScreen: State updated successfully');
    } catch (e) {
      debugPrint('JobRoleTaskScreen: Error fetching tasks: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching tasks: $e')),
      );
    }
  }

  List<JobRoleTaskTable> _applyFilters() {
    return allTasks.where((task) {
      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          task.jobrole.toLowerCase().contains(_searchQuery) ||
          task.task.toLowerCase().contains(_searchQuery) ||
          task.criticalWorkFunction.toLowerCase().contains(_searchQuery) ||
          task.track.toLowerCase().contains(_searchQuery);

      // Additional filters
      bool matchesTrack = selectedTracks.isEmpty || selectedTracks.contains(task.track);
      bool matchesJobRole = selectedJobRoles.isEmpty || selectedJobRoles.contains(task.jobrole);
      bool matchesCriticalWorkFunction = selectedCriticalWorkFunctions.isEmpty || selectedCriticalWorkFunctions.contains(task.criticalWorkFunction);
      bool matchesTaskType = selectedTaskTypes.isEmpty || selectedTaskTypes.contains(task.taskType);

      return matchesSearch && matchesTrack && matchesJobRole && matchesCriticalWorkFunction && matchesTaskType;
    }).toList();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        filteredTasks = _applyFilters();
      });
    });
  }

  void _showFilterDialog(BuildContext context) {
    // Get unique values for each filter category
    final allTracks = allTasks.map((t) => t.track).toSet().toList()..sort();
    final allJobRoles = allTasks.map((t) => t.jobrole).toSet().toList()..sort();
    final allCriticalWorkFunctions = allTasks.map((t) => t.criticalWorkFunction).toSet().toList()..sort();
    final allTaskTypes = allTasks.map((t) => t.taskType).toSet().toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottom) {
            // Filter job roles based on selected tracks
            final filteredJobRoles = selectedTracks.isEmpty
                ? allJobRoles
                : allTasks.where((t) => selectedTracks.contains(t.track))
                    .map((t) => t.jobrole).toSet().toList()..sort();

            // Filter critical work functions based on selected job roles
            final filteredCriticalWorkFunctions = selectedJobRoles.isEmpty
                ? allCriticalWorkFunctions
                : allTasks.where((t) => selectedJobRoles.contains(t.jobrole))
                    .map((t) => t.criticalWorkFunction).toSet().toList()..sort();

            return Container(
              padding: EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D))),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterSection('Department (Track)', allTracks, selectedTracks, setStateBottom),
                          if (selectedTracks.isNotEmpty || allTracks.length <= 5) // Show job roles if tracks selected or few tracks
                            _buildFilterSection('Job Role', filteredJobRoles, selectedJobRoles, setStateBottom),
                          if (selectedJobRoles.isNotEmpty || (selectedTracks.isNotEmpty && filteredJobRoles.length <= 5)) // Show critical functions if job roles selected or few options
                            _buildFilterSection('Critical Work Function', filteredCriticalWorkFunctions, selectedCriticalWorkFunctions, setStateBottom),
                          _buildFilterSection('Task Type', allTaskTypes, selectedTaskTypes, setStateBottom),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedTracks.clear();
                            selectedJobRoles.clear();
                            selectedCriticalWorkFunctions.clear();
                            selectedTaskTypes.clear();
                            filteredTasks = _applyFilters();
                          });
                          setStateBottom(() {});
                          Navigator.pop(context);
                        },
                        child: Text('Clear All', style: TextStyle(color: Colors.red)),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            filteredTasks = _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF6A00),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(String title, List<String> options, Set<String> selected, StateSetter setStateBottom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D))),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option, style: TextStyle(color: isSelected ? Colors.white : Color(0xFF1F2A6D))),
              selected: isSelected,
              onSelected: (bool value) {
                setStateBottom(() {
                  if (value) {
                    selected.add(option);
                  } else {
                    selected.remove(option);
                  }
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Color(0xFFFF6A00),
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Role Tasks - ${widget.sector}'),
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
                hintText: 'Search tasks, job roles, or work functions',
                prefixIcon: Icon(Icons.search, color: Color(0xFF1F2A6D)),
                suffixIcon: IconButton(
                  icon: Icon(Icons.filter_list, color: Color(0xFF1F2A6D)),
                  onPressed: () => _showFilterDialog(context),
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
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : filteredTasks.isEmpty
                        ? Center(child: Text('No tasks found'))
                        : ListView.builder(
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = filteredTasks[index];
                              return Card(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 4,
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
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                task.jobrole,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color(0xFF1F2A6D),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: task.taskType == 'High'
                                                    ? Colors.red.withOpacity(0.1)
                                                    : task.taskType == 'Medium'
                                                        ? Colors.orange.withOpacity(0.1)
                                                        : Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                task.taskType,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: task.taskType == 'High'
                                                      ? Colors.red
                                                      : task.taskType == 'Medium'
                                                          ? Colors.orange
                                                          : Colors.green,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Track: ${task.track}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Critical Work Function:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFF6A00),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          task.criticalWorkFunction,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Task:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2A6D),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          task.task,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                        if (task.taskCategory != null && task.taskCategory!.isNotEmpty) ...[
                                          SizedBox(height: 8),
                                          Text(
                                            'Category: ${task.taskCategory}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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
}