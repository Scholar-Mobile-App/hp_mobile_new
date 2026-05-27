import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/notification_service.dart';
import '../models/user.dart';
import '../models/menu.dart';
import '../models/menu_response.dart';
import 'login_screen.dart';
import 'profile_details_screen.dart';
import 'goals_screen.dart';
import 'achievements_screen.dart';
import 'training_screen.dart';
import 'resources_screen.dart';
import 'content_screen.dart';
import 'competency_management/library_taxonomy/library_taxonomy_screen.dart';
import 'competency_management/library_taxonomy/jobrole_screen.dart';
import 'attendance/attendance_screen.dart';
import 'attendance/attendance_report_screen.dart';
import 'organization_management/task_assignment_progress_screen.dart';
import 'organization_management/organization_detail_screen.dart';
import 'lms/courses_list_screen.dart';
import 'lms/my_learning_dashboard_screen.dart';
import 'lms/assessment_list_screen.dart';
import 'hrms/apply_leave_screen.dart';
import 'hrms/my_leave_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _initializeFCMToken(User user) async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.updateTokenWithUser(user.id.toString(), user.token);
    } catch (e) {
      debugPrint('Error initializing FCM token: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildQuickActionCard(BuildContext context, String title, IconData icon, String subtitle, VoidCallback? onTap, {required int level}) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing based on device type and orientation
    bool isLandscape = screenWidth > screenHeight;
    double basePadding;

    if (screenWidth >= 1200) {
      basePadding = isLandscape ? 22 : 24;
    } else if (screenWidth >= 800) {
      basePadding = isLandscape ? 20 : 22;
    } else if (screenWidth >= 600) {
      basePadding = isLandscape ? 18 : 20;
    } else {
      basePadding = isLandscape ? 16 : 18;
    }

    double padding = level == 1 ? basePadding * 1.5 : level == 2 ? basePadding * 1.2 : basePadding;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: level == 1
                ? [const Color(0xFFFF6A00), const Color(0xFFFF7A1A)]
                : level == 2
                    ? [const Color(0xFF1F2A6D), const Color(0xFF2E3A8C)]
                    : [Colors.white, const Color(0xFFF8F9FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: level == 3 ? Border.all(color: const Color(0xFF1F2A6D).withOpacity(0.2), width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompactCard = constraints.maxWidth < 180;
            final double cardWidth = constraints.maxWidth;
            final double iconSize = (cardWidth * (isCompactCard ? 0.16 : 0.18)).clamp(22.0, 44.0);
            final double titleFontSize = (cardWidth * (isCompactCard ? 0.088 : 0.105)).clamp(12.5, 22.0);
            final double subtitleFontSize = (cardWidth * (isCompactCard ? 0.062 : 0.078)).clamp(10.0, 16.0);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: level == 1 || level == 2 ? Colors.white : const Color(0xFFFF6A00),
                ),
                SizedBox(height: isCompactCard ? 6 : 12),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: level == 1 || level == 2 ? Colors.white : const Color(0xFF1F2A6D),
                      height: 1.15,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: isCompactCard ? 2 : 6),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: screenWidth >= 500 ? FontWeight.w600 : FontWeight.normal,
                      color: level == 1 || level == 2 ? Colors.white70 : Colors.grey[600],
                      height: 1.15,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: isCompactCard ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ],
    );
  }

  void _navigateToGoals(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GoalsScreen()),
    );
  }

  void _navigateToAchievements(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AchievementsScreen()),
    );
  }

  void _navigateToTraining(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TrainingScreen()),
    );
  }

  void _navigateToResources(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResourcesScreen()),
    );
  }

  IconData _getIconFromString(String iconString, String menuName, int index) {
    // Map common icon strings to Flutter Icons
    switch (iconString.toLowerCase()) {
      case 'mdi mdi-flag':
        return Icons.flag;
      case 'mdi mdi-emoji-events':
        return Icons.emoji_events;
      case 'mdi mdi-school':
        return Icons.school;
      case 'mdi mdi-library-books':
        return Icons.library_books;
      case 'mdi mdi-domain':
        return Icons.domain;
      case 'mdi mdi-account-group':
        return Icons.group;
      case 'mdi mdi-file-certificate':
        return Icons.assignment;
      case 'mdi mdi-school-outline':
        return Icons.school_outlined;
      case 'mdi mdi-account-multiple':
        return Icons.people;
      case 'mdi mdi-file-chart':
        return Icons.bar_chart;
      case 'mdi mdi-view-dashboard':
        return Icons.dashboard;
      case 'mdi mdi-account-box':
        return Icons.account_box;
      case 'mdi mdi-calendar-check':
        return Icons.calendar_today;
      case 'mdi mdi-clipboard-check':
        return Icons.checklist;
      case 'mdi mdi-chart-line':
        return Icons.show_chart;
      case 'mdi mdi-book-open':
        return Icons.book;
      case 'mdi mdi-settings':
        return Icons.settings;
      case 'mdi mdi-bell':
        return Icons.notifications;
      case 'mdi mdi-folder':
        return Icons.folder;
      case 'mdi mdi-star':
        return Icons.star;
      case 'mdi mdi-trophy':
        return Icons.emoji_events;
      case 'mdi mdi-target':
        return Icons.track_changes;
      case 'mdi mdi-brain':
        return Icons.psychology;
      case 'mdi mdi-lightbulb':
        return Icons.lightbulb;
      case 'mdi mdi-trending-up':
        return Icons.trending_up;
      default:
        // Dynamic fallback based on menu name keywords and index
        return _getDynamicIcon(menuName, index);
    }
  }

  IconData _getDynamicIcon(String menuName, int index) {
    // Create a dynamic icon based on menu name keywords
    final name = menuName.toLowerCase();

    // Check for specific keywords in menu name
    if (name.contains('goal') || name.contains('target')) {
      return Icons.track_changes;
    } else if (name.contains('achievement') || name.contains('trophy') || name.contains('award')) {
      return Icons.emoji_events;
    } else if (name.contains('training') || name.contains('course') || name.contains('learning')) {
      return Icons.school;
    } else if (name.contains('resource') || name.contains('library') || name.contains('document')) {
      return Icons.library_books;
    } else if (name.contains('profile') || name.contains('account')) {
      return Icons.account_circle;
    } else if (name.contains('attendance') || name.contains('calendar')) {
      return Icons.calendar_today;
    } else if (name.contains('competency') || name.contains('skill')) {
      return Icons.psychology;
    } else if (name.contains('organization') || name.contains('team') || name.contains('group')) {
      return Icons.group;
    } else if (name.contains('report') || name.contains('chart') || name.contains('analytics')) {
      return Icons.bar_chart;
    } else if (name.contains('task') || name.contains('assignment')) {
      return Icons.assignment;
    } else if (name.contains('dashboard') || name.contains('overview')) {
      return Icons.dashboard;
    } else {
      // Fallback to a rotating set of icons based on index
      final icons = [
        Icons.apps,
        Icons.widgets,
        Icons.grid_view,
        Icons.view_list,
        Icons.view_module,
        Icons.list,
        Icons.menu,
        Icons.more_horiz,
        Icons.more_vert,
        Icons.category,
        Icons.extension,
        Icons.build,
        Icons.settings_applications,
      ];
      return icons[index % icons.length];
    }
  }

  void _navigateToMenuItem(BuildContext context, MenuItem menuItem) {
    // Handle navigation based on menu item
    if (menuItem.menuName == "Library & Taxonomy") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LibraryTaxonomyScreen(menuItem: menuItem),
        ),
      );
    } else if (menuItem.menuName.toLowerCase().contains("jobrole")) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const JobRoleScreen(),
        ),
      );
    } else if (menuItem.menuName == "My Attendance") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceScreen(),
        ),
      );
    } else if (menuItem.menuName.toLowerCase().contains('attendance') &&
               menuItem.menuName.toLowerCase().contains('report')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AttendanceReportScreen(),
        ),
      );
    } else if (menuItem.menuName == "Task Assignment & Progress") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TaskAssignmentProgressScreen(),
        ),
      );
    } else if (menuItem.menuName == "Add Organization Detail") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OrganizationDetailScreen(),
        ),
      );
    } else if (menuItem.menuName == "My Learning Dashboard") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyLearningDashboardScreen(menuItem: menuItem),
        ),
      );
    } else if (menuItem.menuName == "Assessment List") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssessmentListScreen(menuItem: menuItem),
        ),
      );
    } else if (menuItem.menuName.toLowerCase().contains('course') ||
                menuItem.menuName.toLowerCase().contains('lms')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CoursesListScreen(menuItem: menuItem),
        ),
      );
    } else if (menuItem.menuName.toLowerCase().contains('apply') &&
               menuItem.menuName.toLowerCase().contains('leave')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ApplyLeaveScreen()),
      );
    } else if (menuItem.menuName.toLowerCase().contains('my') &&
               menuItem.menuName.toLowerCase().contains('leave')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyLeaveScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContentScreen(menuItem: menuItem),
        ),
      );
    }
  }


  Widget _buildDefaultQuickActions(BuildContext context) {
    debugPrint('No mobile menus available, showing default menus');

    // Responsive grid configuration based on screen size and orientation
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool isLandscape = screenWidth > screenHeight;

    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth >= 1200) {
      // Large tablets/desktops
      crossAxisCount = isLandscape ? 5 : 4;
      childAspectRatio = isLandscape ? 1.1 : 1.2;
    } else if (screenWidth >= 800) {
      // Medium tablets
      crossAxisCount = isLandscape ? 4 : 3;
      childAspectRatio = isLandscape ? 1.15 : 1.25;
    } else if (screenWidth >= 600) {
      // Small tablets/large phones
      crossAxisCount = isLandscape ? 3 : 2;
      childAspectRatio = isLandscape ? 1.2 : 1.3;
    } else {
      // Phones
      crossAxisCount = isLandscape ? 3 : 2;
      childAspectRatio = isLandscape ? 1.3 : 1.4;
    }

    return GridView(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildQuickActionCard(
          context,
          'Goals',
          Icons.flag,
          'Track your development goals',
          () => _navigateToGoals(context),
          level: 3,
        ),
        _buildQuickActionCard(
          context,
          'Achievements',
          Icons.emoji_events,
          'View your milestones',
          () => _navigateToAchievements(context),
          level: 3,
        ),
        _buildQuickActionCard(
          context,
          'Training',
          Icons.school,
          'Access learning resources',
          () => _navigateToTraining(context),
          level: 3,
        ),
        _buildQuickActionCard(
          context,
          'Resources',
          Icons.library_books,
          'Company documents & policies',
          () => _navigateToResources(context),
          level: 3,
        ),
      ],
    );
  }

  Widget _buildDynamicQuickActions(BuildContext context, List<MenuItem> mobileMenus) {
    debugPrint('Showing ${mobileMenus.length} dynamic menus');

    // Responsive grid configuration based on screen size and orientation (same as default)
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool isLandscape = screenWidth > screenHeight;

    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth >= 1200) {
      // Large tablets/desktops
      crossAxisCount = isLandscape ? 5 : 4;
      childAspectRatio = isLandscape ? 1.1 : 1.2;
    } else if (screenWidth >= 800) {
      // Medium tablets
      crossAxisCount = isLandscape ? 4 : 3;
      childAspectRatio = isLandscape ? 1.15 : 1.25;
    } else if (screenWidth >= 600) {
      // Small tablets/large phones
      crossAxisCount = isLandscape ? 3 : 2;
      childAspectRatio = isLandscape ? 1.2 : 1.3;
    } else {
      // Phones
      crossAxisCount = isLandscape ? 3 : 2;
      childAspectRatio = isLandscape ? 1.3 : 1.4;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mobileMenus.length,
      itemBuilder: (context, index) {
        final menuItem = mobileMenus[index];
        debugPrint('Menu item $index: ${menuItem.menuName}, icon: ${menuItem.icon}');
        return _buildQuickActionCard(
          context,
          menuItem.menuName,
          _getIconFromString(menuItem.icon, menuItem.menuName, index),
          'Access ${menuItem.menuName}',
          () => _navigateToMenuItem(context, menuItem),
          level: 3,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    var mobileMenus = auth.menuResponse?.getMobileMenus() ?? [];


    debugPrint('Dashboard user image: ${user?.image}');

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1F2A6D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              debugPrint('Refresh button pressed');
              await context.read<AuthProvider>().fetchMenuRights();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu updated')),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F2A6D), Color(0xFF2E3A8C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6A00), Color(0xFFFF7A1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: user.image.isNotEmpty ? NetworkImage(
                          user.image.startsWith('http') ? user.image : 'https://s3-triz.fra1.cdn.digitaloceanspaces.com/public/hp_user/${user.image}'
                        ) : null,
                        backgroundColor: Colors.white,
                        child: user.image.isEmpty ? const Icon(
                          Icons.person,
                          size: 35,
                          color: Color(0xFF1F2A6D),
                        ) : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
               Container(
                 color: Colors.white.withOpacity(0.1),
                 child: ListTile(
                   leading: const Icon(Icons.logout, color: Colors.white),
                   title: const Text(
                     'Logout',
                     style: TextStyle(color: Colors.white, fontSize: 16),
                   ),
                   onTap: () async {
                     Navigator.pop(context); // Close the drawer
                     await auth.logout();
                     Navigator.pushReplacement(
                       context,
                       MaterialPageRoute(builder: (context) => LoginScreen()),
                     );
                   },
                 ),
               ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          debugPrint('Pull to refresh triggered');
          await context.read<AuthProvider>().fetchMenuRights();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1F2A6D).withOpacity(0.1), const Color(0xFF2E3A8C).withOpacity(0.05)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6A00), Color(0xFFFF7A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6A00).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.waving_hand,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${user.firstName}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Logged in as ${user.userProfileName} at ${user.orgName}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Color(0xFF1F2A6D),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileDetailsScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: user.image.isNotEmpty ? NetworkImage(
                            user.image.startsWith('http') ? user.image : 'https://s3-triz.fra1.cdn.digitaloceanspaces.com/public/hp_user/${user.image}'
                          ) : null,
                          backgroundColor: const Color(0xFF1F2A6D),
                          child: user.image.isEmpty ? const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.white,
                          ) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  color: Color(0xFF1F2A6D),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap to view full profile',
                                style: TextStyle(
                                  color: Color(0xFFFF6A00),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF1F2A6D),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: Color(0xFF1F2A6D),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                mobileMenus.isEmpty
                    ? _buildDefaultQuickActions(context)
                    : _buildDynamicQuickActions(context, mobileMenus),
                const SizedBox(height: 24),
                const Text(
                  'Recent Announcements',
                  style: TextStyle(
                    color: Color(0xFF1F2A6D),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.campaign, color: Color(0xFFFF6A00), size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Welcome to Gaps To Growth!',
                            style: TextStyle(
                              color: Color(0xFF1F2A6D),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your journey to professional development starts here. Set goals, track progress, and achieve your career aspirations with our comprehensive tools.',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Recent Update: New training modules available',
                        style: TextStyle(
                          color: Color(0xFFFF6A00),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Progress Overview',
                  style: TextStyle(
                    color: Color(0xFF1F2A6D),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6A00), Color(0xFFFF7A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6A00).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Development Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProgressItem('Goals Completed', '3/5', 0.6),
                      const SizedBox(height: 12),
                      _buildProgressItem('Courses Started', '2/8', 0.25),
                      const SizedBox(height: 12),
                      _buildProgressItem('Achievements Unlocked', '7/15', 0.47),
                      const SizedBox(height: 16),
                      const Text(
                        'Keep up the great work! You\'re making excellent progress.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
