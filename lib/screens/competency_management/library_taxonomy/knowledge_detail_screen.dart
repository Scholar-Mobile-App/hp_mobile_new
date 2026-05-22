import 'package:flutter/material.dart';
import '../../../models/user_knowledge.dart';

class KnowledgeDetailScreen extends StatelessWidget {
  final UserKnowledge knowledge;

  const KnowledgeDetailScreen({super.key, required this.knowledge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          knowledge.title ?? 'Knowledge Details',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildAssessmentInfo(),
              const SizedBox(height: 24),
              _buildAdditionalDetails(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: Color(0xFFFF6A00), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    knowledge.title ?? 'No Title',
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
            if (knowledge.description != null && knowledge.description!.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2A6D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                knowledge.description!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildInfoRow('Category', knowledge.category),
            _buildInfoRow('Sub-Category', knowledge.subCategory),
            _buildInfoRow('Complexity Level', knowledge.complexityLevel),
            _buildInfoRow('Proficiency Expectation', knowledge.proficiencyExpectation),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentInfo() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, color: Color(0xFFFF6A00), size: 28),
                SizedBox(width: 12),
                Text(
                  'Assessment & Evaluation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2A6D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailSection('Assessment Method', knowledge.assessmentMethod),
            _buildDetailSection('Knowledge Tags', knowledge.knowledgeTags),
            _buildDetailSection('Key Concepts', knowledge.keyConcepts),
            _buildDetailSection('References', knowledge.references),
            _buildDetailSection('Certification Options', knowledge.certificationOptions),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalDetails() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Color(0xFFFF6A00), size: 28),
                SizedBox(width: 12),
                Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2A6D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailSection('Theoretical Foundation', knowledge.theoreticalFoundation),
            _buildDetailSection('Business Link', knowledge.businessLink),
            _buildDetailSection('Compliance Relevance', knowledge.complianceRelevance),
            _buildDetailSection('Created At', knowledge.createdAt),
            if (knowledge.updatedAt != null)
              _buildDetailSection('Updated At', knowledge.updatedAt!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2A6D),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6A00).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFF6A00).withOpacity(0.3)),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2A6D),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}