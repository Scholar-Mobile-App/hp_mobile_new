import 'menu.dart';

class MenuResponse {
  final List<MenuItem> level1;
  final Map<String, Map<String, MenuItem>> level2;
  final Map<String, Map<String, MenuItem>> level3;

  MenuResponse({
    required this.level1,
    required this.level2,
    required this.level3,
  });

  factory MenuResponse.fromJson(Map<String, dynamic> json) {
    // Parse level_1
    List<MenuItem> level1 = [];
    if (json['level_1'] != null) {
      level1 = (json['level_1'] as List).map((item) => MenuItem.fromJson(item)).toList();
    }

    // Parse level_2
    Map<String, Map<String, MenuItem>> level2 = {};
    if (json['level_2'] != null) {
      (json['level_2'] as Map<String, dynamic>).forEach((parentKey, subMenus) {
        if (subMenus is Map<String, dynamic>) {
          Map<String, MenuItem> subMenuMap = {};
          subMenus.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              subMenuMap[key] = MenuItem.fromJson(value);
            }
          });
          level2[parentKey] = subMenuMap;
        }
      });
    }

    // Parse level_3
    Map<String, Map<String, MenuItem>> level3 = {};
    if (json['level_3'] != null) {
      (json['level_3'] as Map<String, dynamic>).forEach((parentKey, subMenus) {
        if (subMenus is Map<String, dynamic>) {
          Map<String, MenuItem> subMenuMap = {};
          subMenus.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              subMenuMap[key] = MenuItem.fromJson(value);
            }
          });
          level3[parentKey] = subMenuMap;
        }
      });
    }

    return MenuResponse(
      level1: level1,
      level2: level2,
      level3: level3,
    );
  }

  // Get only level 3 mobile menus (is_mobile == 1)
  List<MenuItem> getMobileMenus() {
    List<MenuItem> mobileMenus = [];

    // Add only level 3 mobile menus
    level3.values.forEach((subMenus) {
      mobileMenus.addAll(subMenus.values.where((menu) => menu.isMobile == 1));
    });

    // Sort by sort_order
    mobileMenus.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return mobileMenus;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> level2Json = {};
    level2.forEach((parentKey, subMenus) {
      Map<String, dynamic> subMenuJson = {};
      subMenus.forEach((key, menuItem) {
        subMenuJson[key] = menuItem.toJson();
      });
      level2Json[parentKey] = subMenuJson;
    });

    Map<String, dynamic> level3Json = {};
    level3.forEach((parentKey, subMenus) {
      Map<String, dynamic> subMenuJson = {};
      subMenus.forEach((key, menuItem) {
        subMenuJson[key] = menuItem.toJson();
      });
      level3Json[parentKey] = subMenuJson;
    });

    return {
      'level_1': level1.map((item) => item.toJson()).toList(),
      'level_2': level2Json,
      'level_3': level3Json,
    };
  }
}