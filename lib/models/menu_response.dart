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

  /// Builds the same level_1 / level_2 / level_3 shape from the nested tree that
  /// `/user/ajax_sidebar_menu_g2g` returns (module -> `menus` -> `submenus` ...).
  ///
  /// That endpoint is what the web sidebar uses and is driven by Role &
  /// Permissions, so the app's menu now follows it. The tree has no `parent_id` or
  /// `level`, so both come from where each row sits. Anything nested deeper than
  /// level 3 is kept under its parent at level 3 rather than dropped.
  factory MenuResponse.fromSidebarTree(List<dynamic> tree) {
    final level1 = <MenuItem>[];
    final level2 = <String, Map<String, MenuItem>>{};
    final level3 = <String, Map<String, MenuItem>>{};

    MenuItem toItem(Map<String, dynamic> n, int parentId, int level) => MenuItem(
          id: (n['id'] as num?)?.toInt() ?? 0,
          menuName: (n['label'] ?? n['menu_name'] ?? '').toString(),
          parentId: parentId,
          level: level,
          pageType: (n['page_type'] ?? '').toString(),
          accessLink: (n['access_link'] ?? '').toString(),
          icon: (n['icon'] ?? '').toString(),
          status: 1,
          sortOrder: (n['sort_order'] as num?)?.toInt() ?? 0,
          subInstituteId: '',
          menuType: '',
          canView: (n['can_view'] as num?)?.toInt() ?? 1,
          canAdd: (n['can_add'] as num?)?.toInt() ?? 0,
          canEdit: (n['can_edit'] as num?)?.toInt() ?? 0,
          canDelete: (n['can_delete'] as num?)?.toInt() ?? 0,
          dashboardRight: (n['dashboard_right'] as num?)?.toInt() ?? 0,
          isMobile: (n['is_mobile'] as num?)?.toInt() ?? 0,
        );

    List<dynamic> childrenOf(Map<String, dynamic> n) =>
        (n['menus'] ?? n['submenus'] ?? n['children'] ?? const []) as List<dynamic>;

    void walk(Map<String, dynamic> node, int parentId, int level) {
      final item = toItem(node, parentId, level);
      if (level == 1) {
        level1.add(item);
      } else {
        final bucket = level == 2 ? level2 : level3;
        (bucket[parentId.toString()] ??= {})[item.id.toString()] = item;
      }
      for (final c in childrenOf(node)) {
        if (c is Map<String, dynamic>) walk(c, item.id, level >= 3 ? 3 : level + 1);
      }
    }

    for (final m in tree) {
      if (m is Map<String, dynamic>) walk(m, 0, 1);
    }

    return MenuResponse(level1: level1, level2: level2, level3: level3);
  }

  // Get only level 3 mobile menus (is_mobile == 1)
  List<MenuItem> getMobileMenus() {
    List<MenuItem> mobileMenus = [];

    // Level 3 mobile menus
    for (var subMenus in level3.values) {
      mobileMenus.addAll(subMenus.values.where((menu) => menu.isMobile == 1));
    }

    // A screen sitting directly under a module (level 2, e.g. Travel Visit).
    // Only real pages: a level 2 GROUP is a folder, not something to open.
    for (var subMenus in level2.values) {
      mobileMenus.addAll(subMenus.values.where((menu) => menu.isMobile == 1 && menu.pageType == 'page'));
    }

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