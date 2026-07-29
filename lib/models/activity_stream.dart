class ActivityStreamItem {
  final int id;
  final String title;
  final String priority;
  final String date;
  final String status;
  final String? approvalStatus;
  final String allocatedUser;
  final String allocatedBy;
  final String imageUrl;
  final bool isCompliance;

  const ActivityStreamItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.date,
    required this.status,
    required this.approvalStatus,
    required this.allocatedUser,
    required this.allocatedBy,
    required this.imageUrl,
    this.isCompliance = false,
  });

  factory ActivityStreamItem.fromJson(
    Map<String, dynamic> json, {
    bool isCompliance = false,
  }) {
    return ActivityStreamItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: (json['task_title'] ??
              json['compliance_title'] ??
              json['title'] ??
              'Untitled activity')
          .toString(),
      priority: (json['task_type'] ?? json['priority'] ?? '').toString(),
      date: (json['task_date'] ??
              json['compliance_date'] ??
              json['date'] ??
              json['created_at'] ??
              '')
          .toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      approvalStatus: json['approve_status']?.toString(),
      allocatedUser:
          (json['allocatedUser'] ?? json['allocated_user'] ?? '').toString(),
      allocatedBy:
          (json['allocatedBy'] ?? json['allocated_by'] ?? '').toString(),
      imageUrl: (json['image'] ?? '').toString(),
      isCompliance: isCompliance,
    );
  }
}

class ActivityStreamSection {
  final List<ActivityStreamItem> items;

  const ActivityStreamSection(this.items);

  factory ActivityStreamSection.fromJson(dynamic value) {
    if (value is! Map) return const ActivityStreamSection([]);
    final map = Map<String, dynamic>.from(value);
    final items = <ActivityStreamItem>[];

    void addItems(dynamic list, bool isCompliance) {
      if (list is! List) return;
      for (final item in list.whereType<Map>()) {
        items.add(ActivityStreamItem.fromJson(
          Map<String, dynamic>.from(item),
          isCompliance: isCompliance,
        ));
      }
    }

    addItems(map['taskAssigned'], false);
    addItems(map['complianceAssigned'], true);
    return ActivityStreamSection(items);
  }
}

class ActivityStreamData {
  final String todayTitle;
  final Map<String, ActivityStreamSection> sections;

  const ActivityStreamData({
    required this.todayTitle,
    required this.sections,
  });

  factory ActivityStreamData.fromJson(Map<String, dynamic> json) {
    return ActivityStreamData(
      todayTitle: json['todaytitle']?.toString() ?? '',
      sections: {
        'upcoming': ActivityStreamSection.fromJson(json['upcoming']),
        'today': ActivityStreamSection.fromJson(json['today']),
        'recent': ActivityStreamSection.fromJson(json['recent']),
        'observer': ActivityStreamSection.fromJson(json['observer']),
      },
    );
  }
}
