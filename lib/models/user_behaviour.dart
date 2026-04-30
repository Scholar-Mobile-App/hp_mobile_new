class UserBehaviour {
  final int id;
  final String? category;
  final String? subCategory;
  final String? title;
  final String? description;
  final String? businessLink;
  final String? assessmentMethod;
  final String? behaviourTags;
  final String? measurableIndicators;
  final String? behaviourAlternatives;
  final String? performanceMetrics;
  final String? riskImplications;
  final String? coachingGuidelines;
  final int subInstituteId;
  final int? createdBy;
  final int? updatedBy;
  final int? deletedBy;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  UserBehaviour({
    required this.id,
    this.category,
    this.subCategory,
    this.title,
    this.description,
    this.businessLink,
    this.assessmentMethod,
    this.behaviourTags,
    this.measurableIndicators,
    this.behaviourAlternatives,
    this.performanceMetrics,
    this.riskImplications,
    this.coachingGuidelines,
    required this.subInstituteId,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory UserBehaviour.fromJson(Map<String, dynamic> json) {
    return UserBehaviour(
      id: json['id'] ?? 0,
      category: json['category']?.toString(),
      subCategory: json['sub_category']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      businessLink: json['business_link']?.toString(),
      assessmentMethod: json['assessment_method']?.toString(),
      behaviourTags: json['behaviour_tags']?.toString(),
      measurableIndicators: json['measurable_indicators']?.toString(),
      behaviourAlternatives: json['behaviour_alternatives']?.toString(),
      performanceMetrics: json['performance_metrics']?.toString(),
      riskImplications: json['risk_implications']?.toString(),
      coachingGuidelines: json['coaching_guidelines']?.toString(),
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
      'behaviour_tags': behaviourTags,
      'measurable_indicators': measurableIndicators,
      'behaviour_alternatives': behaviourAlternatives,
      'performance_metrics': performanceMetrics,
      'risk_implications': riskImplications,
      'coaching_guidelines': coachingGuidelines,
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