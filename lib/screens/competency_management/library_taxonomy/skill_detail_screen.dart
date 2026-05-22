import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../services/api_service.dart';

class SkillDetailScreen extends StatefulWidget {
  final int skillId;
  final String skillTitle;

  const SkillDetailScreen({
    super.key,
    required this.skillId,
    required this.skillTitle,
  });

  @override
  _SkillDetailScreenState createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? skillData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchSkillDetails();
  }

  Future<void> _fetchSkillDetails() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) throw Exception('No user available');
      final token = auth.originalToken ?? user.token;

      final data = await _apiService.fetchSkillDetails(widget.skillId, user, token);
      setState(() {
        skillData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.skillTitle,
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text('Error: $error'))
                : skillData == null
                    ? const Center(child: Text('No data available'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBasicInfo(),
                            const SizedBox(height: 24),
                            _buildJobRoles(),
                            const SizedBox(height: 24),
                            _buildDetailedInfo(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    final editData = skillData!['editData'];
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
                const Icon(Icons.build, color: Color(0xFFFF6A00), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    editData['title'] ?? 'No Title',
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
              editData['description'] ?? 'No Description',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Department', editData['department']),
            _buildInfoRow('Category', editData['category']),
            _buildInfoRow('Sub Category', editData['sub_category']),
            _buildInfoRow('Proficiency Level', editData['proficiency_level']),
            _buildInfoRow('Skill Status', editData['skill_status']),
            _buildInfoRow('Skill Importance', editData['skill_importance']),
          ],
        ),
      ),
    );
  }

  Widget _buildJobRoles() {
    final jobRoles = skillData!['userJobroleData'] as List<dynamic>;
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
                Icon(Icons.work, color: Color(0xFFFF6A00), size: 28),
                SizedBox(width: 12),
                Text(
                  'Associated Job Roles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2A6D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: jobRoles.length,
              itemBuilder: (context, index) {
                return _buildJobRoleItem(jobRoles[index], index == jobRoles.length - 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobRoleItem(dynamic role, bool isLast) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6A00).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF6A00).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.work_outline,
            color: Color(0xFFFF6A00),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role['jobrole'] ?? 'No Job Role',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2A6D),
                  ),
                ),
                const SizedBox(height: 6),
                _buildRoleDetailRow('Sector', role['sector']),
                const SizedBox(height: 2),
                _buildRoleDetailRow('Track', role['track']),
                const SizedBox(height: 2),
                _buildRoleDetailRow('Proficiency Level', role['proficiency_level']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedInfo() {
    final editData = skillData!['editData'];
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
                  'Additional Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2A6D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailSection('Related Skills', editData['related_skills']),
            _buildDetailSection('Custom Tags', editData['custom_tags']),
            _buildDetailSection('Learning Resources', editData['learning_resources']),
            _buildDetailSection('Assessment Method', editData['assesment_method']),
            _buildDetailSection('Certification Qualifications', editData['certification_qualifications']),
            _buildDetailSection('Experience Project', editData['experience_project']),
            _buildDetailSection('SOP Practice Link', editData['sop_practice_link']),
            _buildDetailSection('Performance Metrics', editData['performance_metrics']),
            _buildDetailSection('Common Errors Tips', editData['common_errors_tips']),
            _buildDetailSection('SME Contacts', editData['sme_contacts']),
            _buildDetailSection('Sub Skills', editData['sub_skills']),
            _buildDetailSection('Skill Flow', editData['skill_flow']),
            _buildDetailSection('Task List', editData['tasklist']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String? content) {
    if (content == null || content.isEmpty || content == 'null') return const SizedBox.shrink();

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
            _formatContent(content),
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

  String _formatContent(String content) {
    // Remove brackets and quotes for display
    return content.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty || value == 'null') return const SizedBox.shrink();

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