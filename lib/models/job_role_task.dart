class JobRoleTask {
  final int id;
  final String sector;
  final String track;
  final String jobrole;
  final String criticalWorkFunction;
  final String task;
  final String taskType;
  final int subInstituteId;
  final int createdBy;
  final int? updatedBy;
  final int? deletedBy;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? taskCategory;
  final int? userJobrole;
  final String firstName;
  final String middleName;
  final String lastName;

  JobRoleTask({
    required this.id,
    required this.sector,
    required this.track,
    required this.jobrole,
    required this.criticalWorkFunction,
    required this.task,
    required this.taskType,
    required this.subInstituteId,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.taskCategory,
    this.userJobrole,
    required this.firstName,
    required this.middleName,
    required this.lastName,
  });

  factory JobRoleTask.fromJson(Map<String, dynamic> json) {
    return JobRoleTask(
      id: json['id'] ?? 0,
      sector: json['sector'] ?? '',
      track: json['track'] ?? '',
      jobrole: json['jobrole'] ?? '',
      criticalWorkFunction: json['critical_work_function'] ?? '',
      task: json['task'] ?? '',
      taskType: json['task_type'] ?? '',
      subInstituteId: json['sub_institute_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      updatedBy: json['updated_by'],
      deletedBy: json['deleted_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      taskCategory: json['task_category'],
      userJobrole: json['user_jobrole'],
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }
}