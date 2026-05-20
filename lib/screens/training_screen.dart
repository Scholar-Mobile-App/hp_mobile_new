import 'package:flutter/material.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Training & Learning',
          style: TextStyle(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Learning Center',
                style: TextStyle(
                  color: Color(0xFF1F2A6D),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Expand your knowledge and skills with our comprehensive training programs',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              _buildCourseCard(
                'Advanced Leadership Skills',
                'Develop strategic thinking and team management abilities',
                '4.8',
                '2h 30m',
                Icons.leaderboard,
                true,
              ),
              const SizedBox(height: 16),
              _buildCourseCard(
                'Digital Transformation',
                'Navigate the digital landscape and emerging technologies',
                '4.9',
                '3h 15m',
                Icons.computer,
                false,
              ),
              const SizedBox(height: 16),
              _buildCourseCard(
                'Project Management Excellence',
                'Master agile and traditional project management methodologies',
                '4.7',
                '5h 45m',
                Icons.work,
                true,
              ),
              const SizedBox(height: 16),
              _buildCourseCard(
                'Communication & Influence',
                'Enhance your ability to communicate effectively and influence others',
                '4.6',
                '2h 15m',
                Icons.message,
                false,
              ),
              const SizedBox(height: 16),
              _buildCourseCard(
                'Data Analytics Fundamentals',
                'Learn to analyze data and make data-driven decisions',
                '4.8',
                '4h 20m',
                Icons.analytics,
                false,
              ),
              const SizedBox(height: 24),
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
                    const Text(
                      'Learning Paths',
                      style: TextStyle(
                        color: Color(0xFF1F2A6D),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLearningPath('Management Track', '3 courses • 12h total', 0.4),
                    const SizedBox(height: 12),
                    _buildLearningPath('Technical Excellence', '5 courses • 18h total', 0.2),
                    const SizedBox(height: 12),
                    _buildLearningPath('Leadership Development', '4 courses • 15h total', 0.6),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                      'Your Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProgressItem('Courses Completed', '8/15', 0.53),
                    const SizedBox(height: 12),
                    _buildProgressItem('Learning Hours', '24/50', 0.48),
                    const SizedBox(height: 12),
                    _buildProgressItem('Certificates Earned', '3/8', 0.38),
                    const SizedBox(height: 16),
                    const Text(
                      'Great progress! Keep learning to unlock new opportunities.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                    const Text(
                      'Recommended for You',
                      style: TextStyle(
                        color: Color(0xFF1F2A6D),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecommendation('Innovation & Creativity', 'Based on your role and interests'),
                    _buildRecommendation('Change Management', 'Popular among your peers'),
                    _buildRecommendation('Advanced Communication', 'Complements your current skills'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(String title, String description, String rating, String duration, IconData icon, bool enrolled) {
    return Container(
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
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFFFF6A00),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1F2A6D),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    duration,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: enrolled ? Colors.grey : const Color(0xFFFF6A00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                enrolled ? 'Continue Learning' : 'Enroll Now',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPath(String title, String details, double progress) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1F2A6D),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                details,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6A00)),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildRecommendation(String title, String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6A00),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1F2A6D),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  reason,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}