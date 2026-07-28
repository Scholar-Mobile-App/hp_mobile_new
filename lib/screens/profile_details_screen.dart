import 'package:flutter/material.dart';
import '../widgets/network_avatar.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  _ProfileDetailsScreenState createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  Map<String, dynamic>? _userDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'No user logged in';
      });
      return;
    }

    try {
      final apiService = ApiService();
      await apiService.loadCookies();
      final details = await apiService.fetchUserEditDetails(
        user.token,
        user.id,
        user.subInstituteId,
        user.orgName, // assuming orgType is orgName
        user.syear,
      );
      setState(() {
        _userDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile Details'),
          backgroundColor: const Color(0xFF1F2A6D),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _userDetails == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile Details'),
          backgroundColor: const Color(0xFF1F2A6D),
        ),
        body: Center(child: Text(_error ?? 'Failed to load profile details')),
      );
    }

    final responseData = _userDetails!['data'] ?? _userDetails!;
    final userData = responseData['user'] ?? responseData;
    debugPrint('Details userData image: ${userData['image']}');
    final skills = responseData['skills'] as List<dynamic>? ?? [];
    final departments = responseData['departments'] as List<dynamic>? ?? [];
    final employees = responseData['employees'] as List<dynamic>? ?? [];
    final jobRoles = responseData['job_roles'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile Details',
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
            colors: [
              const Color(0xFF1F2A6D).withOpacity(0.1),
              const Color(0xFF2E3A8C).withOpacity(0.05)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NetworkAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF1F2A6D),
                iconColor: Colors.white,
                image: userData['image']?.toString() ?? '',
              ),
              const SizedBox(height: 20),
              Text(
                '${userData['first_name'] ?? ''} ${userData['middle_name'] ?? ''} ${userData['last_name'] ?? ''}'
                    .trim(),
                style: const TextStyle(
                  color: Color(0xFF1F2A6D),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                userData['email'] ?? '',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
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
                    _buildDetailRow(
                        'Phone', userData['mobile']?.toString() ?? ''),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Email', userData['email']?.toString() ?? ''),
                    const SizedBox(height: 12),
                    _buildDetailRow('Qualification',
                        userData['qualification']?.toString() ?? ''),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Occupation', userData['occupation']?.toString() ?? ''),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Gender', userData['gender']?.toString() ?? ''),
                    const SizedBox(height: 12),
                    _buildDetailRow('Date of Birth',
                        userData['birthdate']?.toString() ?? ''),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Address', userData['address']?.toString() ?? ''),
                    const SizedBox(height: 12),
                    _buildDetailRow('City', userData['city']?.toString() ?? ''),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'State', userData['state']?.toString() ?? ''),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Zip Code', userData['pincode']?.toString() ?? ''),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Job Role', userData['userJobrole']?.toString() ?? ''),
                    const SizedBox(height: 12),
                    _buildDetailRow('Department',
                        userData['userDepartment']?.toString() ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (skills.isNotEmpty) _buildListSection('Skills', skills),
              if (departments.isNotEmpty)
                _buildListSection('Departments', departments),
              if (jobRoles.isNotEmpty) _buildListSection('Job Roles', jobRoles),
              if (employees.isNotEmpty)
                _buildListSection('Employees', employees),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Color(0xFF1F2A6D),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(String title, List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2A6D),
          ),
        ),
        children: items
            .map((item) => ListTile(
                  title: Text(item['name']?.toString() ?? ''),
                ))
            .toList(),
      ),
    );
  }
}
