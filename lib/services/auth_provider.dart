import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/menu_response.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  MenuResponse? _menuResponse;
  String? _originalToken;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  MenuResponse? get menuResponse => _menuResponse;
  String? get originalToken => _originalToken;
  bool get isLoading => _isLoading;

  // Login method
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    debugPrint('Starting login for email: $email');

    try {
      final apiService = ApiService();
      // Load existing cookies if any
      await apiService.loadCookies();
      final basicUser = await apiService.login(email, password);
      debugPrint('Basic login successful, token: ${basicUser.token}, user ID: ${basicUser.id}, user_name: ${basicUser.userName}');

      // Store original token before getting XSRF token
      _originalToken = basicUser.token;
      debugPrint('Original token from login: $_originalToken');

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
        orgType: basicUser.orgType,
        yearTitle: basicUser.yearTitle,
        token: userToken,
      );

      // Store original token separately for APIs that need it
      _originalToken = basicUser.token;
      debugPrint('=== SESSION DATA AT LOGIN ===');
      debugPrint('${_currentUser!.toJson()}');
      debugPrint('=== END SESSION DATA ===');
      // Fetch menu rights immediately after login
      try {
        debugPrint('Fetching menu rights for user: ${basicUser.subInstituteId}, profile: ${basicUser.userProfileId}');
        _menuResponse = await apiService.fetchMenuRights(_currentUser!, _originalToken ?? userToken);
        debugPrint('Menu rights fetched successfully, mobile menus: ${_menuResponse?.getMobileMenus().length ?? 0}');
      } catch (e) {
        debugPrint('Failed to fetch menu rights: $e');
        // Don't fail login if menu fetch fails
      }

      // Initialize notifications and update FCM token
      try {
        debugPrint('Initializing notification service and updating FCM token');
        final notificationService = NotificationService();
        await notificationService.initialize();
        await notificationService.updateTokenWithUser(_currentUser!.id.toString(), _originalToken ?? userToken);
        debugPrint('FCM token updated successfully at login');
      } catch (e) {
        debugPrint('Failed to initialize notifications or update FCM token: $e');
        // Don't fail login if notification setup fails
      }

      // Persist the finalized session user and menu response
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_currentUser!.toJson()));
      if (_originalToken != null) {
        await prefs.setString('original_token', _originalToken!);
        debugPrint('Saving original token to prefs');
      }
      if (_menuResponse != null) {
        final menuJson = _menuResponse!.toJson();
        debugPrint('Saving menu response to prefs: ${menuJson.length} keys');
        await prefs.setString('menu_response', jsonEncode(menuJson));
      } else {
        debugPrint('No menu response to save');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout method
  Future<void> logout() async {
    _currentUser = null;
    _menuResponse = null;
    _originalToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('menu_response');
    await prefs.remove('original_token');
    notifyListeners();
  }

  // Separate method to fetch menu rights (alternative approach)
  Future<void> fetchMenuRights() async {
    if (_currentUser == null) return;

    try {
      debugPrint('Fetching menu rights for current user');
      final apiService = ApiService();
      await apiService.loadCookies(); // Ensure cookies are loaded

      // Try original token first, fallback to JWT token
      final tokenToUse = _originalToken ?? _currentUser!.token;
      debugPrint('Available tokens - Original: $_originalToken, JWT: ${_currentUser!.token}');
      debugPrint('Using token: $tokenToUse');

      _menuResponse = await apiService.fetchMenuRights(_currentUser!, tokenToUse);

      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      if (_menuResponse != null) {
        await prefs.setString('menu_response', jsonEncode(_menuResponse!.toJson()));
      }

      notifyListeners();
      debugPrint('Menu rights updated successfully');
    } catch (e) {
      debugPrint('Failed to fetch menu rights: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount(String reason) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    debugPrint('Starting account deletion for user: ${_currentUser!.id}');

    final apiService = ApiService();
    await apiService.loadCookies();
    final tokenToUse = _originalToken ?? _currentUser!.token;

    // Clear all user data
    _currentUser = null;
    _menuResponse = null;
    _originalToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('menu_response');
    await prefs.remove('original_token');
    await prefs.remove('cookies');

    _isLoading = false;
    notifyListeners();
  }

  // Check session on app start
  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userMap = jsonDecode(userString) as Map<String, dynamic>;
      _currentUser = User.fromJson(userMap);

      // Load original token if available
      final originalTokenString = prefs.getString('original_token');
      if (originalTokenString != null) {
        _originalToken = originalTokenString;
        debugPrint('Original token loaded from prefs');
      }

      // Load menu response if available
      final menuString = prefs.getString('menu_response');
      if (menuString != null) {
        try {
          final menuMap = jsonDecode(menuString) as Map<String, dynamic>;
          _menuResponse = MenuResponse.fromJson(menuMap);
          debugPrint('Menu response loaded from prefs: ${menuMap.length} items');
        } catch (e) {
          debugPrint('Failed to load menu response from prefs: $e');
        }
      } else {
        debugPrint('No menu response found in shared preferences');
      }

      debugPrint('=== LOADED SESSION DATA ===');
      debugPrint('${_currentUser!.toJson()}');
      debugPrint('=== END LOADED SESSION DATA ===');
      notifyListeners();
    } else {
      debugPrint('No session data found in shared preferences');
    }
  }
}
