import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../models/user_attitude.dart';
import '../../../services/auth_provider.dart';
import '../../../services/api_service.dart';
import 'attitude_detail_screen.dart';

class AttitudeScreen extends StatefulWidget {
  const AttitudeScreen({Key? key}) : super(key: key);

  @override
  _AttitudeScreenState createState() => _AttitudeScreenState();
}

class _AttitudeScreenState extends State<AttitudeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<UserAttitude> allAttitudes = [];
  List<UserAttitude> filteredAttitudes = [];

  @override
  void initState() {
    super.initState();
    _fetchAttitudes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAttitudes() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) throw Exception('No user available');
      final token = auth.originalToken ?? user.token;

      final data = await _apiService.fetchAttitudes(user, token);
      setState(() {
        allAttitudes = data.map((json) => UserAttitude.fromJson(json)).toList();
        filteredAttitudes = _applyFilters();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching attitudes: $e')),
      );
    }
  }

  List<UserAttitude> _applyFilters() {
    return allAttitudes.where((attitude) {
      bool matchesSearch = _searchQuery.isEmpty ||
          attitude.title?.toLowerCase().contains(_searchQuery) == true ||
          attitude.category?.toLowerCase().contains(_searchQuery) == true ||
          attitude.subCategory?.toLowerCase().contains(_searchQuery) == true ||
          attitude.description?.toLowerCase().contains(_searchQuery) == true;
      return matchesSearch;
    }).toList();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        filteredAttitudes = _applyFilters();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attitudes'),
        backgroundColor: Color(0xFF1F2A6D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search attitudes',
                prefixIcon: Icon(Icons.search, color: Color(0xFF1F2A6D)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFFF6A00), width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredAttitudes.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredAttitudes.length,
                    itemBuilder: (context, index) {
                      final attitude = filteredAttitudes[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Color(0xFFE8F4FD)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            leading: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFF1F2A6D).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.psychology,
                                color: Color(0xFF1F2A6D),
                                size: 28,
                              ),
                            ),
                            title: Text(
                              attitude.title ?? 'No Title',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF1F2A6D),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text(
                                      attitude.category ?? 'No Category',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text(
                                      attitude.subCategory ?? 'No Sub-Category',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                if (attitude.description != null && attitude.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      attitude.description!.length > 100
                                          ? '${attitude.description!.substring(0, 100)}...'
                                          : attitude.description!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFFFF6A00).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFFFF6A00),
                                size: 16,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AttitudeDetailScreen(attitude: attitude),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }


}

