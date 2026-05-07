import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/menu_response.dart';
import '../models/job_role_task.dart';
import '../models/job_role_task_table.dart';
import '../models/job_role_skill.dart';
import '../models/job_role_kaba.dart';
import '../models/user_knowledge.dart';
import '../models/user_ability.dart';
import '../models/user_behaviour.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => '${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}';

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
    final url = '${ApiConfig.baseUrl}${ApiConfig.profileEndpoint}?token=$token';
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

  // Fetch menu rights - use same auth as profile API
  Future<MenuResponse> fetchMenuRights(User user, String token) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.menuRightsEndpoint}?type=API&token=$token&sub_institute_id=${user.subInstituteId}&profile_id=${user.userProfileId}';

    debugPrint('Fetching menu rights with same auth as profile API: $url');

    // Use same headers as profile API
    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    debugPrint('Using same headers as profile API');

    final response = await _httpClient.get(Uri.parse(url), headers: headers);
    debugPrint('Menu rights response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      debugPrint('Menu rights fetch successful');
      final data = json.decode(response.body);
      debugPrint('Menu response data keys: ${data.keys.toList()}');
      final menuResponse = MenuResponse.fromJson(data);
      final mobileMenus = menuResponse.getMobileMenus();
      debugPrint('Parsed ${mobileMenus.length} mobile menus from API');
      return menuResponse;
    } else {
      debugPrint('Menu rights fetch failed: ${response.body}');
      throw Exception('Failed to fetch menu rights: ${response.statusCode}');
    }
  }

  // Fetch skill library
  Future<List<dynamic>> fetchSkillLibrary(User user, String token) async {
    final url = 'https://hp.triz.co.in/skill_library?type=API&token=$token&sub_institute_id=${user.subInstituteId}&org_type=${Uri.encodeComponent(user.orgType)}&category=&sub_category=';

    debugPrint('Fetching skill library from: $url');

    // No headers needed for this API, based on the sample
    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      debugPrint('Skill library fetch successful');
      final data = json.decode(response.body);
      debugPrint('Skill library response data keys: ${data.keys.toList()}');
      final userSkills = data['userSkills'] as List<dynamic>;
      return userSkills;
    } else {
      debugPrint('Skill library fetch failed: ${response.body}');
      throw Exception('Failed to fetch skill library: ${response.statusCode}');
    }
  }

  // Fetch skill details
  Future<Map<String, dynamic>> fetchSkillDetails(int skillId, User user, String token) async {
    final url = 'https://hp.triz.co.in/skill_library/$skillId/edit?type=API&token=$token&sub_institute_id=${user.subInstituteId}&org_type=${Uri.encodeComponent(user.orgType)}&formType=user';

    debugPrint('Fetching skill details from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      debugPrint('Skill details fetch successful');
      final data = json.decode(response.body);
      debugPrint('Skill details response data keys: ${data.keys.toList()}');
      return data;
    } else {
      debugPrint('Skill details fetch failed: ${response.body}');
      throw Exception('Failed to fetch skill details: ${response.statusCode}');
    }
  }

  // Fetch job roles
  Future<List<dynamic>> fetchJobRoles(User user, String token) async {
    final url = 'https://hp.triz.co.in/table_data?table=s_user_jobrole&filters[sub_institute_id]=${user.subInstituteId}';

    debugPrint('Fetching job roles from: $url');

    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };
    final response = await _httpClient.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      debugPrint('Job roles fetch successful');
      final data = json.decode(response.body) as List<dynamic>;
      return data;
    } else {
      debugPrint('Job roles fetch failed: ${response.body}');
      throw Exception('Failed to fetch job roles: ${response.statusCode}');
    }
  }

  // Fetch job roles by department
  Future<Map<String, dynamic>> fetchJobRolesByDepartment(User user, String token) async {
    final url = 'https://hp.triz.co.in/api/jobroles-by-department?sub_institute_id=${user.subInstituteId}';

    debugPrint('Fetching job roles by department from: $url');

    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };
    final response = await _httpClient.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      debugPrint('Job roles by department fetch successful');
      final data = json.decode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      debugPrint('Job roles by department fetch failed: ${response.body}');
      throw Exception('Failed to fetch job roles by department: ${response.statusCode}');
    }
  }

  // Fetch attitudes
  Future<List<dynamic>> fetchAttitudes(User user, String token) async {
    final url = 'https://hp.triz.co.in/table_data?table=s_user_attitude&filters[sub_institute_id]=${user.subInstituteId}&order_by[id]=desc';

    debugPrint('Fetching attitudes from: $url');

    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };
    final response = await _httpClient.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      debugPrint('Attitudes fetch successful');
      final data = json.decode(response.body) as List<dynamic>;
      return data;
    } else {
      debugPrint('Attitudes fetch failed: ${response.body}');
      throw Exception('Failed to fetch attitudes: ${response.statusCode}');
    }
  }

  // Fetch job role tasks
  Future<List<JobRoleTask>> fetchJobRoleTasks(User user, String token, String jobRole, int jobRoleId) async {
    final url = 'https://hp.triz.co.in/jobrole_library/create?type=API&token=$token&sub_institute_id=${user.subInstituteId}&org_type=${Uri.encodeComponent(user.orgType)}&jobrole=${Uri.encodeComponent(jobRole)}&formType=tasks';

    debugPrint('Fetching job role tasks from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      debugPrint('Job role tasks fetch successful');
      final data = json.decode(response.body);
      final tasks = data['usertaskData'] as List<dynamic>;
      return tasks.map((task) => JobRoleTask.fromJson(task)).toList();
    } else {
      debugPrint('Job role tasks fetch failed: ${response.body}');
      throw Exception('Failed to fetch job role tasks: ${response.statusCode}');
    }
  }

  // Fetch job role KABA (Knowledge, Attitude, Behavior, Abilities)
  Future<JobRoleKABA> fetchJobRoleKABA(User user, int jobRoleId) async {
    final url = 'https://hp.triz.co.in/get-kaba?sub_institute_id=${user.subInstituteId}&type=jobrole&type_id=$jobRoleId';

    debugPrint('Fetching job role KABA from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      debugPrint('Job role KABA fetch successful');
      return JobRoleKABA.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } else {
      debugPrint('Job role KABA fetch failed: ${response.body}');
      throw Exception('Failed to fetch job role KABA: ${response.statusCode}');
    }
  }

  // Fetch job role skills
  Future<List<JobRoleSkill>> fetchJobRoleSkills(User user, String token, String jobRole) async {
    final url = 'https://hp.triz.co.in/jobrole_library/create?type=API&token=$token&sub_institute_id=${user.subInstituteId}&org_type=${Uri.encodeComponent(user.orgType)}&jobrole=${Uri.encodeComponent(jobRole)}&formType=skills';

    debugPrint('Fetching job role skills from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      debugPrint('Job role skills fetch successful');
      final data = json.decode(response.body);
      final skills = data['userskillData'] as List<dynamic>;
      return skills.map((skill) => JobRoleSkill.fromJson(skill)).toList();
    } else {
      debugPrint('Job role skills fetch failed: ${response.body}');
      throw Exception('Failed to fetch job role skills: ${response.statusCode}');
    }
  }

  // Fetch job role tasks from table_data endpoint
  Future<List<JobRoleTaskTable>> fetchJobRoleTasksTable(User user, String sector, {String orderDirection = 'desc'}) async {
    final url = 'https://hp.triz.co.in/table_data?table=s_user_jobrole_task&filters[sub_institute_id]=${user.subInstituteId}&filters[sector]=$sector&order_by[direction]=$orderDirection';

    debugPrint('ApiService: Fetching job role tasks table from: $url');
    debugPrint('ApiService: User sub_institute_id: ${user.subInstituteId}, sector: $sector');

    final response = await _httpClient.get(Uri.parse(url));

    debugPrint('ApiService: Response status code: ${response.statusCode}');
    if (response.statusCode == 200) {
      debugPrint('ApiService: Job role tasks table fetch successful');
      final data = json.decode(response.body) as List<dynamic>;
      debugPrint('ApiService: Received ${data.length} task records');
      if (data.isNotEmpty) {
        debugPrint('ApiService: Sample task data: ${data.first}');
      }
      return data.map((task) => JobRoleTaskTable.fromJson(task)).toList();
    } else {
      debugPrint('ApiService: Job role tasks table fetch failed: ${response.body}');
      throw Exception('Failed to fetch job role tasks table: ${response.statusCode}');
    }
  }

  // Fetch user knowledge
  Future<List<UserKnowledge>> fetchUserKnowledge(User user, String token) async {
    final url = 'https://hp.triz.co.in/table_data?filters[sub_institute_id]=${user.subInstituteId}&table=s_user_knowledge&type=API&token=$token';

    debugPrint('Fetching user knowledge from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      debugPrint('User knowledge fetch successful');
      final data = json.decode(response.body) as List<dynamic>;
      debugPrint('Received ${data.length} knowledge records');
      if (data.isNotEmpty) {
        debugPrint('Sample knowledge data: ${data.first}');
      }
      return data.map((item) => UserKnowledge.fromJson(item)).toList();
    } else {
      debugPrint('User knowledge fetch failed: ${response.body}');
      throw Exception('Failed to fetch user knowledge: ${response.statusCode}');
    }
  }

  // Fetch user ability
  Future<List<UserAbility>> fetchUserAbility(User user, String token) async {
    final url = 'https://hp.triz.co.in/table_data?filters[sub_institute_id]=${user.subInstituteId}&table=s_user_ability&order_by[id]=desc&type=API&token=$token';

    debugPrint('Fetching user ability from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      debugPrint('User ability fetch successful');
      final data = json.decode(response.body) as List<dynamic>;
      debugPrint('Received ${data.length} ability records');
      if (data.isNotEmpty) {
        debugPrint('Sample ability data: ${data.first}');
      }
      return data.map((item) => UserAbility.fromJson(item)).toList();
    } else {
      debugPrint('User ability fetch failed: ${response.body}');
      throw Exception('Failed to fetch user ability: ${response.statusCode}');
    }
  }

  // Fetch user behaviour
  Future<List<UserBehaviour>> fetchUserBehaviour(User user, String token) async {
    final url = 'https://hp.triz.co.in/table_data?filters[sub_institute_id]=${user.subInstituteId}&table=s_user_behaviour&type=API&token=$token';

    debugPrint('Fetching user behaviour from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      debugPrint('User behaviour fetch successful');
      final data = json.decode(response.body) as List<dynamic>;
      debugPrint('Received ${data.length} behaviour records');
      if (data.isNotEmpty) {
        debugPrint('Sample behaviour data: ${data.first}');
      }
      return data.map((item) => UserBehaviour.fromJson(item)).toList();
    } else {
      debugPrint('User behaviour fetch failed: ${response.body}');
      throw Exception('Failed to fetch user behaviour: ${response.statusCode}');
    }
  }

  // Punch In API
  Future<Map<String, dynamic>> punchIn(User user, String token) async {
    final url = 'https://hp.triz.co.in/hrms-in-time/store';

    final now = DateTime.now();
    final outdate = DateFormat('yyyy-MM-dd').format(now);
    final punchinTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final payload = {
      'type': 'API',
      'token': token,
      'user_id': user.id.toString(),
      'client_id': '0',
      'sub_institute_id': user.subInstituteId.toString(),
      'outdate': outdate,
      'punchin_time': punchinTime,
      'address_in': '127.0.0.1', // Placeholder IP, can be replaced with actual IP fetching
    };

    debugPrint('Punching in with payload: $payload');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(payload),
    );

    debugPrint('Punch in response status: ${response.statusCode}');
    debugPrint('Punch in response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Punch in response: $data');
      if (data['status'] == '0') {
        // Handle already punched in
        throw Exception(data['message'] ?? 'Already punched in');
      }
      debugPrint('Punch in successful: $data');
      return data;
    } else {
      debugPrint('Punch in failed: ${response.body}');
      throw Exception('Failed to punch in: ${response.statusCode}');
    }
  }

  // Punch Out API
  Future<Map<String, dynamic>> punchOut(User user, String token) async {
    final url = 'https://hp.triz.co.in/hrms-out-time/store';

    final now = DateTime.now();
    final outdate = DateFormat('yyyy-MM-dd').format(now);
    final punchoutTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final payload = {
      'type': 'API',
      'token': token,
      'user_id': user.id.toString(),
      'client_id': '0',
      'sub_institute_id': user.subInstituteId.toString(),
      'outdate': outdate,
      'punchout_time': punchoutTime,
      'address_out': '127.0.0.1', // Placeholder IP, can be replaced with actual IP fetching
    };

    debugPrint('Punching out with payload: $payload');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(payload),
    );

    debugPrint('Punch out response status: ${response.statusCode}');
    debugPrint('Punch out response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Punch out response: $data');
      if (data['status'] == '0') {
        // Handle not punched in or other errors
        throw Exception(data['message'] ?? 'Cannot punch out');
      }
      debugPrint('Punch out successful: $data');
      return data;
    } else {
      debugPrint('Punch out failed: ${response.body}');
      throw Exception('Failed to punch out: ${response.statusCode}');
    }
  }

  // Fetch Attendance Data
  Future<Map<String, dynamic>> fetchAttendance(User user, String token) async {
    final url = 'https://hp.triz.co.in/hrms-attendance?type=API&token=$token&sub_institute_id=${user.subInstituteId}&user_id=${user.id}&formType=MyAttendance';

    debugPrint('Fetching attendance from: $url');

    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.get(Uri.parse(url), headers: headers);

    debugPrint('Attendance fetch response status: ${response.statusCode}');
    debugPrint('Attendance fetch response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Attendance fetch successful: $data');
      return data;
    } else {
      debugPrint('Attendance fetch failed: ${response.body}');
      throw Exception('Failed to fetch attendance: ${response.statusCode}');
    }
  }
}
