import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import 'login_screen.dart';
import 'profile_details_screen.dart';
import 'goals_screen.dart';
import 'achievements_screen.dart';
import 'training_screen.dart';
import 'resources_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('Dashboard initState called');
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    debugPrint('Current user: ${user?.userName}');
    debugPrint('User token: ${user?.token}');
    debugPrint('User id: ${user?.id}');
  }

  Widget _buildQuickActionCard(BuildContext context, String title, IconData icon, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Color(0xFFFF6A00),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Color(0xFF1F2A6D),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    debugPrint('Dashboard user image: ${user?.image}');

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF1F2A6D),
        elevation: 0,
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6A00), Color(0xFFFF7A1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     CircleAvatar(
                       radius: 35,
                       backgroundImage: user.image.isNotEmpty ? NetworkImage(
                         user.image.startsWith('http') ? user.image : 'https://s3-triz.fra1.cdn.digitaloceanspaces.com/public/hp_user/' + user.image
                       ) : null,
                       backgroundColor: Colors.white,
                       child: user.image.isEmpty ? Icon(
                         Icons.person,
                         size: 35,
                         color: Color(0xFF1F2A6D),
                       ) : null,
                     ),
                    SizedBox(height: 12),
                    Text(
                      user.fullName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white.withOpacity(0.1),
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text(
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F2A6D).withOpacity(0.1), Color(0xFF2E3A8C).withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6A00), Color(0xFFFF7A1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF6A00).withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.waving_hand,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user.firstName}!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Logged in as ${user.userProfileName} at ${user.orgName}',
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
              SizedBox(height: 24),
              Text(
                'Dashboard',
                style: TextStyle(
                  color: Color(0xFF1F2A6D),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileDetailsScreen()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: user.image.isNotEmpty ? NetworkImage(
                            user.image.startsWith('http') ? user.image : 'https://s3-triz.fra1.cdn.digitaloceanspaces.com/public/hp_user/' + user.image
                          ) : null,
                          backgroundColor: Color(0xFF1F2A6D),
                          child: user.image.isEmpty ? Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.white,
                          ) : null,
                        ),
                       SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               user.fullName,
                               style: TextStyle(
                                 color: Color(0xFF1F2A6D),
                                 fontSize: 20,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                             SizedBox(height: 4),
                             Text(
                               user.email,
                               style: TextStyle(
                                 color: Colors.grey[600],
                                 fontSize: 14,
                               ),
                             ),
                             SizedBox(height: 4),
                             Text(
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
                       Icon(
                         Icons.arrow_forward_ios,
                         color: Color(0xFF1F2A6D),
                         size: 16,
                       ),
                     ],
                   ),
                 ),
               ),
               SizedBox(height: 24),
               Text(
                 'Quick Actions',
                 style: TextStyle(
                   color: Color(0xFF1F2A6D),
                   fontSize: 22,
                   fontWeight: FontWeight.bold,
                 ),
               ),
               SizedBox(height: 16),
               GridView.count(
                 crossAxisCount: 2,
                 shrinkWrap: true,
                 physics: NeverScrollableScrollPhysics(),
                 crossAxisSpacing: 16,
                 mainAxisSpacing: 16,
                 children: [
                   _buildQuickActionCard(
                     context,
                     'Goals',
                     Icons.flag,
                     'Track your development goals',
                     () => _navigateToGoals(context),
                   ),
                   _buildQuickActionCard(
                     context,
                     'Achievements',
                     Icons.emoji_events,
                     'View your milestones',
                     () => _navigateToAchievements(context),
                   ),
                   _buildQuickActionCard(
                     context,
                     'Training',
                     Icons.school,
                     'Access learning resources',
                     () => _navigateToTraining(context),
                   ),
                   _buildQuickActionCard(
                     context,
                     'Resources',
                     Icons.library_books,
                     'Company documents & policies',
                     () => _navigateToResources(context),
                   ),
                 ],
               ),
               SizedBox(height: 24),
               Text(
                 'Recent Announcements',
                 style: TextStyle(
                   color: Color(0xFF1F2A6D),
                   fontSize: 22,
                   fontWeight: FontWeight.bold,
                 ),
               ),
               SizedBox(height: 16),
               Container(
                 padding: EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(16),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.grey.withOpacity(0.2),
                       blurRadius: 8,
                       offset: Offset(0, 4),
                     ),
                   ],
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
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
                     SizedBox(height: 12),
                     Text(
                       'Your journey to professional development starts here. Set goals, track progress, and achieve your career aspirations with our comprehensive tools.',
                       style: TextStyle(
                         color: Colors.grey[700],
                         fontSize: 14,
                         height: 1.5,
                       ),
                     ),
                     SizedBox(height: 16),
                     Text(
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
               SizedBox(height: 24),
               Text(
                 'Progress Overview',
                 style: TextStyle(
                   color: Color(0xFF1F2A6D),
                   fontSize: 22,
                   fontWeight: FontWeight.bold,
                 ),
               ),
               SizedBox(height: 16),
               Container(
                 padding: EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   gradient: LinearGradient(
                     colors: [Color(0xFFFF6A00), Color(0xFFFF7A1A)],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                   borderRadius: BorderRadius.circular(16),
                   boxShadow: [
                     BoxShadow(
                       color: Color(0xFFFF6A00).withOpacity(0.3),
                       blurRadius: 10,
                       offset: Offset(0, 5),
                     ),
                   ],
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       'Your Development Progress',
                       style: TextStyle(
                         color: Colors.white,
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     SizedBox(height: 16),
                     _buildProgressItem('Goals Completed', '3/5', 0.6),
                     SizedBox(height: 12),
                     _buildProgressItem('Courses Started', '2/8', 0.25),
                     SizedBox(height: 12),
                     _buildProgressItem('Achievements Unlocked', '7/15', 0.47),
                     SizedBox(height: 16),
                     Text(
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
    );
  }






}