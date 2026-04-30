class JobRoleSkill {
  final int id;
  final String sector;
  final String track;
  final String jobrole;
  final String skill;
  final String type;
  final String proficiencyLevel;
  final String proficiencyDescription;
  final String skillCode;
  final int subInstituteId;
  final int createdBy;
  final int? updatedBy;
  final int? deletedBy;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? userJobrole;
  final int skillId;
  final String category;
  final String subCategory;
  final String skillTitle;
  final String skillDescription;
  final String jobroleDescription;
  final int departmentId;
  final String firstName;
  final String middleName;
  final String lastName;

  JobRoleSkill({
    required this.id,
    required this.sector,
    required this.track,
    required this.jobrole,
    required this.skill,
    required this.type,
    required this.proficiencyLevel,
    required this.proficiencyDescription,
    required this.skillCode,
    required this.subInstituteId,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.userJobrole,
    required this.skillId,
    required this.category,
    required this.subCategory,
    required this.skillTitle,
    required this.skillDescription,
    required this.jobroleDescription,
    required this.departmentId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
  });

  factory JobRoleSkill.fromJson(Map<String, dynamic> json) {
    return JobRoleSkill(
      id: json['id'] ?? 0,
      sector: json['sector'] ?? '',
      track: json['track'] ?? '',
      jobrole: json['jobrole'] ?? '',
      skill: json['skill'] ?? '',
      type: json['type'] ?? '',
      proficiencyLevel: json['proficiency_level'] ?? '',
      proficiencyDescription: json['proficiency_description'] ?? '',
      skillCode: json['skill_code'] ?? '',
      subInstituteId: json['sub_institute_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      updatedBy: json['updated_by'],
      deletedBy: json['deleted_by'],
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      userJobrole: json['user_jobrole'],
      skillId: json['skill_id'] ?? 0,
      category: json['category'] ?? '',
      subCategory: json['sub_category'] ?? '',
      skillTitle: json['skillTitle'] ?? '',
      skillDescription: json['skillDescription'] ?? '',
      jobroleDescription: json['jobroleDescription'] ?? '',
      departmentId: json['department_id'] ?? 0,
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }
}