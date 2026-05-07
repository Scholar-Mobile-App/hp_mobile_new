import 'package:flutter/foundation.dart';

class User {
  final int id;
  final String userName;
  final String firstName;
  final String middleName;
  final String lastName;
  final String fullName;
  final String email;
  final String mobile;
  final String birthdate;
  final String address;
  final String gender;
  final String joinYear;
  final String employeeNo;
  final String? employeeId;
  final String image;
  final int userProfileId;
  final String userProfileName;
  final int subInstituteId;
  final int clientId;
  final int isAdmin;
  final int status;
  final int departmentId;
  final String departmentName;
  final String jobroleId;
  final String jobroleName;
  final String jobLevel;
  final int sequenceOrder;
  final int hasVerticalProgression;
  final int hasLateralMovement;
  final String progressionType;
  final String schoolName;
  final String schoolShortCode;
  final String schoolLogo;
  final String syear;
  final String orgName;
  final String orgType;
  final String yearTitle;
  final String token;

  User({
    required this.id,
    required this.userName,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.birthdate,
    required this.address,
    required this.gender,
    required this.joinYear,
    required this.employeeNo,
    required this.employeeId,
    required this.image,
    required this.userProfileId,
    required this.userProfileName,
    required this.subInstituteId,
    required this.clientId,
    required this.isAdmin,
    required this.status,
    required this.departmentId,
    required this.departmentName,
    required this.jobroleId,
    required this.jobroleName,
    required this.jobLevel,
    required this.sequenceOrder,
    required this.hasVerticalProgression,
    required this.hasLateralMovement,
    required this.progressionType,
    required this.schoolName,
    required this.schoolShortCode,
    required this.schoolLogo,
    required this.syear,
    required this.orgName,
    required this.orgType,
    required this.yearTitle,
    required this.token,
  });

  // Factory constructor to create User from JSON (for login)
  factory User.fromLoginJson(Map<String, dynamic> json) {
    final sessionData = json['sessionData'] is Map
        ? Map<String, dynamic>.from(json['sessionData'] as Map)
        : <String, dynamic>{};
    final organization = json['organization'] is Map
        ? Map<String, dynamic>.from(json['organization'] as Map)
        : <String, dynamic>{};
    final yearData = json['year_data'] is Map
        ? Map<String, dynamic>.from(json['year_data'] as Map)
        : <String, dynamic>{};
    final userData = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};
    final userProfile = userData['user_profile'] is Map
        ? Map<String, dynamic>.from(userData['user_profile'] as Map)
        : <String, dynamic>{};
    debugPrint('Session Data: $sessionData');

