import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/menu.dart';

class ApiService {
  static const String baseUrl = 'https://hp.triz.co.in/login';

  // Standard HTTP client
  http.Client get _httpClient {
    return http.Client();
  }

  // Store cookies from login response
  Map<String, String> _cookies = {};

  // Load cookies from shared preferences
  Future<void> loadCookies() async {
    debugPrint('Loading cookies from prefs');
    final prefs = await SharedPreferences.getInstance();
    final cookiesString = prefs.getString('cookies');
    debugPrint('Cookies string from prefs: $cookiesString');
    if (cookiesString != null) {
      _cookies = Map<String, String>.from(jsonDecode(cookiesString));
      debugPrint('Cookies loaded: $_cookies');
    } else {
      debugPrint('No cookies in prefs');
    }
  }

  // Extract cookies from response headers
  Future<void> _extractCookies(http.Response response) async {
    // Handle multiple set-cookie headers properly
    response.headers.forEach((key, value) {
      if (key.toLowerCase() == 'set-cookie') {
        // Parse the cookie string
        // Format: name=value; attributes...
        final parts = value.split(';');
        if (parts.isNotEmpty) {
          final cookiePart = parts[0].trim();
          final eqIndex = cookiePart.indexOf('=');
          if (eqIndex > 0) {
            final name = cookiePart.substring(0, eqIndex).trim();
            final cookieValue = cookiePart.substring(eqIndex + 1).trim();
            _cookies[name] = cookieValue;
            debugPrint('Extracted cookie: $name = $cookieValue');
          }
        }
      }
    });
    debugPrint('All extracted cookies: $_cookies');
    // Save cookies to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cookies', jsonEncode(_cookies));
    debugPrint('Cookies saved to prefs: $_cookies');
  }

  // Get cookie header string
  String _getCookieHeader() {
    debugPrint('Generating cookie header from _cookies: $_cookies');
    final header = _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    debugPrint('Generated cookie header: "$header"');
    return header;
  }

  // Get XSRF token
  String? getXsrfToken() {
    return _cookies['XSRF-TOKEN'];
  }



  // Login function
  Future<User> login(String email, String password) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'email': email,
        'password': password,
        'type': 'API',
      },
    );
    debugPrint('Making login GET request to: $uri');
    final response = await _httpClient.get(uri);

    if (response.statusCode == 200) {
      debugPrint('Login request successful');
      // Extract cookies from login response
      await _extractCookies(response);

      final data = json.decode(response.body);
      debugPrint('Response data: $data');
      if (data['status'] == 0) {
        throw Exception(data['message'] ?? 'Incorrect password or invalid credentials');
      }
      // Pass full response data to handle nested structures
      return User.fromLoginJson(data);
    } else {
      debugPrint('Login request failed with status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      throw Exception('Failed to login: ${response.statusCode}');
    }
  }

  // Fetch profile details
  Future<User> fetchProfile(String token) async {
    final url = 'https://hp.triz.co.in/api/user/profile?token=$token';
    debugPrint('Fetching profile from: $url');

    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };
    final response = await _httpClient.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      debugPrint('Profile fetch successful');
      final data = json.decode(response.body);
      debugPrint('Profile response data: $data');
      if (data['status_code'] == 1) {
        final profileData = data['data'];
        return User.fromProfileJson(profileData, token);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch profile');
      }
    } else {
      debugPrint('Profile fetch failed with status: ${response.statusCode}');
      debugPrint('Profile response body: ${response.body}');
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    }
  }

  // Fetch user edit details
  Future<Map<String, dynamic>> fetchUserEditDetails(String token, int userId, int subInstituteId, String orgType, String syear) async {
    final url = 'https://hp.triz.co.in/user/add_user/$userId/edit?type=API&token=$token&sub_institute_id=$subInstituteId&org_type=${Uri.encodeComponent(orgType)}&syear=$syear';
    debugPrint('Fetching user edit details from: $url');

    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };
    final response = await _httpClient.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      debugPrint('User edit details fetch successful');
      debugPrint('Response body: ${response.body}');
      return json.decode(response.body);
    } else {
      debugPrint('User edit details fetch failed with status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      throw Exception('Failed to fetch user edit details: ${response.statusCode}');
    }
  }


}
