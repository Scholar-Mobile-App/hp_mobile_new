class UserKnowledge {
  final int id;
  final String? category;
  final String? subCategory;
  final String? title;
  final String? description;
  final String? businessLink;
  final String? assessmentMethod;
  final String? knowledgeTags;
  final String? keyConcepts;
  final String? theoreticalFoundation;
  final String? complexityLevel;
  final String? proficiencyExpectation;
  final String? references;
  final String? certificationOptions;
  final String? complianceRelevance;
  final int subInstituteId;
  final int? createdBy;
  final int? updatedBy;
  final int? deletedBy;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  UserKnowledge({
    required this.id,
    this.category,
    this.subCategory,
    this.title,
    this.description,
    this.businessLink,
    this.assessmentMethod,
    this.knowledgeTags,
    this.keyConcepts,
    this.theoreticalFoundation,
    this.complexityLevel,
    this.proficiencyExpectation,
    this.references,
    this.certificationOptions,
    this.complianceRelevance,
    required this.subInstituteId,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory UserKnowledge.fromJson(Map<String, dynamic> json) {
    return UserKnowledge(
      id: json['id'] ?? 0,
      category: json['category']?.toString(),
      subCategory: json['sub_category']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      businessLink: json['business_link']?.toString(),
      assessmentMethod: json['assessment_method']?.toString(),
      knowledgeTags: json['knowledge_tags']?.toString(),
      keyConcepts: json['key_concepts']?.toString(),
      theoreticalFoundation: json['theoretical_foundation']?.toString(),
      complexityLevel: json['complexity_level']?.toString(),
      proficiencyExpectation: json['proficiency_expectation']?.toString(),
      references: json['references']?.toString(),
      certificationOptions: json['certification_options']?.toString(),
      complianceRelevance: json['compliance_relevance']?.toString(),
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
      'knowledge_tags': knowledgeTags,
      'key_concepts': keyConcepts,
      'theoretical_foundation': theoreticalFoundation,
      'complexity_level': complexityLevel,
      'proficiency_expectation': proficiencyExpectation,
      'references': references,
      'certification_options': certificationOptions,
      'compliance_relevance': complianceRelevance,
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