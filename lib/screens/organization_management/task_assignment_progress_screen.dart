import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../models/task.dart';
import 'task_details_screen.dart';
import 'package:another_flushbar/flushbar.dart';

class TaskAssignmentProgressScreen extends StatefulWidget {
  const TaskAssignmentProgressScreen({super.key});

  @override
  State<TaskAssignmentProgressScreen> createState() =>
      _TaskAssignmentProgressScreenState();
}

class _TaskAssignmentProgressScreenState
    extends State<TaskAssignmentProgressScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isViewingTasks = true; // Start with viewing tasks
  List<Task> assignedTasks = [];
  bool isLoadingAssignedTasks = true;
  String? selectedDepartment;
  String? selectedJobRole;
  String? selectedJobRoleName;
  String? selectedRepeatDays;
  DateTime? selectedRepeatUntil;
  String? selectedPriority;
  String _selectedTaskStatusFilter = 'all';
  bool _sortNewestFirst = true;

  // Responsive design helpers
  double getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 16.0; // Small phones
    if (screenWidth < 480) return 20.0; // Medium phones
    return 24.0; // Large phones/tablets
  }

  double getResponsiveMargin(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 8.0;
    if (screenWidth < 480) return 12.0;
    return 16.0;
  }

  double getResponsiveTextSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 375.0; // Base on iPhone 6/7/8 width
    return baseSize * scale.clamp(0.8, 1.2); // Limit scaling range
  }

  double getResponsiveIconSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 375.0;
    return baseSize * scale.clamp(0.85, 1.15);
  }

  List<String> departments = [];
  List<Map<String, dynamic>> jobRoles = [];
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> jobRoleTasks = [];
  List<Map<String, dynamic>> filteredTasks = [];
  List<Map<String, dynamic>> skills = [];
  Map<String, dynamic>? observer;
  Set<String> selectedEmployeeIds = {};
  Set<String> selectedSkillIds = {};
  String taskTitle = '';
  String taskDescription = '';
  final TextEditingController taskTitleController = TextEditingController();
  final TextEditingController taskDescriptionController = TextEditingController();
  final FocusNode taskTitleFocusNode = FocusNode();
  bool isLoadingDepartments = true;
  bool isLoadingJobRoles = false;
  bool isLoadingEmployees = false;
  bool isLoadingTasks = false;
  bool isLoadingSkills = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Force rebuild when tab changes
    });
    _initializeNotifications();
    fetchAssignedTasks();
    taskTitleFocusNode.addListener(() {
      if (taskTitleFocusNode.hasFocus && taskTitle.isEmpty) {
        setState(() {
          filteredTasks = List.from(jobRoleTasks);
        });
      } else if (!taskTitleFocusNode.hasFocus) {
        setState(() {
          filteredTasks = [];
        });
      }
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      // FCM token is now handled at login time
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    taskTitleController.dispose();
    taskDescriptionController.dispose();
    taskTitleFocusNode.dispose();
    super.dispose();
  }

  Future<void> fetchObserver(int userId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    final apiService = ApiService();
    await apiService.loadCookies();

    try {
      final observerData = await apiService.fetchSupervisor(userId, user.subInstituteId);
      setState(() {
        observer = observerData;
      });
    } catch (e) {
      debugPrint('Error fetching observer for user $userId: $e');
      setState(() {
        observer = null;
      });
    }
  }

  Future<void> fetchSkills() async {
    setState(() {
      isLoadingSkills = true;
      skills = [];
      selectedSkillIds = {};
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    final apiService = ApiService();
    await apiService.loadCookies();

    try {
      final token = auth.originalToken ?? user.token;
      final skillsData = await apiService.fetchUserSkills(user, token);
      setState(() {
        skills = List<Map<String, dynamic>>.from(skillsData);
        isLoadingSkills = false;
      });
    } catch (e) {
      debugPrint('Error fetching skills: $e');
      setState(() {
        isLoadingSkills = false;
      });
    }
  }

  Future<void> fetchDepartments() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    final apiService = ApiService();
    await apiService.loadCookies();

    try {
      final token = auth.originalToken ?? user.token;
      final departmentsData = await apiService.fetchDepartments(user, token);
      setState(() {
        departments = departmentsData;
        isLoadingDepartments = false;
      });
    } catch (e) {
      debugPrint('Error fetching departments: $e');
      setState(() {
        isLoadingDepartments = false;
      });
    }
  }

  Future<void> fetchJobRoles(String department) async {
    setState(() {
      isLoadingJobRoles = true;
      jobRoles = [];
      selectedJobRole = null;
      selectedJobRoleName = null;
      employees = [];
      selectedEmployeeIds = {};
    });
    updateSelectedSkills();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    final apiService = ApiService();
    await apiService.loadCookies();

    try {
      final token = auth.originalToken ?? user.token;
      final jobRolesData = await apiService.fetchJobRolesByDepartmentName(
        user,
        token,
        department,
      );
      setState(() {
        jobRoles = List<Map<String, dynamic>>.from(jobRolesData);
        isLoadingJobRoles = false;
      });
    } catch (e) {
      debugPrint('Error fetching job roles: $e');
      setState(() {
        isLoadingJobRoles = false;
      });
    }
  }

  Future<void> fetchEmployees(String jobRoleId) async {
    setState(() {
      isLoadingEmployees = true;
      employees = [];
      selectedEmployeeIds = {};
      jobRoleTasks = [];
      taskTitle = '';
      taskTitleController.clear();
      taskDescription = '';
      taskDescriptionController.clear();
      selectedRepeatDays = null;
      selectedRepeatUntil = null;
      selectedPriority = null;
      filteredTasks = [];
    });
    updateSelectedSkills();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    final apiService = ApiService();
    await apiService.loadCookies();

    try {
      final token = auth.originalToken ?? user.token;
      final employeesData = await apiService.fetchEmployeesByJobRole(
        user,
        token,
        jobRoleId,
      );
      setState(() {
        employees = List<Map<String, dynamic>>.from(employeesData);
        isLoadingEmployees = false;
      });
      await fetchTasks(jobRoleId);
    } catch (e) {
      debugPrint('Error fetching employees: $e');
      setState(() {
        isLoadingEmployees = false;
      });
    }
  }

  Future<void> fetchTasks(String jobRoleId) async {
    setState(() {
      isLoadingTasks = true;
      jobRoleTasks = [];
      filteredTasks = [];
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    final apiService = ApiService();
    await apiService.loadCookies();

    try {
      final selectedJobRoleData = jobRoles.firstWhere(
        (role) => role['id'].toString() == jobRoleId,
      );
      final jobRoleName = selectedJobRoleData['jobrole'] as String;
      final tasksData = await apiService.fetchJobRoleTasksTable(user, jobrole: jobRoleName);
      setState(() {
        jobRoleTasks = tasksData
            .map(
              (task) => {
                'id': task.id,
                'task': task.task,
                'critical_work_function': task.criticalWorkFunction,
                'task_type': task.taskType,
              },
            )
            .toList();
        isLoadingTasks = false;
      });
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      setState(() {
        isLoadingTasks = false;
      });
    }
  }

  Future<void> fetchAssignedTasks() async {
    setState(() {
      isLoadingAssignedTasks = true;
      assignedTasks = [];
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      setState(() {
        isLoadingAssignedTasks = false;
      });
      return;
    }

    final apiService = ApiService();
    await apiService.loadCookies();

    try {
      final token = auth.originalToken ?? user.token;
      final tasksData = await apiService.fetchAssignedTasks(user, token);
      setState(() {
        assignedTasks = tasksData;
        isLoadingAssignedTasks = false;
      });
    } catch (e) {
      debugPrint('Error fetching assigned tasks: $e');
      setState(() {
        isLoadingAssignedTasks = false;
      });
    }
  }

  Future<void> _selectRepeatUntilDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedRepeatUntil ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedRepeatUntil) {
      setState(() {
        selectedRepeatUntil = picked;
      });
    }
  }

  Future<void> updateSelectedSkills() async {
    setState(() {
      skills = [];
      isLoadingSkills = true;
    });

    if (selectedEmployeeIds.isEmpty) {
      setState(() {
        isLoadingSkills = false;
        observer = null;
      });
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    final apiService = ApiService();
    await apiService.loadCookies();

    final token = auth.originalToken ?? user.token;

    final Set<Map<String, dynamic>> allSkills = {};

    for (String empId in selectedEmployeeIds) {
      try {
        final skillsData = await apiService.fetchUserSkillsById(int.parse(empId), token, user);
        for (var skill in skillsData) {
          allSkills.add(skill);
        }
      } catch (e) {
        debugPrint('Error fetching skills for employee $empId: $e');
      }
    }

    setState(() {
      skills = allSkills.toList();
      isLoadingSkills = false;
    });

    // Fetch observer for the first selected employee
    if (selectedEmployeeIds.isNotEmpty) {
      await fetchObserver(int.parse(selectedEmployeeIds.first));
    }

    debugPrint('Available skills: ${skills.map((s) => s['skill_name']).toList()}');
  }

  void filterTasks(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredTasks = List.from(jobRoleTasks);
      } else {
        filteredTasks = jobRoleTasks
            .where(
              (task) => (task['task'] as String)
                  .toLowerCase()
                  .contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _onTabChanged() {
    // Auto-advance logic can be added here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isViewingTasks
          ? const Color(0xFFF7F8FC)
          : const Color(0xFFFAFAFA),
      appBar: _isViewingTasks
          ? null
          : AppBar(
              title: const Text(
                'Task Assignment',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              foregroundColor: const Color(0xFF1A1A1A),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF1A1A1A),
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      body: _isViewingTasks ? _buildAssignedTasksView() : Column(
        children: [
          // Progress Indicator
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: getResponsivePadding(context),
              vertical: getResponsivePadding(context) * 2 / 3,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildStepIndicator(context, 0, 'Filters', Icons.filter_list_alt),
                _buildStepConnector(context, 0),
                _buildStepIndicator(context, 1, 'Team', Icons.people),
                _buildStepConnector(context, 1),
                _buildStepIndicator(context, 2, 'Details', Icons.assignment),
                _buildStepConnector(context, 2),
                _buildStepIndicator(context, 3, 'Review', Icons.check_circle),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: const Color(0xFF6366F1),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'FILTERS'),
                Tab(text: 'ASSIGN'),
                Tab(text: 'CONFIGURE'),
                Tab(text: 'REVIEW'),
              ],
              onTap: (index) {
                _onTabChanged();
              },
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildFiltersTab(),
                _buildAssignTab(),
                _buildConfigureTab(),
                _buildReviewTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isViewingTasks ? null : _buildBottomNavigation(),
    );
  }

  Widget _buildStepIndicator(BuildContext context, int step, String label, IconData icon) {
    final bool isActive = _getCurrentStep() >= step;
    final bool isCompleted = _getCurrentStep() > step;
    final double indicatorSize = getResponsiveIconSize(context, 48.0);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: indicatorSize,
            height: indicatorSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : isActive
                      ? const Color(0xFF6366F1)
                      : Colors.grey.shade200,
              border: Border.all(
                color: isActive ? const Color(0xFF6366F1) : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted || isActive ? Colors.white : Colors.grey.shade500,
              size: getResponsiveIconSize(context, 20.0),
            ),
          ),
          SizedBox(height: getResponsiveMargin(context)),
          Text(
            label,
            style: TextStyle(
              fontSize: getResponsiveTextSize(context, 12.0),
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF6366F1) : Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(BuildContext context, int step) {
    final bool isActive = _getCurrentStep() > step;

    return Container(
      width: getResponsivePadding(context) * 4 / 3,
      height: 2,
      margin: EdgeInsets.symmetric(horizontal: getResponsiveMargin(context)),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6366F1) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  int _getCurrentStep() {
    if (selectedDepartment == null || selectedJobRole == null) return 0;
    if (selectedEmployeeIds.isEmpty) return 1;
    if (taskTitle.isEmpty || taskDescription.isEmpty) return 2;
    // Skills selection is optional, so we can proceed to review even without skills
    return 3;
  }

  Widget _buildAssignedTasksView() {
    final displayedTasks = _getDisplayedAssignedTasks();
    final horizontalPadding = getResponsivePadding(context);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              getResponsiveMargin(context),
              horizontalPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildHeaderIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    SizedBox(width: getResponsiveMargin(context)),
                    Expanded(
                      child: Text(
                        'My Tasks',
                        style: TextStyle(
                          fontSize: getResponsiveTextSize(context, 24.0),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F3270),
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    if ((Provider.of<AuthProvider>(context, listen: false).currentUser?.userProfileName ?? '').toLowerCase().contains('admin'))
                      _buildAssignTaskButton(),
                  ],
                ),
                SizedBox(height: getResponsivePadding(context) * 1.4),
                Text(
                  'Tasks Assigned to You',
                  style: TextStyle(
                    fontSize: getResponsiveTextSize(context, 30.0),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F3270),
                    letterSpacing: -0.9,
                  ),
                ),
                SizedBox(height: getResponsiveMargin(context)),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    'View and manage tasks assigned to you by your supervisors.',
                    style: TextStyle(
                      fontSize: getResponsiveTextSize(context, 16.0),
                      color: const Color(0xFF5E6C96),
                      height: 1.45,
                    ),
                  ),
                ),
                SizedBox(height: getResponsivePadding(context) * 1.1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTaskStatusFilterBar(),
                      SizedBox(width: getResponsiveMargin(context)),
                      _buildFilterActionButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: getResponsiveMargin(context)),
          Expanded(
            child: isLoadingAssignedTasks
                ? const Center(child: CircularProgressIndicator())
                : displayedTasks.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: _buildEmptyState(
                          icon: Icons.assignment_outlined,
                          title: assignedTasks.isEmpty
                              ? 'No Tasks Assigned'
                              : 'No Matching Tasks',
                          message: assignedTasks.isEmpty
                              ? 'You don\'t have any tasks assigned to you yet.'
                              : 'Try a different task status filter to see more items.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchAssignedTasks,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            horizontalPadding,
                          ),
                          itemCount: displayedTasks.length,
                          itemBuilder: (context, index) {
                            final task = displayedTasks[index];
                            return _buildTaskCard(task);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final statusColor = _getStatusColor(task.status);

    return Container(
      margin: EdgeInsets.only(bottom: getResponsiveMargin(context) * 1.2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F3270).withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailsScreen(task: task),
              ),
            );
          },
          borderRadius: BorderRadius.circular(26),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(26),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(getResponsivePadding(context)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _getStatusIcon(task.status),
                            color: statusColor,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: getResponsiveMargin(context)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.taskTitle,
                                      style: TextStyle(
                                        fontSize: getResponsiveTextSize(
                                          context,
                                          17.0,
                                        ),
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1F3270),
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatusBadge(task.status),
                                ],
                              ),
                              if (task.taskDescription != null &&
                                  task.taskDescription!.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  task.taskDescription!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF58678F),
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildTaskMetaPanel(task),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF42558F),
                                    size: 28,
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (_normalizeTaskStatus(status)) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  Color _getStatusColor(String status) {
    switch (_normalizeTaskStatus(status)) {
      case 'completed':
        return const Color(0xFF45D37B);
      case 'in_progress':
        return const Color(0xFF4B96FF);
      case 'pending':
      default:
        return const Color(0xFFFF7A1A);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (_normalizeTaskStatus(status)) {
      case 'completed':
        return Icons.check_rounded;
      case 'in_progress':
        return Icons.radio_button_unchecked_rounded;
      case 'pending':
      default:
        return Icons.access_time_rounded;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }

  String _normalizeTaskStatus(String status) {
    final normalized = status.trim().toLowerCase().replaceAll(' ', '_');
    if (normalized == 'inprogress') {
      return 'in_progress';
    }
    return normalized;
  }

  List<Task> _getDisplayedAssignedTasks() {
    final filtered = assignedTasks.where((task) {
      if (_selectedTaskStatusFilter == 'all') {
        return true;
      }
      return _normalizeTaskStatus(task.status) == _selectedTaskStatusFilter;
    }).toList();

    filtered.sort((a, b) {
      final firstDate = _parseTaskDate(a);
      final secondDate = _parseTaskDate(b);
      return _sortNewestFirst
          ? secondDate.compareTo(firstDate)
          : firstDate.compareTo(secondDate);
    });

    return filtered;
  }

  DateTime _parseTaskDate(Task task) {
    final rawDate = task.taskDate.isNotEmpty ? task.taskDate : task.createdAt;
    return DateTime.tryParse(rawDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _getTaskDisplayDate(Task task) {
    final rawDate = task.taskDate.isNotEmpty ? task.taskDate : task.createdAt;
    return _formatDate(rawDate);
  }

  String _getTaskPersonLabel(Task task) {
    final person = task.allocator?.trim();
    if (person != null && person.isNotEmpty) {
      return person;
    }

    final fallback = task.allocatedTo?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return 'Unassigned';
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1F3270).withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1F3270),
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildAssignTaskButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _isViewingTasks = false;
        });
        fetchDepartments();
      },
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF2E3E98),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E3E98).withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFFF3C56A),
              size: 26,
            ),
            SizedBox(width: 10),
            Text(
              'Assign Task',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatusFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F3270).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTaskFilterChip(
            value: 'all',
            label: 'All',
            icon: Icons.view_list_rounded,
          ),
          _buildTaskFilterChip(
            value: 'pending',
            label: 'Pending',
            icon: Icons.access_time_rounded,
          ),
          _buildTaskFilterChip(
            value: 'in_progress',
            label: 'In Progress',
            icon: Icons.radio_button_unchecked_rounded,
          ),
          _buildTaskFilterChip(
            value: 'completed',
            label: 'Completed',
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskFilterChip({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTaskStatusFilter == value;
    final iconColor = value == 'all'
        ? (isSelected ? Colors.white : const Color(0xFF31406F))
        : (isSelected ? Colors.white : _getStatusColor(value));

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTaskStatusFilter = value;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2E3E98)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: iconColor,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF31406F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskMetaPanel(Task task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          _buildTaskMetaItem(
            icon: Icons.person_outline_rounded,
            value: _getTaskPersonLabel(task),
          ),
          Container(
            width: 1,
            height: 18,
            color: const Color(0xFFD9DEEF),
          ),
          _buildTaskMetaItem(
            icon: Icons.calendar_today_outlined,
            value: _getTaskDisplayDate(task),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterActionButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _showTaskSortSheet,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1F3270).withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.filter_alt_outlined,
            color: Color(0xFF4B5D91),
            size: 28,
          ),
        ),
      ),
    );
  }

  Future<void> _showTaskSortSheet() async {
    final selectedOption = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort Tasks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F3270),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.arrow_downward_rounded,
                    color: _sortNewestFirst
                        ? const Color(0xFF2E3E98)
                        : const Color(0xFF7A86A8),
                  ),
                  title: const Text('Newest first'),
                  trailing: _sortNewestFirst
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF2E3E98),
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.arrow_upward_rounded,
                    color: !_sortNewestFirst
                        ? const Color(0xFF2E3E98)
                        : const Color(0xFF7A86A8),
                  ),
                  title: const Text('Oldest first'),
                  trailing: !_sortNewestFirst
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF2E3E98),
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedOption != null) {
      setState(() {
        _sortNewestFirst = selectedOption;
      });
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTaskMetaItem({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF5D6A90),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4D5D88),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   'Project Filters',
          //   style: TextStyle(
          //     fontSize: getResponsiveTextSize(context, 28.0),
          //     fontWeight: FontWeight.w700,
          //     color: const Color(0xFF1A1A1A),
          //     letterSpacing: -0.5,
          //   ),
          // ),
          SizedBox(height: getResponsiveMargin(context) / 2),
          Text(
            'Select the department and job role to define the task scope.',
            style: TextStyle(
              fontSize: getResponsiveTextSize(context, 16.0),
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          SizedBox(height: getResponsivePadding(context) * 4 / 3),

          // Department Selection
          _buildSectionCard(
            icon: Icons.business,
            title: 'Department',
            child: isLoadingDepartments
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    initialValue: selectedDepartment,
                    isExpanded: true,
                    decoration: _buildInputDecoration('Choose department'),
                    items: departments.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedDepartment = newValue;
                        selectedJobRole = null;
                        selectedJobRoleName = null;
                        employees = [];
                        selectedEmployeeIds = {};
                        taskTitle = '';
                        taskTitleController.clear();
                        filteredTasks = [];
                        if (newValue != null) {
                          fetchJobRoles(newValue);
                        }
                      });
                      updateSelectedSkills();
                    },
                  ),
          ),

          const SizedBox(height: 24),

          // Job Role Selection
          if (selectedDepartment != null)
            _buildSectionCard(
              icon: Icons.work,
              title: 'Job Role',
              child: isLoadingJobRoles
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      initialValue: selectedJobRole,
                      isExpanded: true,
                      decoration: _buildInputDecoration('Choose job role'),
                      items: jobRoles.map((Map<String, dynamic> role) {
                        return DropdownMenuItem<String>(
                          value: role['id'].toString(),
                          child: Text(
                            role['jobrole'].toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedJobRole = newValue;
                          selectedJobRoleName = newValue == null
                              ? null
                              : jobRoles.firstWhere(
                                  (role) => role['id'].toString() == newValue,
                                )['jobrole'] as String;
                          taskTitle = '';
                          taskTitleController.clear();
                          taskDescription = '';
                          taskDescriptionController.clear();
                          selectedRepeatDays = null;
                          selectedRepeatUntil = null;
                          selectedPriority = null;
                          filteredTasks = [];
                          if (newValue != null) {
                            fetchEmployees(newValue);
                          }
                        });
                      },
                    ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAssignTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Assignment',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select team members who will be responsible for this task.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          if (selectedJobRole == null)
            _buildEmptyState(
              icon: Icons.people_outline,
              title: 'No Job Role Selected',
              message: 'Please select a department and job role first.',
            )
          else if (isLoadingEmployees)
            const Center(child: CircularProgressIndicator())
          else if (employees.isEmpty)
            _buildEmptyState(
              icon: Icons.error_outline,
              title: 'No Team Members',
              message: 'No team members found for this job role.',
            )
          else
            _buildSectionCard(
              icon: Icons.people,
              title: 'Select Team Members',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: employees.map((employee) {
                      final nameSuffix = employee['name_suffix']?.toString() ?? '';
                      final firstName = employee['first_name']?.toString() ?? '';
                      final lastName = employee['last_name']?.toString() ?? '';
                      final fullName = '$nameSuffix $firstName $lastName'.trim();
                      final employeeId = employee['id'].toString();
                      final isSelected = selectedEmployeeIds.contains(employeeId);

                      return _buildSelectionChip(
                        label: fullName,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedEmployeeIds.remove(employeeId);
                            } else {
                              selectedEmployeeIds.add(employeeId);
                            }
                          });
                          updateSelectedSkills();
                        },
                      );
                    }).toList(),
                  ),
                  if (selectedEmployeeIds.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF10B981),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${selectedEmployeeIds.length} team member${selectedEmployeeIds.length == 1 ? '' : 's'} selected',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildConfigureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Configuration',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure the task details, schedule, and requirements.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          if (selectedJobRole == null)
            _buildEmptyState(
              icon: Icons.assignment,
              title: 'Configuration Unavailable',
              message: 'Please complete the previous steps first.',
            )
          else ...[
            // Task Title
            _buildSectionCard(
              icon: Icons.title,
              title: 'Task Title',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  isLoadingTasks
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            TextField(
                              controller: taskTitleController,
                              focusNode: taskTitleFocusNode,
                              decoration: _buildInputDecoration('Enter task title'),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1A1A1A),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  taskTitle = value;
                                });
                                filterTasks(value);
                              },
                            ),
                            if (filteredTasks.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Suggested Tasks',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ...filteredTasks.take(5).map((task) {
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            taskTitle = task['task'].toString();
                                            taskTitleController.text = task['task'].toString();
                                            filteredTasks = [];
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.task_alt,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  task['task'].toString(),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF1A1A1A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Task Description
            _buildSectionCard(
              icon: Icons.description,
              title: 'Task Description',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  TextField(
                    controller: taskDescriptionController,
                    maxLines: 4,
                    decoration: _buildInputDecoration('Enter detailed task description'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                    onChanged: (value) {
                      setState(() {
                        taskDescription = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Schedule Settings
            _buildSectionCard(
              icon: Icons.schedule,
              title: 'Schedule Settings',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedRepeatDays,
                          decoration: _buildInputDecoration('Repeat every'),
                          items: List.generate(10, (index) {
                            int days = index + 1;
                            return DropdownMenuItem<String>(
                              value: '$days days',
                              child: Text('$days days'),
                            );
                          }),
                          onChanged: (newValue) {
                            setState(() {
                              selectedRepeatDays = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Until date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          controller: TextEditingController(
                            text: selectedRepeatUntil != null
                                ? DateFormat('yyyy-MM-dd').format(selectedRepeatUntil!)
                                : '',
                          ),
                          onTap: () => _selectRepeatUntilDate(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Priority
            _buildSectionCard(
              icon: Icons.priority_high,
              title: 'Task Priority',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        _buildPriorityButton('Low', selectedPriority == 'Low'),
                        _buildPriorityButton('Medium', selectedPriority == 'Medium'),
                        _buildPriorityButton('High', selectedPriority == 'High'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Required Skills
            if (selectedEmployeeIds.isNotEmpty)
              _buildSectionCard(
                icon: Icons.build,
                title: 'Required Skills',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    isLoadingSkills
                        ? const Center(child: CircularProgressIndicator())
                        : skills.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.grey),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No skills available for selected team members.',
                                        style: TextStyle(color: Color(0xFF6B7280)),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Select the skills required for this task:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: skills.map((skill) {
                                      final skillName = skill['skill_name']?.toString() ?? '';
                                      final skillId = skill['id'].toString();
                                      final isSelected = selectedSkillIds.contains(skillId);
                                      return FilterChip(
                                        label: Text(
                                          skillName,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : const Color(0xFF374151),
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (bool selected) {
                                          setState(() {
                                            if (selected) {
                                              selectedSkillIds.add(skillId);
                                            } else {
                                              selectedSkillIds.remove(skillId);
                                            }
                                          });
                                        },
                                        selectedColor: const Color(0xFF8B5CF6),
                                        checkmarkColor: Colors.white,
                                        backgroundColor: Colors.grey.shade100,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  if (selectedSkillIds.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF8B5CF6),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${selectedSkillIds.length} skill${selectedSkillIds.length == 1 ? '' : 's'} selected',
                                            style: const TextStyle(
                                              color: Color(0xFF5B21B6),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review all task details before submission.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Task Summary
          _buildSectionCard(
            icon: Icons.assignment,
            title: 'Task Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSummaryItem('Department', selectedDepartment ?? 'Not selected'),
                _buildSummaryItem('Job Role', selectedJobRoleName ?? 'Not selected'),
                _buildSummaryItem('Task Title', taskTitle.isNotEmpty ? taskTitle : 'Not specified'),
                _buildSummaryItem('Priority', selectedPriority ?? 'Not set'),
                if (selectedRepeatDays != null)
                  _buildSummaryItem('Repeat Frequency', selectedRepeatDays!),
                if (selectedRepeatUntil != null)
                  _buildSummaryItem(
                    'Repeat Until',
                    DateFormat('MMM dd, yyyy').format(selectedRepeatUntil!),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Assigned Team
          if (selectedEmployeeIds.isNotEmpty)
            _buildSectionCard(
              icon: Icons.people,
              title: 'Assigned Team (${selectedEmployeeIds.length})',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedEmployeeIds.map((employeeId) {
                      final employee = employees.firstWhere(
                        (emp) => emp['id'].toString() == employeeId,
                      );
                      final nameSuffix = employee['name_suffix']?.toString() ?? '';
                      final firstName = employee['first_name']?.toString() ?? '';
                      final lastName = employee['last_name']?.toString() ?? '';
                      final fullName = '$nameSuffix $firstName $lastName'.trim();

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                        ),
                        child: Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Skills & Observer
          if (selectedEmployeeIds.isNotEmpty)
            _buildSectionCard(
              icon: Icons.settings,
              title: 'Skills & Supervision',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  if (skills.isNotEmpty) ...[
                    const Text(
                      'Required Skills',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selectedSkillIds.map((skillId) {
                        final skill = skills.firstWhere(
                          (s) => s['id'].toString() == skillId,
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            skill['skill_name']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (observer != null) ...[
                    const Text(
                      'Supervisor',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade200,
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF6B7280),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            observer!['name']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            if (isSelected) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String label, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedPriority = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? _getPriorityColor(label) : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: label == 'Low' ? const Radius.circular(10) : Radius.zero,
              right: label == 'High' ? const Radius.circular(10) : Radius.zero,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return const Color(0xFF10B981);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'High':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Show Previous button for all tabs except the first one
            if (_tabController.index > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _tabController.animateTo(_tabController.index - 1);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            if (_tabController.index > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (_tabController.index == _tabController.length - 1) {
                    // Last tab (Review) - submit the task
                    if (selectedEmployeeIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least one employee'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (taskTitle.isEmpty || taskDescription.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter task title and description'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final user = auth.currentUser;
                    if (user == null) return;

                    final apiService = ApiService();
                    await apiService.loadCookies();

                    final token = auth.originalToken ?? user.token;

                    String skillId = '';
                    String skillsName = '';
                    if (selectedSkillIds.isNotEmpty) {
                      // Collect all selected skills
                      final selectedSkills = skills.where(
                        (s) => selectedSkillIds.contains(s['id'].toString()),
                      ).toList();

                      // Create comma-separated strings for skill IDs and names
                      skillId = selectedSkills.map((s) => s['id'].toString()).join(',');
                      skillsName = selectedSkills.map((s) => s['skill_name']?.toString() ?? '').join(',');
                    }

                    final repeatDays = selectedRepeatDays != null ? int.parse(selectedRepeatDays!.split(' ')[0]) : 1;
                    final repeatUntil = selectedRepeatUntil != null ? DateFormat('yyyy-MM-dd').format(selectedRepeatUntil!) : '';

                    // For each selected employee, assign the task
                    for (String employeeId in selectedEmployeeIds) {
                      try {
                        await apiService.assignTask(
                          user: user,
                          token: token,
                          taskTitle: taskTitle,
                          taskDescription: taskDescription,
                          taskAllocatedTo: employeeId,
                          skillId: skillId,
                          skills: skillsName,
                          manageBy: user.id.toString(),
                          observationPoint: 'KRA', // hardcoded as per payload
                          kpa: '', // not defined in screen
                          selType: selectedPriority ?? 'Medium',
                          repeatDays: repeatDays,
                          repeatUntil: repeatUntil,
                        );

                        // Send push notification to the assigned employee
                        // Note: In production, this should be handled by the backend server
                        // The backend should send FCM notification to the assignee's device
                        // Currently only logging for backend integration
                        await NotificationService().sendPushNotification(
                          token: '', // Backend should retrieve assignee's FCM token
                          title: 'New Task Assigned',
                          body: 'You have been assigned: $taskTitle',
                          data: {
                            'type': 'task_assigned',
                            'task_title': taskTitle,
                            'assigned_by': user.fullName,
                            'employee_id': employeeId,
                          },
                        );

                      } catch (e) {
                        debugPrint('Error assigning task to employee $employeeId: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to assign task to employee: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return; // Stop on first error
                      }
                    }

                    // Show in-app notification for the assigner
                    final flushbar = Flushbar(
                      title: '✅ Task Assigned Successfully!',
                      message: 'Task "$taskTitle" has been assigned to ${selectedEmployeeIds.length} team member${selectedEmployeeIds.length == 1 ? '' : 's'}.',
                      duration: const Duration(seconds: 3),
                      backgroundColor: Colors.green.shade600,
                      flushbarPosition: FlushbarPosition.TOP,
                      icon: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                      ),
                    )..show(context);

                    debugPrint('🎉 Task assigned! Notification displayed to user.');

                    // Switch back to viewing tasks and refresh the list
                    setState(() {
                      _isViewingTasks = true;
                      _tabController.index = 0; // Reset to first tab
                      // Reset all form data
                      selectedDepartment = null;
                      selectedJobRole = null;
                      selectedJobRoleName = null;
                      employees = [];
                      selectedEmployeeIds = {};
                      taskTitle = '';
                      taskTitleController.clear();
                      taskDescription = '';
                      taskDescriptionController.clear();
                      selectedRepeatDays = null;
                      selectedRepeatUntil = null;
                      selectedPriority = null;
                      filteredTasks = [];
                      skills = [];
                      selectedSkillIds = {};
                    });
                    fetchAssignedTasks();
                  } else {
                    // Other tabs - continue to next tab
                    _tabController.animateTo(_tabController.index + 1);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _tabController.index == _tabController.length - 1 ? 'Assign Task' : 'Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
