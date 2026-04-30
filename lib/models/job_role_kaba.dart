class RatingLevel {
  final String level;
  final String descriptor;
  final String indicators;

  RatingLevel({
    required this.level,
    required this.descriptor,
    required this.indicators,
  });

  factory RatingLevel.fromJson(Map<String, dynamic> json) {
    return RatingLevel(
      level: json['level'] ?? '',
      descriptor: json['descriptor'] ?? '',
      indicators: json['indicators'] ?? '',
    );
  }
}

class KABAItem {
  final int id;
  final String category;
  final String subCategory;
  final String title;
  final String description;
  final String proficiencyLevel;
  final List<RatingLevel> ratingLevels;

  KABAItem({
    required this.id,
    required this.category,
    required this.subCategory,
    required this.title,
    required this.description,
    required this.proficiencyLevel,
    required this.ratingLevels,
  });

  factory KABAItem.fromJson(Map<String, dynamic> json) {
    return KABAItem(
      id: json['id'] ?? 0,
      category: json['category'] ?? '',
      subCategory: json['sub_category'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      proficiencyLevel: json['proficiency_level'] ?? '',
      ratingLevels: (json['rating_levels'] as List<dynamic>?)
          ?.map((level) => RatingLevel.fromJson(level))
          .toList() ?? [],
    );
  }
}

class JobRoleKABA {
  final String type;
  final int typeId;
  final String title;
  final String description;
  final List<KABAItem> skill;
  final List<KABAItem> knowledge;
  final List<KABAItem> ability;
  final List<KABAItem> attitude;
  final List<KABAItem> behaviour;

  JobRoleKABA({
    required this.type,
    required this.typeId,
    required this.title,
    required this.description,
    required this.skill,
    required this.knowledge,
    required this.ability,
    required this.attitude,
    required this.behaviour,
  });

  factory JobRoleKABA.fromJson(Map<String, dynamic> json) {
    return JobRoleKABA(
      type: json['type'] ?? '',
      typeId: json['type_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      skill: (json['skill'] as List<dynamic>?)
          ?.map((item) => KABAItem.fromJson(item))
          .toList() ?? [],
      knowledge: (json['knowledge'] as List<dynamic>?)
          ?.map((item) => KABAItem.fromJson(item))
          .toList() ?? [],
      ability: (json['ability'] as List<dynamic>?)
          ?.map((item) => KABAItem.fromJson(item))
          .toList() ?? [],
      attitude: (json['attitude'] as List<dynamic>?)
          ?.map((item) => KABAItem.fromJson(item))
          .toList() ?? [],
      behaviour: (json['behaviour'] as List<dynamic>?)
          ?.map((item) => KABAItem.fromJson(item))
          .toList() ?? [],
    );
  }
}