import 'package:flutter/material.dart';

import '../models/menu.dart';
import 'attendance/attendance_report_screen.dart';
import 'attendance/attendance_screen.dart';
import 'competency_management/library_taxonomy/library_taxonomy_screen.dart';
import 'hrms/apply_leave_screen.dart';
import 'hrms/my_leave_screen.dart';
import 'hrms/travel_visit_screen.dart';
import 'lms/assessment_list_screen.dart';
import 'lms/courses_list_screen.dart';
import 'lms/my_learning_dashboard_screen.dart';
import 'organization_management/organization_detail_screen.dart';
import 'organization_management/task_assignment_progress_screen.dart';

/// Which app screen a menu from the sidebar API opens.
///
/// The app's menu comes from `/user/ajax_sidebar_menu_g2g`, so the names on the
/// cards - and in the screens that print the menu's name - are the names that API
/// sends. A screen is chosen by the menu's `access_link`, which does not change
/// when a menu is renamed. A menu with no entry here has no screen in the app and
/// is left off the dashboard rather than shown as a card that opens nothing useful.
final Map<String, Widget Function(MenuItem item)> _routes = {
  '/module/hrit-solutions/attendance-management/attendance-tracking': (_) => AttendanceScreen(),
  '/module/hrit-solutions/attendance-management/monthly-attendance-report': (_) => const AttendanceReportScreen(),
  '/module/hrit-solutions/leave-management/leave-dashboard': (_) => ApplyLeaveScreen(),
  '/module/hrit-solutions/leave-management/leave-requests': (_) => MyLeaveScreen(),
  '/module/hrit-solutions/travel-visit': (_) => const TravelVisitScreen(),
  '/module/lms/learning/learning-catalog': (m) => CoursesListScreen(menuItem: m),
  '/module/lms/learning/my-learning': (m) => MyLearningDashboardScreen(menuItem: m),
  '/module/lms/learning/my-assessment': (m) => AssessmentListScreen(menuItem: m),
  '/module/task-management/my-tasks': (_) => const TaskAssignmentProgressScreen(),
  '/module/capability-intelligence/capability-library': (m) => LibraryTaxonomyScreen(menuItem: m),
  '/module/organizational-management/organization-setup/organization-profile': (_) => const OrganizationDetailScreen(),
};

String _key(MenuItem m) => m.accessLink.trim().toLowerCase().replaceAll(RegExp(r'/+$'), '');

/// The screen for [item], or null when the app has none.
Widget? mobileScreenFor(MenuItem item) => _routes[_key(item)]?.call(item);

/// Only the menus the app can open, in the order the server sent them.
List<MenuItem> openableMobileMenus(List<MenuItem> menus) =>
    menus.where((m) => _routes.containsKey(_key(m))).toList();
