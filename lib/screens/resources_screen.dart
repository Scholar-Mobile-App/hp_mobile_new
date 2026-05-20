import 'package:flutter/material.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resources',
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
                'Company Resources',
                style: TextStyle(
                  color: Color(0xFF1F2A6D),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Access important documents, policies, and helpful information',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              _buildResourceSection(
                'HR Policies',
                [
                  _buildResourceItem('Employee Handbook', 'Complete guide to company policies and procedures', Icons.book),
                  _buildResourceItem('Code of Conduct', 'Ethical standards and business conduct guidelines', Icons.gavel),
                  _buildResourceItem('Leave Policy', 'Information about vacation, sick leave, and time off', Icons.calendar_today),
                  _buildResourceItem('Benefits Overview', 'Health, retirement, and other employee benefits', Icons.medical_services),
                ],
              ),
              const SizedBox(height: 24),
              _buildResourceSection(
                'IT & Security',
                [
                  _buildResourceItem('IT Help Desk', 'Get technical support and troubleshooting assistance', Icons.support),
                  _buildResourceItem('Security Guidelines', 'Best practices for data protection and cybersecurity', Icons.security),
                  _buildResourceItem('Remote Work Policy', 'Guidelines for working remotely and using company devices', Icons.home_work),
                  _buildResourceItem('Software Licenses', 'Access to company-approved software and tools', Icons.computer),
                ],
              ),
              const SizedBox(height: 24),
              _buildResourceSection(
                'Professional Development',
                [
                  _buildResourceItem('Career Development', 'Resources for career planning and advancement', Icons.trending_up),
                  _buildResourceItem('Mentorship Program', 'Connect with mentors and find mentees', Icons.people),
                  _buildResourceItem('Conference Reimbursements', 'Apply for conference and training reimbursement', Icons.school),
                  _buildResourceItem('Research Library', 'Access to industry research and whitepapers', Icons.library_books),
                ],
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
                      'Quick Links',
                      style: TextStyle(
                        color: Color(0xFF1F2A6D),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickLink('Company Directory', 'Find contact information for colleagues'),
                    _buildQuickLink('Internal Job Postings', 'View open positions within the company'),
                    _buildQuickLink('Expense Reimbursement', 'Submit expense reports online'),
                    _buildQuickLink('Facilities Booking', 'Reserve meeting rooms and equipment'),
                    _buildQuickLink('IT Service Portal', 'Request new equipment or software'),
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
                      'Emergency Contacts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildEmergencyContact('HR Emergency Hotline', '+1-800-HP-HELP'),
                    _buildEmergencyContact('IT Security Incident', 'security@hp.com'),
                    _buildEmergencyContact('Facilities Emergency', '+1-800-HP-FACILITY'),
                    _buildEmergencyContact('Employee Assistance Program', '+1-800-HP-SUPPORT'),
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
                      'Recent Updates',
                      style: TextStyle(
                        color: Color(0xFF1F2A6D),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildUpdate('New Benefits Package', 'Updated health and retirement benefits effective January 2025', 'Dec 15, 2024'),
                    _buildUpdate('Remote Work Policy Update', 'Revised guidelines for hybrid work arrangements', 'Nov 28, 2024'),
                    _buildUpdate('Diversity & Inclusion Initiative', 'New programs and resources for employee engagement', 'Nov 10, 2024'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceSection(String title, List<Widget> items) {
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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1F2A6D),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildResourceItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {},
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6A00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFF6A00),
                size: 20,
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
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
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
    );
  }

  Widget _buildQuickLink(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {},
        child: Row(
          children: [
            const Icon(
              Icons.link,
              color: Color(0xFFFF6A00),
              size: 16,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
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
      ),
    );
  }

  Widget _buildEmergencyContact(String title, String contact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(
            Icons.phone,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            contact,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdate(String title, String description, String date) {
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
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
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