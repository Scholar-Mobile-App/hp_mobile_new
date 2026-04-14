import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Login method
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    debugPrint('Starting login for email: $email');

    final apiService = ApiService();
    final basicUser = await apiService.login(email, password);
    debugPrint('Basic login successful, token: ${basicUser.token}, user ID: ${basicUser.id}, user_name: ${basicUser.userName}');

    // Get XSRF token from cookies
    final xsrfToken = apiService.getXsrfToken();
    final userToken = xsrfToken ?? basicUser.token;
    _currentUser = User(
      id: basicUser.id,
      userName: basicUser.userName,
      firstName: basicUser.firstName,
      middleName: basicUser.middleName,
      lastName: basicUser.lastName,
      fullName: basicUser.fullName,
      email: basicUser.email,
      mobile: basicUser.mobile,
      birthdate: basicUser.birthdate,
      address: basicUser.address,
      gender: basicUser.gender,
      joinYear: basicUser.joinYear,
      employeeNo: basicUser.employeeNo,
      employeeId: basicUser.employeeId,
      image: basicUser.image,
      userProfileId: basicUser.userProfileId,
      userProfileName: basicUser.userProfileName,
      subInstituteId: basicUser.subInstituteId,
      clientId: basicUser.clientId,
      isAdmin: basicUser.isAdmin,
      status: basicUser.status,
      departmentId: basicUser.departmentId,
      departmentName: basicUser.departmentName,
      jobroleId: basicUser.jobroleId,
      jobroleName: basicUser.jobroleName,
      jobLevel: basicUser.jobLevel,
      sequenceOrder: basicUser.sequenceOrder,
      hasVerticalProgression: basicUser.hasVerticalProgression,
      hasLateralMovement: basicUser.hasLateralMovement,
      progressionType: basicUser.progressionType,
      schoolName: basicUser.schoolName,
      schoolShortCode: basicUser.schoolShortCode,
      schoolLogo: basicUser.schoolLogo,
      syear: basicUser.syear,
      orgName: basicUser.orgName,
      yearTitle: basicUser.yearTitle,
      token: userToken,
    );
    debugPrint('=== SESSION DATA AT LOGIN ===');
    debugPrint('${_currentUser!.toJson()}');
    debugPrint('=== END SESSION DATA ===');
    // Persist the finalized session user
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(_currentUser!.toJson()));
    _isLoading = false;
    notifyListeners();
  }

  // Logout method
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }

  // Check session on app start
  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userMap = jsonDecode(userString) as Map<String, dynamic>;
      _currentUser = User.fromJson(userMap);
      debugPrint('=== LOADED SESSION DATA ===');
      debugPrint('${_currentUser!.toJson()}');
      debugPrint('=== END LOADED SESSION DATA ===');
      notifyListeners();
    } else {
      debugPrint('No session data found in shared preferences');
    }
  }
}
