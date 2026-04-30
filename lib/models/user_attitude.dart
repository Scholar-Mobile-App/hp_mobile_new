class UserAttitude {
  final int id;
  final String? category;
  final String? subCategory;
  final String? title;
  final String? description;
  final String? businessLink;
  final String? assessmentMethod;
  final String? attitudeTags;
  final String? developmentMethods;
  final String? negativeIndicators;
  final String? improvementStrategies;
  final String? culturalAlignment;
  final int subInstituteId;
  final int? createdBy;
  final int? updatedBy;
  final int? deletedBy;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  UserAttitude({
    required this.id,
    this.category,
    this.subCategory,
    this.title,
    this.description,
    this.businessLink,
    this.assessmentMethod,
    this.attitudeTags,
    this.developmentMethods,
    this.negativeIndicators,
    this.improvementStrategies,
    this.culturalAlignment,
    required this.subInstituteId,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory UserAttitude.fromJson(Map<String, dynamic> json) {
    return UserAttitude(
      id: json['id'] ?? 0,
      category: json['category']?.toString(),
      subCategory: json['sub_category']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      businessLink: json['business_link']?.toString(),
      assessmentMethod: json['assessment_method']?.toString(),
      attitudeTags: json['attitude_tags']?.toString(),
      developmentMethods: json['development_methods']?.toString(),
      negativeIndicators: json['negative_indicators']?.toString(),
      improvementStrategies: json['improvement_strategies']?.toString(),
      culturalAlignment: json['cultural_alignment']?.toString(),
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
      'attitude_tags': attitudeTags,
      'development_methods': developmentMethods,
      'negative_indicators': negativeIndicators,
      'improvement_strategies': improvementStrategies,
      'cultural_alignment': culturalAlignment,
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