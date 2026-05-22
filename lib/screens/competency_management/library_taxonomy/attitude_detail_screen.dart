import 'package:flutter/material.dart';
import '../../../models/user_attitude.dart';

class AttitudeDetailScreen extends StatelessWidget {
  final UserAttitude attitude;

  const AttitudeDetailScreen({super.key, required this.attitude});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(attitude.title ?? 'Attitude Details'),
        backgroundColor: const Color(0xFF1F2A6D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1F2A6D).withOpacity(0.05), const Color(0xFFE8F4FD).withOpacity(0.3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFF8F9FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.mood, color: Color(0xFFFF6A00), size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              attitude.title ?? 'No Title',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2A6D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildChip('Category: ${attitude.category ?? 'N/A'}'),
                      if (attitude.subCategory != null && attitude.subCategory!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _buildChip('Sub-Category: ${attitude.subCategory}'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Description Section
              if (attitude.description != null && attitude.description!.isNotEmpty)
                _buildDetailCard(
                  'Description',
                  attitude.description!,
                  Icons.description,
                  const Color(0xFF1F2A6D),
                ),

              // Business Link
              if (attitude.businessLink != null && attitude.businessLink!.isNotEmpty)
                _buildDetailCard(
                  'Business Link',
                  attitude.businessLink!,
                  Icons.link,
                  const Color(0xFF2196F3),
                ),

              // Assessment Method
              if (attitude.assessmentMethod != null && attitude.assessmentMethod!.isNotEmpty)
                _buildDetailCard(
                  'Assessment Method',
                  attitude.assessmentMethod!,
                  Icons.assessment,
                  const Color(0xFF4CAF50),
                ),

              // Attitude Tags
              if (attitude.attitudeTags != null && attitude.attitudeTags!.isNotEmpty)
                _buildDetailCard(
                  'Attitude Tags',
                  attitude.attitudeTags!,
                  Icons.tag,
                  const Color(0xFFFF6A00),
                ),

              // Development Methods
              if (attitude.developmentMethods != null && attitude.developmentMethods!.isNotEmpty)
                _buildDetailCard(
                  'Development Methods',
                  attitude.developmentMethods!,
                  Icons.school,
                  const Color(0xFF9C27B0),
                ),

              // Negative Indicators
              if (attitude.negativeIndicators != null && attitude.negativeIndicators!.isNotEmpty)
                _buildDetailCard(
                  'Negative Indicators',
                  attitude.negativeIndicators!,
                  Icons.warning,
                  const Color(0xFFF44336),
                ),

              // Improvement Strategies
              if (attitude.improvementStrategies != null && attitude.improvementStrategies!.isNotEmpty)
                _buildDetailCard(
                  'Improvement Strategies',
                  attitude.improvementStrategies!,
                  Icons.trending_up,
                  const Color(0xFF009688),
                ),

              // Cultural Alignment
              if (attitude.culturalAlignment != null && attitude.culturalAlignment!.isNotEmpty)
                _buildDetailCard(
                  'Cultural Alignment',
                  attitude.culturalAlignment!,
                  Icons.public,
                  const Color(0xFF607D8B),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String content, IconData icon, Color iconColor) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6A00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF6A00).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFFFF6A00),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}