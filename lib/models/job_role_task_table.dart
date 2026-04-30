class JobRoleTaskTable {
  final int id;
  final String sector;
  final String track;
  final String jobrole;
  final String criticalWorkFunction;
  final String task;
  final String taskType;
  final int subInstituteId;
  final int? createdBy;
  final int? updatedBy;
  final int? deletedBy;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? taskCategory;

  JobRoleTaskTable({
    required this.id,
    required this.sector,
    required this.track,
    required this.jobrole,
    required this.criticalWorkFunction,
    required this.task,
    required this.taskType,
    required this.subInstituteId,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.taskCategory,
  });

  factory JobRoleTaskTable.fromJson(Map<String, dynamic> json) {
    return JobRoleTaskTable(
      id: json['id'] ?? 0,
      sector: json['sector'] ?? '',
      track: json['track'] ?? '',
      jobrole: json['jobrole'] ?? '',
      criticalWorkFunction: json['critical_work_function'] ?? '',
      task: json['task'] ?? '',
      taskType: json['task_type'] ?? '',
      subInstituteId: json['sub_institute_id'] ?? 0,
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      deletedBy: json['deleted_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      taskCategory: json['task_category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sector': sector,
      'track': track,
      'jobrole': jobrole,
      'critical_work_function': criticalWorkFunction,
      'task': task,
      'task_type': taskType,
      'sub_institute_id': subInstituteId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'deleted_by': deletedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'task_category': taskCategory,
    };
  }
}