class Task {
  final int id;
  final String taskTitle;
  final String? taskDescription;
  final String? taskAttachment;
  final String? fileSize;
  final String? fileType;
  final String taskDate;
  final String repeatDays;
  final String? kra;
  final String? kpa;
  final String taskType;
  final String status;
  final String? taskcompletationRemarks;
  final int taskAllocated;
  final int taskAllocatedTo;
  final String? requiredSkills;
  final String? skillId;
  final String? observationPoint;
  final String createdIpAddress;
  final String syear;
  final int subInstituteId;
  final String? approvedBy;
  final String? approvedOn;
  final String? approveStatus;
  final String? approveRemarks;
  final String? reply;
  final int createdBy;
  final int? updatedBy;
  final int? deletedBy;
  final String createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final int userId;
  final String? manageby;
  final String? allocator;
  final String? allocatedTo;
  final String? department;
  final String? jobrole;

  Task({
    required this.id,
    required this.taskTitle,
    this.taskDescription,
    this.taskAttachment,
    this.fileSize,
    this.fileType,
    required this.taskDate,
    required this.repeatDays,
    this.kra,
    this.kpa,
    required this.taskType,
    required this.status,
    this.taskcompletationRemarks,
    required this.taskAllocated,
    required this.taskAllocatedTo,
    this.requiredSkills,
    this.skillId,
    this.observationPoint,
    required this.createdIpAddress,
    required this.syear,
    required this.subInstituteId,
    this.approvedBy,
    this.approvedOn,
    this.approveStatus,
    this.approveRemarks,
    this.reply,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.userId,
    this.manageby,
    this.allocator,
    this.allocatedTo,
    this.department,
    this.jobrole,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      taskTitle: json['task_title'] as String? ?? '',
      taskDescription: json['task_description'] as String?,
      taskAttachment: json['task_attachment'] as String?,
      fileSize: json['file_size'] as String?,
      fileType: json['file_type'] as String?,
      taskDate: json['task_date'] as String? ?? '',
      repeatDays: json['repeat_days'] as String? ?? '',
      kra: json['kra'] as String?,
      kpa: json['kpa'] as String?,
      taskType: json['task_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      taskcompletationRemarks: json['taskcompletation_remarks'] as String?,
      taskAllocated: (json['task_allocated'] as int?) ?? 0,
      taskAllocatedTo: (json['task_allocated_to'] as int?) ?? 0,
      requiredSkills: json['required_skills'] as String?,
      skillId: json['skill_id'] as String?,
      observationPoint: json['observation_point'] as String?,
      createdIpAddress: json['CREATED_IP_ADDRESS'] as String? ?? '',
      syear: json['SYEAR'] as String? ?? '',
      subInstituteId: (json['sub_institute_id'] as int?) ?? 0,
      approvedBy: json['approved_by'] as String?,
      approvedOn: json['approved_on'] as String?,
      approveStatus: json['approve_status'] as String?,
      approveRemarks: json['approve_remarks'] as String?,
      reply: json['reply'] as String?,
      createdBy: (json['created_by'] as int?) ?? 0,
      updatedBy: json['updated_by'] as int?,
      deletedBy: json['deleted_by'] as int?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
      deletedAt: json['deleted_at'] as String?,
      userId: (json['user_id'] as int?) ?? 0,
      manageby: json['manageby'] as String?,
      allocator: json['ALLOCATOR'] as String?,
      allocatedTo: json['ALLOCATED_TO'] as String?,
      department: json['department'] as String?,
      jobrole: json['jobrole'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_title': taskTitle,
      'task_description': taskDescription,
      'task_attachment': taskAttachment,
      'file_size': fileSize,
      'file_type': fileType,
      'task_date': taskDate,
      'repeat_days': repeatDays,
      'kra': kra,
      'kpa': kpa,
      'task_type': taskType,
      'status': status,
      'taskcompletation_remarks': taskcompletationRemarks,
      'task_allocated': taskAllocated,
      'task_allocated_to': taskAllocatedTo,
      'required_skills': requiredSkills,
      'skill_id': skillId,
      'observation_point': observationPoint,
      'CREATED_IP_ADDRESS': createdIpAddress,
      'SYEAR': syear,
      'sub_institute_id': subInstituteId,
      'approved_by': approvedBy,
      'approved_on': approvedOn,
      'approve_status': approveStatus,
      'approve_remarks': approveRemarks,
      'reply': reply,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'deleted_by': deletedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'user_id': userId,
      'manageby': manageby,
      'ALLOCATOR': allocator,
      'ALLOCATED_TO': allocatedTo,
      'department': department,
      'jobrole': jobrole,
    };
  }
}