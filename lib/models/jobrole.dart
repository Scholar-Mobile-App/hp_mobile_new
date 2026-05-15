class JobRole {
  final int id;
  final String industries;
  final String department;
  final String subDepartment;
  final int departmentId;
  final String jobrole;
  final String? description;
  final String? jobLevel;
  final int? sequenceOrder;
  final int? hasVerticalProgression;
  final int? hasLateralMovement;
  final String? progressionType;
  final String? jobroleCategory;
  final String? performanceExpectation;
  final String status;
  final String? relatedJobrole;
  final String? requiredSkillExperience;
  final String? location;
  final String? salaryRange;
  final String? companyInformation;
  final String? responsibilities;
  final String? benefits;
  final String? keywordTags;
  final String? jobPostingDate;
  final String? applicationDeadline;
  final String? contactInformation;
  final String? internalTracking;
  final String? education;
  final String? experience;
  final String? training;
  final int subInstituteId;
  final int createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  JobRole({
    required this.id,
    required this.industries,
    required this.department,
    required this.subDepartment,
    required this.departmentId,
    required this.jobrole,
    this.description,
    this.jobLevel,
    this.sequenceOrder,
    this.hasVerticalProgression,
    this.hasLateralMovement,
    this.progressionType,
    this.jobroleCategory,
    this.performanceExpectation,
    required this.status,
    this.relatedJobrole,
    this.requiredSkillExperience,
    this.location,
    this.salaryRange,
    this.companyInformation,
    this.responsibilities,
    this.benefits,
    this.keywordTags,
    this.jobPostingDate,
    this.applicationDeadline,
    this.contactInformation,
    this.internalTracking,
    this.education,
    this.experience,
    this.training,
    required this.subInstituteId,
    required this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory JobRole.fromJson(Map<String, dynamic> json) {
    return JobRole(
      id: json['id'] as int? ?? 0,
      industries: json['industries']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      subDepartment: json['sub_department']?.toString() ?? '',
      departmentId: json['department_id'] as int? ?? 0,
      jobrole: json['jobrole']?.toString() ?? '',
      description: json['description'] as String?,
      jobLevel: json['job_level'] as String?,
      sequenceOrder: json['sequence_order'] as int?,
      hasVerticalProgression: json['has_vertical_progression'] as int?,
      hasLateralMovement: json['has_lateral_movement'] as int?,
      progressionType: json['progression_type'] as String?,
      jobroleCategory: json['jobrole_category'] as String?,
      performanceExpectation: json['performance_expectation'] as String?,
      status: json['status']?.toString() ?? '',
      relatedJobrole: json['related_jobrole'] as String?,
      requiredSkillExperience: json['required_skill_experience'] as String?,
      location: json['location'] as String?,
      salaryRange: json['salary_range'] as String?,
      companyInformation: json['company_information'] as String?,
      responsibilities: json['responsibilities'] as String?,
      benefits: json['benefits'] as String?,
      keywordTags: json['keyword_tags'] as String?,
      jobPostingDate: json['job_posting_date'] as String?,
      applicationDeadline: json['application_deadline'] as String?,
      contactInformation: json['contact_information'] as String?,
      internalTracking: json['internal_tracking'] as String?,
      education: json['education'] as String?,
      experience: json['experience'] as String?,
      training: json['training'] as String?,
      subInstituteId: json['sub_institute_id'] as int? ?? 0,
      createdBy: json['created_by'] as int? ?? 0,
      updatedBy: json['updated_by'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      deletedAt: json['deleted_at'] as String?,
    );
  }
}