    return User(
      id: userData['id'] ?? sessionData['user_id'] ?? 0,
      userName: userData['user_name'] ?? sessionData['user_name'] ?? '',
      firstName: userData['first_name'] ?? sessionData['first_name'] ?? '',
      middleName: userData['middle_name']?.toString() ?? '',
      lastName: userData['last_name'] ?? sessionData['last_name'] ?? '',
      fullName:
          '${userData['first_name'] ?? sessionData['first_name'] ?? ''} ${userData['middle_name'] ?? ''} ${userData['last_name'] ?? sessionData['last_name'] ?? ''}'
              .trim(),
      email: userData['email'] ?? sessionData['user_email'] ?? '',
      mobile: userData['mobile']?.toString() ?? '',
      birthdate:
          userData['birthdate']?.toString() ??
          sessionData['birthdate']?.toString() ??
          '',
      address: userData['address']?.toString() ?? '',
      gender: userData['gender']?.toString() ?? '',
      joinYear: userData['join_year']?.toString() ?? '',
      employeeNo:
          userData['employee_no']?.toString() ??
          sessionData['employee_no']?.toString() ??
          '',
      employeeId: userData['employee_id']?.toString(),
      image: userData['image']?.toString() ?? sessionData['user_image']?.toString() ?? '',
      userProfileId: userData['user_profile_id'] ?? sessionData['user_profile_id'] ?? 0,
      userProfileName:
          sessionData['user_profile_name']?.toString() ??
          userProfile['name']?.toString() ??
          '',
      subInstituteId: userData['sub_institute_id'] ?? sessionData['sub_institute_id'] ?? 0,
      clientId: userData['client_id'] ?? 0,
      isAdmin: userData['is_admin'] ?? 0,
      status: userData['status'] ?? 0,
      departmentId: userData['department_id'] ?? 0,
      departmentName: userData['department_name']?.toString() ?? '',
      jobroleId:
          userData['jobrole_id']?.toString() ?? userData['jobtitle_id']?.toString() ?? '',
      jobroleName: userData['jobrole_name']?.toString() ?? '',
      jobLevel: userData['job_level']?.toString() ?? '',
      sequenceOrder: 0,
      hasVerticalProgression: 0,
      hasLateralMovement: 0,
      progressionType: '',
      schoolName:
          organization['SchoolName']?.toString() ??
          sessionData['org_name']?.toString() ??
          '',
      schoolShortCode:
          organization['ShortCode']?.toString() ??
          sessionData['org_short_code']?.toString() ??
          '',
      schoolLogo:
          organization['Logo']?.toString() ??
          sessionData['org_logo']?.toString() ??
          '',
      syear:
          sessionData['syear']?.toString() ??
          yearData['syear']?.toString() ??
          userData['syear']?.toString() ??
          '',
      orgName:
          organization['SchoolName']?.toString() ??
          sessionData['org_name']?.toString() ??
          '',
      orgType: sessionData['org_type']?.toString() ?? 'Healthcare',
      yearTitle:
          yearData['title']?.toString() ??
          sessionData['year_title']?.toString() ??
          '',
      token:
          sessionData['token']?.toString() ??
          userData['api_token']?.toString() ??
          userData['token']?.toString() ??
          userData['id']?.toString() ??
          '',
    );
  }

  // Factory constructor to create User from profile JSON
  factory User.fromProfileJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['id'] ?? 0,
      userName: json['user_name'] ?? '',
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      birthdate: json['birthdate'] ?? '',
      address: json['address'] ?? '',
      gender: json['gender'] ?? '',
      joinYear: json['join_year'] ?? '',
      employeeNo: json['employee_no'] ?? '',
      employeeId: json['employee_id'],
      image: json['image'] ?? '',
      userProfileId: json['user_profile_id'] ?? 0,
      userProfileName: json['user_profile_name'] ?? '',
      subInstituteId: json['sub_institute_id'] ?? 0,
      clientId: json['client_id'] ?? 0,
      isAdmin: json['is_admin'] ?? 0,
      status: json['status'] ?? 0,
      departmentId: json['department_id'] ?? 0,
      departmentName: json['department_name'] ?? '',
      jobroleId: json['jobrole_id'] ?? '',
      jobroleName: json['jobrole_name'] ?? '',
      jobLevel: json['job_level'] ?? '',
      sequenceOrder: json['sequence_order'] ?? 0,
      hasVerticalProgression: json['has_vertical_progression'] ?? 0,
      hasLateralMovement: json['has_lateral_movement'] ?? 0,
      progressionType: json['progression_type'] ?? '',
      schoolName: json['school_name'] ?? '',
      schoolShortCode: json['school_short_code'] ?? '',
      schoolLogo: json['school_logo'] ?? '',
      syear: json['syear'] ?? '',
      orgName: json['org_name'] ?? '',
      orgType: json['org_type'] ?? 'Healthcare',
      yearTitle: json['year_title'] ?? '',
      token: token,
    );
  }

  // Factory constructor to create User from JSON (for stored data)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      userName: json['user_name'] ?? '',
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      birthdate: json['birthdate'] ?? '',
      address: json['address'] ?? '',
      gender: json['gender'] ?? '',
      joinYear: json['join_year'] ?? '',
      employeeNo: json['employee_no'] ?? '',
      employeeId: json['employee_id'],
      image: json['image'] ?? '',
      userProfileId: json['user_profile_id'] ?? 0,
      userProfileName: json['user_profile_name'] ?? '',
      subInstituteId: json['sub_institute_id'] ?? 0,
      clientId: json['client_id'] ?? 0,
      isAdmin: json['is_admin'] ?? 0,
      status: json['status'] ?? 0,
      departmentId: json['department_id'] ?? 0,
      departmentName: json['department_name'] ?? '',
      jobroleId: json['jobrole_id'] ?? '',
      jobroleName: json['jobrole_name'] ?? '',
      jobLevel: json['job_level'] ?? '',
      sequenceOrder: json['sequence_order'] ?? 0,
      hasVerticalProgression: json['has_vertical_progression'] ?? 0,
      hasLateralMovement: json['has_lateral_movement'] ?? 0,
      progressionType: json['progression_type'] ?? '',
      schoolName: json['school_name'] ?? '',
      schoolShortCode: json['school_short_code'] ?? '',
      schoolLogo: json['school_logo'] ?? '',
      syear: json['syear'] ?? '',
      orgName: json['org_name'] ?? '',
      orgType: json['org_type'] ?? 'Healthcare',
      yearTitle: json['year_title'] ?? '',
      token: json['token'] ?? '',
    );
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'full_name': fullName,
      'email': email,
      'mobile': mobile,
      'birthdate': birthdate,
      'address': address,
      'gender': gender,
      'join_year': joinYear,
      'employee_no': employeeNo,
      'employee_id': employeeId,
      'image': image,
      'user_profile_id': userProfileId,
      'user_profile_name': userProfileName,
      'sub_institute_id': subInstituteId,
      'client_id': clientId,
      'is_admin': isAdmin,
      'status': status,
      'department_id': departmentId,
      'department_name': departmentName,
      'jobrole_id': jobroleId,
      'jobrole_name': jobroleName,
      'job_level': jobLevel,
      'sequence_order': sequenceOrder,
      'has_vertical_progression': hasVerticalProgression,
      'has_lateral_movement': hasLateralMovement,
      'progression_type': progressionType,
      'school_name': schoolName,
      'school_short_code': schoolShortCode,
      'school_logo': schoolLogo,
      'syear': syear,
      'org_name': orgName,
      'org_type': orgType,
      'year_title': yearTitle,
      'token': token,
    };
  }
}
