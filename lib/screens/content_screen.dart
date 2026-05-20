import 'package:flutter/material.dart';
import '../models/menu.dart';

class ContentScreen extends StatelessWidget {
  final MenuItem menuItem;

  const ContentScreen({super.key, required this.menuItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          menuItem.menuName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1F2A6D),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1F2A6D).withOpacity(0.1), const Color(0xFF2E3A8C).withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForMenu(menuItem.icon),
                  size: 80,
                  color: const Color(0xFFFF6A00),
                ),
                const SizedBox(height: 24),
                Text(
                  menuItem.menuName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2A6D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Access Link: ${menuItem.accessLink}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
                  child: Text(
                    'Content for ${menuItem.menuName} will be displayed here. This is a placeholder page that can be customized based on the menu item requirements.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForMenu(String iconString) {
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
      default:
        return Icons.apps; // Default icon
    }
  }
}