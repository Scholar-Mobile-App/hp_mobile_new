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
import '../models/task.dart';
import '../models/lms/assessment_model.dart';
import '../config/api_config.dart';

class OrgSectionForSubmit {
  final String legalName;
  final String cin;
  final String gstin;
  final String pan;
  final String registeredAddress;
  final String mobileNo;
  final String countryCode;
  final String email;
  final String website;
  final String? industry;
  final String? employeeCount;
  final String workWeek;
  final String? logoUrl;

  OrgSectionForSubmit({
    required this.legalName,
    required this.cin,
    required this.gstin,
    required this.pan,
    required this.registeredAddress,
    required this.mobileNo,
    required this.countryCode,
    required this.email,
    required this.website,
    this.industry,
    this.employeeCount,
    required this.workWeek,
    this.logoUrl,
  });
}

class ApiService {
  ApiService();

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

  // Fetch organization data
  Future<Map<String, dynamic>> fetchOrganizationData(int subInstituteId, String token) async {
    final url = 'https://hp.triz.co.in/settings/organization_data?type=API&sub_institute_id=$subInstituteId&token=$token';

    debugPrint('Fetching organization data from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      debugPrint('Organization data fetch successful');
      return json.decode(response.body);
    } else {
      debugPrint('Organization data fetch failed: ${response.body}');
      throw Exception('Failed to fetch organization data: ${response.statusCode}');
    }
  }

  // Submit organization data (POST)
  Future<Map<String, dynamic>> submitOrganizationData({
    required int subInstituteId,
    required String token,
    required List<OrgSectionForSubmit> organizations,
  }) async {
    const url = 'https://hp.triz.co.in/settings/organization_data';

    final Map<String, String> body = {
      'type': 'API',
      'formType': 'org_data',
      'sub_institute_id': subInstituteId.toString(),
      'token': token,
    };

    // Main organization (first one)
    if (organizations.isNotEmpty) {
      final main = organizations[0];
      body['legal_name'] = main.legalName;
      body['cin'] = main.cin;
      body['gstin'] = main.gstin;
      body['pan'] = main.pan;
      body['registered_address'] = main.registeredAddress;
      body['mobile_no'] = main.mobileNo;
      body['country_code'] = main.countryCode;
      body['email'] = main.email;
      body['website'] = main.website;
      body['industry'] = main.industry ?? '';
      body['employee_count'] = main.employeeCount ?? '';
      body['work_week'] = main.workWeek;
      body['logo_url'] = main.logoUrl ?? '';
    }

    // Sister companies
    for (int i = 1; i < organizations.length; i++) {
      final sister = organizations[i];
      final prefix = 'sister_companies[$i][legal_name]';
      body['sister_companies[$i][legal_name]'] = sister.legalName;
      body['sister_companies[$i][cin]'] = sister.cin;
      body['sister_companies[$i][gstin]'] = sister.gstin;
      body['sister_companies[$i][pan]'] = sister.pan;
      body['sister_companies[$i][registered_address]'] = sister.registeredAddress;
      body['sister_companies[$i][mobile_no]'] = sister.mobileNo;
      body['sister_companies[$i][country_code]'] = sister.countryCode;
      body['sister_companies[$i][email]'] = sister.email;
      body['sister_companies[$i][website]'] = sister.website;
      body['sister_companies[$i][industry]'] = sister.industry ?? '';
      body['sister_companies[$i][employee_count]'] = sister.employeeCount ?? '';
      body['sister_companies[$i][work_week]'] = sister.workWeek;
    }

    debugPrint('Submitting organization data to: $url');

    final response = await _httpClient.post(
      Uri.parse(url),
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('Organization data submitted successfully');
      return json.decode(response.body);
    } else {
      debugPrint('Organization submit failed: ${response.body}');
      throw Exception('Failed to submit organization data: ${response.statusCode}');
    }
  }

  // Fetch job roles by department (original)
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

  // Fetch departments
  Future<List<String>> fetchDepartments(User user, String token) async {
    final data = await fetchJobRolesByDepartment(user, token);
    return data.keys.toList();
  }

