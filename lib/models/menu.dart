class MenuItem {
  final int id;
  final String menuName;
  final int parentId;
  final int level;
  final String pageType;
  final String accessLink;
  final String icon;
  final int status;
  final int sortOrder;
  final String subInstituteId;
  final String menuType;
  final int canView;
  final int canAdd;
  final int canEdit;
  final int canDelete;
  final int dashboardRight;
  final int isMobile;

  MenuItem({
    required this.id,
    required this.menuName,
    required this.parentId,
    required this.level,
    required this.pageType,
    required this.accessLink,
    required this.icon,
    required this.status,
    required this.sortOrder,
    required this.subInstituteId,
    required this.menuType,
    required this.canView,
    required this.canAdd,
    required this.canEdit,
    required this.canDelete,
    required this.dashboardRight,
    required this.isMobile,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? 0,
      menuName: json['menu_name'] ?? '',
      parentId: json['parent_id'] ?? 0,
      level: json['level'] ?? 1,
      pageType: json['page_type'] ?? '',
      accessLink: json['access_link'] ?? '',
      icon: json['icon'] ?? '',
      status: json['status'] ?? 1,
      sortOrder: json['sort_order'] ?? 0,
      subInstituteId: json['sub_institute_id'] ?? '',
      menuType: json['menu_type'] ?? '',
      canView: json['can_view'] ?? 1,
      canAdd: json['can_add'] ?? 0,
      canEdit: json['can_edit'] ?? 0,
      canDelete: json['can_delete'] ?? 0,
      dashboardRight: json['dashboard_right'] ?? 0,
      isMobile: json['is_mobile'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_name': menuName,
      'parent_id': parentId,
      'level': level,
      'page_type': pageType,
      'access_link': accessLink,
      'icon': icon,
      'status': status,
      'sort_order': sortOrder,
      'sub_institute_id': subInstituteId,
      'menu_type': menuType,
      'can_view': canView,
      'can_add': canAdd,
      'can_edit': canEdit,
      'can_delete': canDelete,
      'dashboard_right': dashboardRight,
      'is_mobile': isMobile,
    };
  }
}