class UserAbility {
  final int id;
  final String? category;
  final String? subCategory;
  final String? title;
  final String? description;
  final String? businessLink;
  final String? assessmentMethod;
  final String? abilityTags;
  final String? cognitiveElements;
  final String? psychomotorElements;
  final String? measurementMetrics;
  final String? importanceLevel;
  final String? commonChallenges;
  final String? improvementTips;
  final int subInstituteId;
  final int? createdBy;
  final int? updatedBy;
  final int? deletedBy;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  UserAbility({
    required this.id,
    this.category,
    this.subCategory,
    this.title,
    this.description,
    this.businessLink,
    this.assessmentMethod,
    this.abilityTags,
    this.cognitiveElements,
    this.psychomotorElements,
    this.measurementMetrics,
    this.importanceLevel,
    this.commonChallenges,
    this.improvementTips,
    required this.subInstituteId,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory UserAbility.fromJson(Map<String, dynamic> json) {
    return UserAbility(
      id: json['id'] ?? 0,
      category: json['category']?.toString(),
      subCategory: json['sub_category']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      businessLink: json['business_link']?.toString(),
      assessmentMethod: json['assessment_method']?.toString(),
      abilityTags: json['ability_tags']?.toString(),
      cognitiveElements: json['cognitive_elements']?.toString(),
      psychomotorElements: json['psychomotor_elements']?.toString(),
      measurementMetrics: json['measurement_metrics']?.toString(),
      importanceLevel: json['importance_level']?.toString(),
      commonChallenges: json['common_challenges']?.toString(),
      improvementTips: json['improvement_tips']?.toString(),
      subInstituteId: json['sub_institute_id'] ?? 0,
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      deletedBy: json['deleted_by'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'sub_category': subCategory,
      'title': title,
      'description': description,
      'business_link': businessLink,
      'assessment_method': assessmentMethod,
      'ability_tags': abilityTags,
      'cognitive_elements': cognitiveElements,
      'psychomotor_elements': psychomotorElements,
      'measurement_metrics': measurementMetrics,
      'importance_level': importanceLevel,
      'common_challenges': commonChallenges,
      'improvement_tips': improvementTips,
      'sub_institute_id': subInstituteId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'deleted_by': deletedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }
}