  // Fetch department management data (main + sub departments)
  Future<Map<String, dynamic>> fetchDepartmentManagement(User user, String token) async {
    final url = 'https://hp.triz.co.in/api/departments-management?type=api&token=$token&sub_institute_id=${user.subInstituteId}';
    debugPrint('Fetching department management from: $url');

    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };
    final response = await _httpClient.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      debugPrint('Department management fetch successful');
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      debugPrint('Department management fetch failed: ${response.body}');
      throw Exception('Failed to fetch department management: ${response.statusCode}');
    }
  }

  // Add new department
  Future<void> addDepartment({
    required int subInstituteId,
    required String token,
    required int userId,
    required String department,
  }) async {
    const url = 'https://hp.triz.co.in/hrms/add_department';
    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'type': 'API',
      'sub_institute_id': subInstituteId,
      'token': token,
      'formType': 'add department',
      'user_id': userId,
      'department': department,
    });

    debugPrint('Adding department to: $url');
    final response = await _httpClient.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      debugPrint('Add department successful');
    } else {
      debugPrint('Add department failed: ${response.body}');
      throw Exception('Failed to add department: ${response.statusCode}');
    }
  }

  // Add sub department
  Future<void> addSubDepartment({
    required int subInstituteId,
    required String token,
    required int userId,
    required String department,
    required int parentId,
  }) async {
    const url = 'https://hp.triz.co.in/api/departments-management';
    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'type': 'api',
      'token': token,
      'sub_institute_id': subInstituteId,
      'department': department,
      'parent_id': parentId,
      'user_id': userId,
      'formType': 'add sub_department',
    });

    debugPrint('Adding sub-department to: $url');
    final response = await _httpClient.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      debugPrint('Add sub-department successful');
    } else {
      debugPrint('Add sub-department failed: ${response.body}');
      throw Exception('Failed to add sub-department: ${response.statusCode}');
    }
  }

  // Edit sub department
  Future<void> editSubDepartment({
    required int subInstituteId,
    required String token,
    required int userId,
    required String parentDepartmentName,
    required String oldSubDepartment,
    required String newSubDepartment,
  }) async {
    const url = 'https://hp.triz.co.in/hrms/add_department';
    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'type': 'API',
      'sub_institute_id': subInstituteId,
      'token': token,
      'user_id': userId,
      'department': parentDepartmentName,
      'old_sub_department': oldSubDepartment,
      'sub_department': newSubDepartment,
      'formType': 'edit sub_department',
    });

    debugPrint('Editing sub-department to: $url');
    final response = await _httpClient.post(Uri.parse(url), headers: headers, body: body);

    debugPrint('Edit sub-department response: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == '1' || data['status'] == 1) {
        debugPrint('Edit sub-department successful');
      } else {
        throw Exception(data['message'] ?? 'Failed to edit sub-department');
      }
    } else {
      debugPrint('Edit sub-department failed: ${response.body}');
      throw Exception('Failed to edit sub-department: ${response.statusCode}');
    }
  }

  // Fetch job roles by department name
  Future<List<dynamic>> fetchJobRolesByDepartmentName(User user, String token, String department) async {
    final data = await fetchJobRolesByDepartment(user, token);
    if (data[department] != null) {
      return data[department] as List<dynamic>;
    } else {
      return [];
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
  Future<List<JobRoleTaskTable>> fetchJobRoleTasksTable(User user, {String? sector, String? jobrole, String orderDirection = 'desc'}) async {
    String url = 'https://hp.triz.co.in/table_data?table=s_user_jobrole_task&filters[sub_institute_id]=${user.subInstituteId}';
    if (sector != null) {
      url += '&filters[sector]=${Uri.encodeComponent(sector)}';
    }
    if (jobrole != null) {
      url += '&filters[jobrole]=${Uri.encodeComponent(jobrole)}';
    }
    url += '&order_by[direction]=$orderDirection';

    debugPrint('ApiService: Fetching job role tasks table from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    debugPrint('ApiService: Response status code: ${response.statusCode}');
    if (response.statusCode == 200) {
      debugPrint('ApiService: Job role tasks table fetch successful');
      final data = json.decode(response.body) as List<dynamic>;
      debugPrint('ApiService: Received ${data.length} task records');
      if (data.isNotEmpty) {
        debugPrint('ApiService: Sample task data: ${data.first}');
      }
      return data.map((json) => JobRoleTaskTable.fromJson(json)).toList();
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
    const url = 'https://hp.triz.co.in/hrms-in-time/store';

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
    const url = 'https://hp.triz.co.in/hrms-out-time/store';

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

  // Fetch Employee Attendance Monthly Report
  Future<Map<String, dynamic>> fetchEmployeeAttendanceMonthlyReport({
    required int userId,
    required int subInstituteId,
    required String token,
    required String month,
  }) async {
    final uri = Uri.parse('https://hp.triz.co.in/api/employee-attendance-monthly-report').replace(
      queryParameters: {
        'sub_institute_id': subInstituteId.toString(),
        'user_id': userId.toString(),
        'month': month,
        'type': 'API',
        'token': token,
      },
    );

    debugPrint('Fetching employee attendance monthly report from: $uri');

    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.get(uri, headers: headers);

    debugPrint('Monthly attendance report status: ${response.statusCode}');
    debugPrint('Monthly attendance report body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Employee attendance monthly report fetch successful');
      return data;
    } else {
      debugPrint('Employee attendance monthly report failed: ${response.body}');
      throw Exception('Failed to fetch attendance report: ${response.statusCode}');
    }
  }

  // Fetch user skills
  Future<List<Map<String, dynamic>>> fetchUserSkills(User user, String token) async {
    final url = 'https://hp.triz.co.in/api/user-skills/${user.id}?type=API&token=$token&sub_institute_id=${user.subInstituteId}';

    debugPrint('Fetching user skills from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      debugPrint('User skills fetch successful');
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      debugPrint('User skills fetch failed: ${response.body}');
      throw Exception('Failed to fetch user skills: ${response.statusCode}');
    }
  }

  // Fetch user skills by user ID
  Future<List<Map<String, dynamic>>> fetchUserSkillsById(int userId, String token, User currentUser) async {
    final url = 'https://hp.triz.co.in/api/user-skills/$userId?type=API&token=$token&sub_institute_id=${currentUser.subInstituteId}';

    debugPrint('Fetching user skills for ID $userId from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      debugPrint('User skills fetch successful for ID $userId');
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      debugPrint('User skills fetch failed for ID $userId: ${response.body}');
      throw Exception('Failed to fetch user skills: ${response.statusCode}');
    }
  }

  // Fetch Skill Development Progress (for My Learning Dashboard)
  Future<Map<String, dynamic>> fetchSkillDevelopmentProgress(User user, String token) async {
    final url = 'https://hp.triz.co.in/api/skill-development/progress?type=API&token=$token&sub_institute_id=${user.subInstituteId}&user_id=${user.id}';

    debugPrint('Fetching skill development progress from: $url');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.get(Uri.parse(url), headers: headers);

    debugPrint('Skill progress response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Skill progress fetch successful');
      return Map<String, dynamic>.from(data);
    } else {
      debugPrint('Skill progress fetch failed: ${response.body}');
      throw Exception('Failed to fetch skill development progress: ${response.statusCode}');
    }
  }

  // Fetch Skill Development Calendar (for My Learning Dashboard)
  Future<Map<String, dynamic>> fetchSkillDevelopmentCalendar(User user, String token, {String? month, String? year}) async {
    final now = DateTime.now();
    final m = month ?? now.month.toString().padLeft(2, '0');
    final y = year ?? now.year.toString();

    final url = 'https://hp.triz.co.in/api/skill-development/calendar?type=API&token=$token&sub_institute_id=${user.subInstituteId}&user_id=${user.id}&month=$m&year=$y';

    debugPrint('Fetching skill development calendar from: $url');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.get(Uri.parse(url), headers: headers);

    debugPrint('Skill calendar response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Skill calendar fetch successful');
      return Map<String, dynamic>.from(data);
    } else {
      debugPrint('Skill calendar fetch failed: ${response.body}');
      throw Exception('Failed to fetch skill development calendar: ${response.statusCode}');
    }
  }

  // Fetch Enrolled Courses (dedicated endpoint for My Learning Dashboard)
  Future<List<dynamic>> fetchEnrolledCourses(User user, String token) async {
    final url = 'https://hp.triz.co.in/api/enrolled_courses?user_id=${user.id}&type=API&token=$token&sub_institute_id=${user.subInstituteId}';

    debugPrint('Fetching enrolled courses from: $url');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.get(Uri.parse(url), headers: headers);

    debugPrint('Enrolled courses response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      debugPrint('Enrolled courses fetch successful');

      if (responseData['data'] is List) {
        return List<dynamic>.from(responseData['data']);
      } else if (responseData is List) {
        return responseData;
      } else {
        return [];
      }
    } else {
      debugPrint('Enrolled courses fetch failed: ${response.body}');
      throw Exception('Failed to fetch enrolled courses: ${response.statusCode}');
    }
  }

  // Fetch supervisor
  Future<Map<String, dynamic>> fetchSupervisor(int userId, int subInstituteId) async {
    final url = 'https://hp.triz.co.in/getSupervisor?user_id=$userId&sub_institute_id=$subInstituteId';

    debugPrint('Fetching supervisor for user ID $userId from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      debugPrint('Supervisor fetch successful');
      final data = json.decode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      debugPrint('Supervisor fetch failed: ${response.body}');
      throw Exception('Failed to fetch supervisor: ${response.statusCode}');
    }
  }

  // Fetch employees by job role
  Future<List<dynamic>> fetchEmployeesByJobRole(User user, String token, String jobRoleId) async {
    final url = 'https://hp.triz.co.in/search_data?type=API&token=$token&sub_institute_id=${user.subInstituteId}&org_type=${Uri.encodeComponent(user.orgType)}&searchType=jobrole_emp&searchWord=$jobRoleId';

    debugPrint('Fetching employees by job role from: $url');

    final response = await _httpClient.get(Uri.parse(url));

    debugPrint('Employees fetch response status: ${response.statusCode}');
    debugPrint('Employees fetch response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Employees fetch successful');
      if (data['searchData'] != null) {
        return data['searchData'] as List<dynamic>;
      } else {
        return [];
      }
    } else {
      debugPrint('Employees fetch failed: ${response.body}');
      throw Exception('Failed to fetch employees: ${response.statusCode}');
    }
  }

  // Assign Task API
  Future<Map<String, dynamic>> assignTask({
    required User user,
    required String token,
    required String taskTitle,
    required String taskDescription,
    required String taskAllocatedTo,
    required String skillId,
    required String skills,
    required String manageBy,
    required String observationPoint,
    required String kpa,
    required String selType,
    required int repeatDays,
    required String repeatUntil,
  }) async {
    final url = 'https://hp.triz.co.in/task?type=API&token=$token&sub_institute_id=${user.subInstituteId}&org_type=Healthcare&syear=2025&user_id=${user.id}&formType=multiUser';

    final payload = {
      'TASK_ALLOCATED_TO': taskAllocatedTo,
      'task_title': taskTitle,
      'task_description': taskDescription,
      'skill_id': skillId,
      'skills': skills,
      'manageby': manageBy,
      'observation_point': observationPoint,
      'KPA': kpa,
      'selType': selType,
      'repeat_days': repeatDays.toString(),
      'repeat_until': repeatUntil,
    };

    debugPrint('Assigning task with URL: $url');
    debugPrint('Assigning task with payload: $payload');

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

    debugPrint('Assign task response status: ${response.statusCode}');
    debugPrint('Assign task response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Assign task response: $data');
      return data;
    } else {
      debugPrint('Assign task failed: ${response.body}');
      throw Exception('Failed to assign task: ${response.statusCode}');
    }
  }

  // Fetch a single task by ID
  Future<Task?> fetchTaskById(int taskId, User user, String token) async {
    final url = 'https://hp.triz.co.in/task/$taskId?type=API&token=$token&sub_institute_id=${user.subInstituteId}';

    debugPrint('Fetching task by ID from: $url');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    debugPrint('Fetch task by ID response status: ${response.statusCode}');
    debugPrint('Fetch task by ID response body length: ${response.body.length}');

    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty) {
        debugPrint('Empty response body, task endpoint might not exist');
        return null;
      }

      try {
        final responseData = json.decode(response.body);
        debugPrint('Fetch task by ID response: $responseData');

        // Try different response formats
        if (responseData['status'] == '1' && responseData['data'] != null) {
          return Task.fromJson(responseData['data']);
        } else if (responseData is Map && responseData.containsKey('id')) {
          // Direct task object
          return Task.fromJson(responseData as Map<String, dynamic>);
        } else {
          debugPrint('Unexpected response format for task');
          return null;
        }
      } catch (e) {
        debugPrint('Error parsing task response: $e');
        return null;
      }
    } else {
      debugPrint('Fetch task by ID failed: ${response.statusCode}');
      throw Exception('Failed to fetch task by ID: ${response.statusCode}');
    }
  }

  // Fetch assigned tasks for the user
  Future<List<Task>> fetchAssignedTasks(User user, String token) async {
    final url = 'https://hp.triz.co.in/task?type=API&sub_institute_id=${user.subInstituteId}&token=$token&user_id=${user.id}&syear=2025&user_profile_name=${user.userProfileName}';

    debugPrint('Fetching assigned tasks from: $url');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    debugPrint('Fetch assigned tasks response status: ${response.statusCode}');
    debugPrint('Fetch assigned tasks response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      debugPrint('Fetch assigned tasks response: $responseData');
      if (responseData['status'] == '1' && responseData['data'] is List) {
        final tasks = responseData['data'] as List<dynamic>;
        return tasks.map((task) => Task.fromJson(task)).toList();
      } else if (responseData['checkList'] is List) {
        final tasks = responseData['checkList'] as List<dynamic>;
        return tasks.map((task) => Task.fromJson(task)).toList();
      } else {
        return [];
      }
    } else {
      debugPrint('Fetch assigned tasks failed: ${response.body}');
      throw Exception('Failed to fetch assigned tasks: ${response.statusCode}');
    }
  }

  // Update task
  Future<Map<String, dynamic>> updateTask({
    required User user,
    required String token,
    required Task task,
    required String status,
    required String completionRemark,
    required String approveRemarks,
    required String approveStatus,
  }) async {
    final url = 'https://hp.triz.co.in/task/${task.id}';

    final payload = {
      'id': task.id.toString(),
      'task_title': task.taskTitle,
      'task_description': task.taskDescription ?? '',
      'file_size': task.fileSize ?? '',
      'file_type': task.fileType ?? '',
      'task_date': task.taskDate,
      'repeat_days': task.repeatDays,
      'kra': task.kra ?? '',
      'kpa': task.kpa ?? '',
      'task_type': task.taskType,
      'status': status,
      'taskcompletation_remarks': completionRemark,
      'task_allocated': task.taskAllocated.toString(),
      'task_allocated_to': task.taskAllocatedTo.toString(),
      'required_skills': task.requiredSkills ?? '',
      'skill_id': task.skillId ?? '',
      'observation_point': task.observationPoint ?? '',
      'CREATED_IP_ADDRESS': task.createdIpAddress,
      'SYEAR': task.syear,
      'sub_institute_id': task.subInstituteId.toString(),
      'approved_by': task.approvedBy ?? '',
      'approved_on': task.approvedOn ?? '',
      'approve_status': approveStatus,
      'approve_remarks': approveRemarks,
      'reply': task.reply ?? '',
      'created_by': task.createdBy.toString(),
      'updated_by': task.updatedBy?.toString() ?? '',
      'deleted_by': task.deletedBy?.toString() ?? '',
      'created_at': task.createdAt,
      'updated_at': task.updatedAt ?? '',
      'deleted_at': task.deletedAt ?? '',
      'manageby': task.manageby ?? '',
      'ALLOCATOR': task.allocator ?? '',
      'ALLOCATED_TO': task.allocatedTo ?? '',
      'department': task.department ?? '',
      'jobrole': task.jobrole ?? '',
      'type': 'API',
      'token': token,
      'sub_institute_id': user.subInstituteId.toString(),
      'formType': 'approveStatus',
      'method_field': 'PUT',
      'syear': '2025',
    };

    debugPrint('Updating task with URL: $url');
    debugPrint('Updating task with payload keys: ${payload.keys.toList()}');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(payload),
    );

    debugPrint('Update task response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Update task response: $data');
      return data;
    } else {
      debugPrint('Update task failed: ${response.body}');
      throw Exception('Failed to update task: ${response.statusCode}');
    }
  }
  

  // Forgot Password API
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    const url = 'https://hp.triz.co.in/forget-password';

    final payload = {
      'email': email,
      'type': 'API',
      'reset_url': 'https://hp-frontend-three.vercel.app//rest-password',
    };

    debugPrint('Forgot password request to: $url');
    debugPrint('Payload: $payload');

    final headers = {
      'Content-Type': 'application/json',
    };

    final response = await _httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(payload),
    );

    debugPrint('Forgot password response status: ${response.statusCode}');
    debugPrint('Forgot password response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Forgot password response: $data');
      return data;
    } else {
      debugPrint('Forgot password failed: ${response.body}');
      throw Exception('Failed to send reset email: ${response.statusCode}');
    }
  }

  // Fetch LMS Courses
  Future<List<dynamic>> fetchLmsCourses(User user, String token) async {
    final url = 'https://hp.triz.co.in/lms/course_master?type=API&sub_institute_id=${user.subInstituteId}&syear=2025&user_id=${user.id}&user_profile_name=${Uri.encodeComponent(user.userProfileName)}&token=$token';

    debugPrint('Fetching LMS courses from: $url');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    debugPrint('LMS courses response status: ${response.statusCode}');
    debugPrint('LMS courses response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      debugPrint('LMS courses response data: $responseData');

      // Handle the actual LMS response structure
      if (responseData['lms_subject'] is Map) {
        final lmsSubject = responseData['lms_subject'] as Map<String, dynamic>;
        List<dynamic> allCourses = [];

        lmsSubject.forEach((category, list) {
          if (list is List) {
            for (var item in list) {
              if (item is Map) {
                final mutable = Map<String, dynamic>.from(item);
                mutable['content_category'] = category; // keep category for UI grouping
                allCourses.add(mutable);
              }
            }
          }
        });

        debugPrint('Flattened ${allCourses.length} LMS subjects from ${lmsSubject.keys.length} categories');
        return allCourses;
      }

      // Fallbacks for other possible structures
      if (responseData['data'] is List) {
        return responseData['data'] as List<dynamic>;
      } else if (responseData is List) {
        return responseData;
      } else if (responseData['courses'] is List) {
        return responseData['courses'] as List<dynamic>;
      } else {
        return [];
      }
    } else {
      debugPrint('Fetch LMS courses failed: ${response.body}');
      throw Exception('Failed to fetch courses: ${response.statusCode}');
    }
  }

  // Enroll in a course / subject (LMS)
  Future<Map<String, dynamic>> enrollInCourse({
    required int subjectId,
    required int standardId,
    int? courseId,
    required User user,
    required String token,
  }) async {
    const url = 'https://hp.triz.co.in/api/enroll';

    final now = DateTime.now();
    final startDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final endDate = "${now.year + 1}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}"; // 1 year validity as fallback

    final payload = {
      "user_id": user.id,
      "sub_institute_id": user.subInstituteId,
      "type": "API",
      "subject_id": subjectId,
      "standard_id": standardId,
      "course_id": courseId ?? subjectId,
      "start_date": startDate,
      "end_date": endDate,
      "status": "enrolled",
      "token": token,
    };

    debugPrint('Enrolling in course: $url');
    debugPrint('Enroll payload: $payload');

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

    debugPrint('Enroll response status: ${response.statusCode}');
    debugPrint('Enroll response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Enroll response: $data');

      if (data['status'] == '0' || data['message']?.toString().toLowerCase().contains('fail') == true) {
        throw Exception(data['message'] ?? 'Enrollment failed');
      }

      return data;
    } else {
      debugPrint('Enroll failed: ${response.body}');
      throw Exception('Failed to enroll: ${response.statusCode}');
    }
  }

  // Fetch LMS Course Chapters & Content
  Future<Map<String, dynamic>> fetchCourseChapters({
    required int subjectId,
    required int standardId,
    required User user,
    required String token,
  }) async {
    final url = 'https://hp.triz.co.in/lms/chapter_master?type=API&sub_institute_id=${user.subInstituteId}&syear=2025&user_profile_name=${Uri.encodeComponent(user.userProfileName)}&user_id=${user.id}&standard_id=$standardId&subject_id=$subjectId&token=$token';

    debugPrint('Fetching course chapters from: $url');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    debugPrint('Course chapters response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Course chapters response: $data');
      return data;
    } else {
      debugPrint('Fetch course chapters failed: ${response.body}');
      throw Exception('Failed to fetch course chapters: ${response.statusCode}');
    }
  }

  // Fetch AI Generated Assessments
  Future<List<Assessment>> fetchAiGeneratedAssessments(User user, String token) async {
    final subInstituteId = user.subInstituteId ?? 3;
    final url = 'https://hp.triz.co.in/api/ai-generated-assessment/assessment/index?sub_institute_id=$subInstituteId&type=API&token=$token';

    debugPrint('Fetching AI assessments from: $url');

    await loadCookies();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    debugPrint('AI Assessments response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final listResponse = AssessmentListResponse.fromJson(jsonData);
      return listResponse.data;
    } else {
      debugPrint('Fetch AI assessments failed: ${response.body}');
      throw Exception('Failed to fetch assessments: ${response.statusCode}');
    }
  }

  // Submit Online Exam (LMS assessment)
  Future<Map<String, dynamic>> submitOnlineExam({
    required int questionpaperId,
    required int userId,
    required int subInstituteId,
    required String token,
    required int questionpaperTime,
    required Map<int, List<int>> selectedAnswers, // questionId -> list of selected answerIds
    required Map<int, Map<int, int>> answerCorrectMap, // questionId -> {answerId: correctAnswerFlag}
    String? hidSessionQuiz,
  }) async {
    const url = 'https://hp.triz.co.in/lms/online_exam';

    final sessionTime = hidSessionQuiz ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final Map<String, String> body = {
      'type': 'API',
      'hid_session_quiz': sessionTime,
      'questionpaper_time': questionpaperTime.toString(),
      'questionpaper_id': questionpaperId.toString(),
      'sub_institute_id': subInstituteId.toString(),
      'user_id': userId.toString(),
    };

    // Build answer_single entries
    selectedAnswers.forEach((qId, selectedIds) {
      if (selectedIds.isNotEmpty) {
        final firstAnswerId = selectedIds.first;
        final correctFlag = answerCorrectMap[qId]?[firstAnswerId] ?? 0;
        body['answer_single[$qId]'] = '$firstAnswerId##$correctFlag';
      }
    });

    debugPrint('Submitting online exam to: $url');
    debugPrint('Online exam payload: $body');

    final headers = {
      'Authorization': 'Bearer $token',
      'Cookie': _getCookieHeader(),
    };

    final response = await _httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    debugPrint('Online exam submit response status: ${response.statusCode}');
    debugPrint('Online exam submit response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {'status': 'success', 'raw': response.body};
      }
    } else {
      throw Exception('Failed to submit exam: ${response.statusCode}');
    }
  }
}
