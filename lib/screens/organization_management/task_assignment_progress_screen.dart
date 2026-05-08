import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/auth_provider.dart';
import '../../services/api_service.dart';

class TaskAssignmentProgressScreen extends StatefulWidget {
  const TaskAssignmentProgressScreen({super.key});

  @override
  State<TaskAssignmentProgressScreen> createState() =>
      _TaskAssignmentProgressScreenState();
}

class _TaskAssignmentProgressScreenState
    extends State<TaskAssignmentProgressScreen> {
  String? selectedDepartment;
  String? selectedJobRole;
  String? selectedJobRoleName;
  String? selectedRepeatDays;
  DateTime? selectedRepeatUntil;

  List<String> departments = [];
  List<Map<String, dynamic>> jobRoles = [];
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> jobRoleTasks = [];
  List<Map<String, dynamic>> filteredTasks = [];
  Set<String> selectedEmployeeIds = {};
  String taskTitle = '';
  String taskDescription = '';
  final TextEditingController taskTitleController = TextEditingController();
  final TextEditingController taskDescriptionController = TextEditingController();
  final FocusNode taskTitleFocusNode = FocusNode();
  bool isLoadingDepartments = true;
  bool isLoadingJobRoles = false;
  bool isLoadingEmployees = false;
  bool isLoadingTasks = false;

  @override
  void initState() {
    super.initState();
    fetchDepartments();
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

  @override
  void dispose() {
    taskTitleController.dispose();
    taskDescriptionController.dispose();
    taskTitleFocusNode.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Task Assignment & Progress',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1F2A6D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2A6D),
                ),
              ),
              const SizedBox(height: 20),
              isLoadingDepartments
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: selectedDepartment,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Department',
                        border: OutlineInputBorder(),
                      ),
                      items: departments.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            overflow: TextOverflow.ellipsis,
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
                      },
                    ),
              const SizedBox(height: 20),
              selectedDepartment == null
                  ? const SizedBox.shrink()
                  : isLoadingJobRoles
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                          value: selectedJobRole,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Job Role',
                            border: OutlineInputBorder(),
                          ),
                          items: jobRoles.map((Map<String, dynamic> role) {
                            return DropdownMenuItem<String>(
                              value: role['id'].toString(),
                              child: Text(
                                role['jobrole'].toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedJobRole = newValue;
                               selectedJobRoleName = newValue == null
                                   ? null
                                   : jobRoles.firstWhere(
                                       (role) =>
                                           role['id'].toString() == newValue,
                                     )['jobrole'] as String;
                               taskTitle = '';
                               taskTitleController.clear();
                               taskDescription = '';
                               taskDescriptionController.clear();
                               selectedRepeatDays = null;
                               selectedRepeatUntil = null;
                               filteredTasks = [];
                              if (newValue != null) {
                                fetchEmployees(newValue);
                              }
                            });
                          },
                        ),
              const SizedBox(height: 20),
              const Text(
                'Assign To',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2A6D),
                ),
              ),
              const SizedBox(height: 10),
              selectedJobRole == null
                  ? const Text(
                      'Please select a job role first.',
                      style: TextStyle(color: Colors.grey),
                    )
                  : isLoadingEmployees
                      ? const Center(child: CircularProgressIndicator())
                      : employees.isEmpty
                          ? const Text(
                              'No employees found for this job role.',
                              style: TextStyle(color: Colors.grey),
                            )
                          : SizedBox(
                              height: 200,
                              child: ListView(
                                children: employees.map((employee) {
                                  final nameSuffix =
                                      employee['name_suffix']?.toString() ?? '';
                                  final firstName =
                                      employee['first_name']?.toString() ?? '';
                                  final lastName =
                                      employee['last_name']?.toString() ?? '';
                                  final fullName =
                                      '$nameSuffix $firstName $lastName'
                                          .trim();
                                  final employeeId =
                                      employee['id'].toString();
                                  return CheckboxListTile(
                                    title: Text(fullName),
                                    value: selectedEmployeeIds
                                        .contains(employeeId),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedEmployeeIds.add(employeeId);
                                        } else {
                                          selectedEmployeeIds.remove(employeeId);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
              const SizedBox(height: 20),
              if (selectedEmployeeIds.isNotEmpty)
                Text(
                  'Assigned to ${selectedEmployeeIds.length} employee(s)',
                  style: const TextStyle(fontSize: 16, color: Colors.green),
                ),
              const SizedBox(height: 20),
              const Text(
                'Task Title',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2A6D),
                ),
              ),
              const SizedBox(height: 10),
              selectedJobRole == null
                  ? const Text(
                      'Please select a job role first.',
                      style: TextStyle(color: Colors.grey),
                    )
                  : isLoadingTasks
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            TextField(
                              controller: taskTitleController,
                              focusNode: taskTitleFocusNode,
                              decoration: const InputDecoration(
                                labelText: 'Enter Task Title',
                                border: OutlineInputBorder(),
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
                                height: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ListView.builder(
                                  itemCount: filteredTasks.length,
                                  itemBuilder: (context, index) {
                                    final task = filteredTasks[index];
                                    return ListTile(
                                      title: Text(task['task'].toString()),
                                       onTap: () {
                                         setState(() {
                                           taskTitle = task['task'].toString();
                                           taskTitleController.text =
                                               task['task'].toString();
                                           filteredTasks = [];
                                         });
                                       },
                                    );
                                  },
                                ),
                              ),
                           ],
                         ),
              const SizedBox(height: 20),
              const Text(
                'Task Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2A6D),
                ),
              ),
              const SizedBox(height: 10),
              selectedJobRole == null
                  ? const Text(
                      'Please select a job role first.',
                      style: TextStyle(color: Colors.grey),
                    )
                  : TextField(
                      controller: taskDescriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Enter Task Description',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          taskDescription = value;
                        });
                      },
                    ),
              const SizedBox(height: 20),
              const Text(
                'Repeat Once in Every',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2A6D),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRepeatDays,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Repeat Interval',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 20),
              const Text(
                'Repeat Until',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2A6D),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Select Repeat Until Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: selectedRepeatUntil != null
                      ? DateFormat('yyyy-MM-dd').format(selectedRepeatUntil!)
                      : '',
                ),
                onTap: () => _selectRepeatUntilDate(context),
              ),
              const SizedBox(height: 40),
              if (selectedDepartment != null && selectedJobRole != null)
                Text(
                  'Selected: Department - $selectedDepartment, Job Role - $selectedJobRoleName${selectedRepeatDays != null ? ', Repeat: $selectedRepeatDays' : ''}${selectedRepeatUntil != null ? ', Until: ${DateFormat('yyyy-MM-dd').format(selectedRepeatUntil!)}' : ''}',
                  style: const TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
