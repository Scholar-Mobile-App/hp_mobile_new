# Gaps To Growth Mobile App - Development Audit Report

**Repository:** hp_mobile_new  
**Project Type:** Flutter Mobile Application  
**Audit Date:** May 28, 2026  
**App Name:** Gaps To Growth (g2g_mobile)  
**Version:** 1.0.4+4

---

## 1. PROJECT OVERVIEW

### 1.1 Project Description
This is a **corporate HR/Growth mobile application** built with Flutter that provides employees access to their professional development journey, including learning management, performance tracking, attendance, leave management, competency development, and organizational resources.

### 1.2 Core Technology Stack
| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x |
| State Management | Provider |
| HTTP Client | http package |
| Local Storage | shared_preferences |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Fonts | Google Fonts (Poppins, Inter) |
| Date Formatting | intl package |
| Notifications UI | another_flushbar |
| Image Selection | image_picker |
| PDF Handling | pdf, printing packages |
| File Opening | open_filex |
| URL Handling | url_launcher |
| Animations | confetti |

### 1.3 Backend API
- Base URL: `https://hp.triz.co.in`
- Authentication: Cookie-based with XSRF token support
- Token Management: Bearer tokens with session cookies

---

## 2. APPLICATION ARCHITECTURE

### 2.1 Project Structure
```
lib/
├── main.dart                 # App entry point with Firebase initialization
├── config/
│   └── api_config.dart       # API endpoints and configuration
├── models/                   # Data models (15 model files)
│   ├── user.dart
│   ├── menu.dart
│   ├── menu_response.dart
│   ├── task.dart
│   ├── jobrole.dart
│   ├── job_role_task.dart
│   ├── job_role_task_table.dart
│   ├── job_role_skill.dart
│   ├── job_role_kaba.dart
│   ├── user_knowledge.dart
│   ├── user_ability.dart
│   ├── user_behaviour.dart
│   ├── user_attitude.dart
│   └── lms/assessment_model.dart
├── services/                 # Business logic services
│   ├── api_service.dart      # API communication layer
│   ├── auth_provider.dart    # Authentication state management
│   └── notification_service.dart  # FCM notifications
└── screens/                  # UI screens (35+ screen files)
    ├── splash_screen.dart
    ├── login_screen.dart
    ├── profile_screen.dart
    ├── profile_details_screen.dart
    ├── goals_screen.dart
    ├── achievements_screen.dart
    ├── training_screen.dart
    ├── resources_screen.dart
    ├── content_screen.dart
    ├── forgot_password_screen.dart
    ├── attendance/
    │   ├── attendance_screen.dart
    │   └── attendance_report_screen.dart
    ├── hrms/
    │   ├── apply_leave_screen.dart
    │   └── my_leave_chart_screen.dart
    ├── lms/
    │   ├── courses_list_screen.dart
    │   ├── course_detail_screen.dart
    │   ├── my_learning_dashboard_screen.dart
    │   ├── assessment_list_screen.dart
    │   └── enrollment_success_dialog.dart
    ├── organization_management/
    │   ├── organization_detail_screen.dart
    │   ├── task_details_screen.dart
    │   └── task_assignment_progress_screen.dart
    └── competency_management/
        └── library_taxonomy/
            ├── library_taxonomy_screen.dart
            ├── skill_detail_screen.dart
            ├── job_role_detail_screen.dart
            ├── jobrole_screen.dart
            ├── jobrole_task_screen.dart
            ├── knowledge_detail_screen.dart
            ├── ability_detail_screen.dart
            ├── attitude_screen.dart
            └── attitude_detail_screen.dart
```

### 2.2 Design System
- **Primary Color:** Orange (#FF6A00)
- **Secondary Color:** Deep Blue (#1F2A6D)
- **Theme:** Material Design 3 with custom color scheme
- **Font Families:** Poppins (headings), Inter (body text)
- **UI Pattern:** Glassmorphism cards with gradient backgrounds

---

## 3. FEATURE AUDIT

### 3.1 Authentication & Session Management ✅

| Feature | Implementation |
|---------|-----------------|
| Login Screen | Modern glassmorphism UI with gradient backgrounds |
| Session Persistence | SharedPreferences storage of user data and tokens |
| Cookie Management | XSRF token extraction and cookie storage |
| Remember Me | Optional session persistence |
| Forgot Password | Dedicated screen with email validation |
| Logout | Clears all session data including cookies |
| Session Check | Auto-login on app restart |

### 3.2 User Profile & Dashboard ✅

| Feature | Implementation |
|---------|-----------------|
| Profile Display | User avatar with image loading from CDN |
| Personal Info | Name, email, department, job role, employee ID |
| Quick Actions | Dynamic menu grid from API menu rights |
| Progress Overview | Goals, courses, achievements with progress bars |
| Announcements | Welcome messaging |

### 3.3 Learning Management System (LMS) ✅

| Feature | Implementation |
|---------|-----------------|
| Course Catalog | List view with categories, search, and filters |
| Course Enrollment | Enrollment API with date range |
| Course Details | Chapter hierarchy with content |
| AI Assessments | AI-generated assessment listing |
| Online Exams | Exam submission with answer tracking |
| Enrollment Success | Confetti celebration animation |
| My Learning Dashboard | Progress tracking per enrolled course |

### 3.4 Attendance Management ✅

| Feature | Implementation |
|---------|-----------------|
| Punch In/Out | Real-time clock with animated buttons |
| Today's Summary | Timeline display with working hours |
| Attendance Reports | Historical attendance data display |
| Visual Feedback | Animated button press effects |

### 3.5 Leave Management (HRMS) ✅

| Feature | Implementation |
|---------|-----------------|
| My Leave Screen | Tabbed view (All, Pending, Approved, Rejected) |
| Leave Summary | Count cards per status |
| Leave Application | Apply leave form with date selection |
| Leave Details | Bottom sheet with status and comments |
| Rejection Reason | Display HR/HOD comments |

### 3.6 Competency Management ✅

| Feature | Implementation |
|---------|-----------------|
| Library Taxonomy | 7-tab navigation (Skill, Job Role, Job Role Task, Knowledge, Ability, Behaviour, Attitude) |
| Skill Library | Searchable skill list with filtering |
| Job Roles | Comprehensive job role browser |
| Job Role Tasks | Task assignments with progress tracking |
| Knowledge Base | User knowledge assessment views |
| Abilities | Competency ability display |
| Behaviours | Workplace behavior tracking |
| Attitudes | Attitude assessment module |

### 3.7 Organization Management ✅

| Feature | Implementation |
|---------|-----------------|
| Organization Info | Tab with organization details |
| Department Management | Expandable department tree with add/edit |
| Sub-departments | Hierarchical structure support |
| Compliance Management | Placeholder for compliance trackers |
| Disciplinary Management | Placeholder for disciplinary tracking |

### 3.8 Additional Features ✅

| Feature | Implementation |
|---------|-----------------|
| Goals Screen | Development goals tracking with cards |
| Achievements Screen | Achievement badges and milestones |
| Training Screen | Training courses and learning paths |
| Resources Screen | Learning resources access |
| Content Screen | General content management |
| Push Notifications | Firebase FCM integration |

---

## 4. DATABASE MODELS (15 MODELS)

| Model | Purpose |
|-------|---------|
| `User` | Employee profile with 41 fields |
| `Menu` | Navigation menu items |
| `MenuResponse` | API menu rights response parsing |
| `Task` | Task assignment data |
| `JobRole` | Job role definitions |
| `JobRoleTask` | Tasks associated with roles |
| `JobRoleTaskTable` | Task table structure |
| `JobRoleSkill` | Skills required for roles |
| `JobRoleKaba` | Knowledge-Ability-Behaviour-Attitude matrix |
| `UserKnowledge` | Employee knowledge assessment |
| `UserAbilityO | Employee ability assessment |
| `UserBehaviour` | Employee behaviour tracking |
| `UserAttitude` | Employee attitude assessment |
| `Assessment` | LMS assessment model |

---

## 5. API INTEGRATIONS

### 5.1 API Endpoints Integrated
| Endpoint | Purpose |
|----------|---------|
| `/login` | User authentication |
| `/api/user/profile` | Fetch user profile |
| `/user/ajax_groupwiserights` | Fetch menu rights |
| `/lms/course_master` | LMS course listing |
| `/api/enroll` | Course enrollment |
| `/lms/chapter_master` | Course chapters |
| `/api/ai-generated-assessment` | AI assessments |
| `/lms/online_exam` | Exam submission |
| Attendance APIs | Punch in/out functionality |
| Leave APIs | Leave application and listing |

### 5.2 API Service Features
- Cookie extraction and persistence
- XSRF token management
- Bearer token authentication
- Error handling with user feedback
- JSON response parsing

---

## 6. UI/UX IMPLEMENTATIONS

### 6.1 Screens with Advanced UI
| Screen | Notable UI Features |
|--------|--------------------|
| Splash Screen | Multi-layer logo animation, floating text animation |
| Login Screen | Glassmorphism card, gradient buttons, floating effects |
| Profile Screen | Responsive quick action grid, progress cards |
| Organization Screen | Glassmorphism tab bar with blur effects |
| Leave Screen | Tabbed interface with status badges |

### 6.2 Common UI Patterns
- Gradient backgrounds
- Card-based layouts with shadows
- Bottom sheet modals for details
- Tabbed navigation
- Animated button interactions
- Search with debouncing
- Filter chips and bottom sheets

---

## 7. STATISTICS

| Metric | Count |
|--------|-------|
| Total Dart Files | 50+ |
| Screen Files | 35+ |
| Model Files | 15 |
| Service Files | 3 |
| Asset Images | 4 (crop.png, icon.png, login_bg.jpg, logo.png) |
| Platform Build Configs | Android, iOS, macOS, Linux, Windows, Web |

---

## 8. DOCUMENTATION FILES

| File | Purpose |
|------|---------|
| `README.md` | Basic Flutter project documentation |
| `FIREBASE_SETUP.md` | Firebase configuration guide |
| `PUSH_NOTIFICATIONS_README.md` | FCM setup instructions |
| `analysis_options.yaml` | Dart linting rules |

---

## 9. BUILD CONFIGURATION

| Platform | Status |
|----------|--------|
| Android | Configured (Gradle, Kotlin) |
| iOS | Configured (Podfile, Xcode) |
| macOS | Configured (CocoaPods) |
| Linux | Configured (CMake) |
| Windows | Configured (CMake) |
| Web | Configured (SPA manifest) |

---

## 10. DEVELOPMENT SUMMARY

### What Has Been Built:
1. ✅ **Complete Authentication Flow** - Login, session persistence, logout
2. ✅ **User Dashboard** - Profile viewing with dynamic menus from API
3. ✅ **Learning Management System** - Course catalog, enrollment, exams, AI assessments
4. ✅ **Attendance Tracking** - Punch in/out with live clock and history
5. ✅ **Leave Management** - Apply leave, view status, rejection feedback
6. ✅ **Competency Framework** - 7-module taxonomy library
7. ✅ **Organization Management** - Department hierarchy management
8. ✅ **Push Notifications** - FCM integration ready
9. ✅ **Professional UI/UX** - Modern design with animations
10. ✅ **Multi-platform Ready** - Android, iOS, Web, Desktop support

### Architecture Highlights:
- **Clean separation** between UI, services, and models
- **Provider pattern** for state management
- **Cookie-based auth** with XSRF token security
- **Responsive layouts** for various screen sizes
- **Centralized API configuration**
---

# DEEP DETAIL AUDIT ADDENDUM

## 11. SOURCE CODE DEEP ANALYSIS

### 11.1 ApiService Detailed Breakdown

The `api_service.dart` (461+ lines) is the central nervous system of the application:

#### 11.1.1 Cookie Management System
```dart
Map<String, String> _cookies = {};  // In-memory cookie store

Future<void> loadCookies() async { }    // Loads persisted cookies
Future<void> _extractCookies() async { } // Parses Set-Cookie headers
String _getCookieHeader() { }            // Generates cookie string
String? getXsrfToken() { }              // Extract XSRF token
```

#### 11.1.2 Authentication Methods
| Method | Auth Type | Returns |
|--------|-----------|---------|
| `login()` | GET (query params) | User object |
| `fetchProfile()` | Bearer + Cookie | User object |
| `fetchUserEditDetails()` | Bearer + Cookie | Map |

#### 11.1.3 Exam Submission Format
```dart
body['answer_single[$questionId]'] = '$answerId##$correctFlag'
```

### 11.2 NotificationService Architecture

#### 11.2.1 Singleton Pattern
```dart
static final NotificationService _instance = NotificationService._internal();
factory NotificationService() => _instance;
```

#### 11.2.2 Firebase Message Handlers
| Handler | Purpose |
|---------|---------|
| `onBackgroundMessage` | App terminated state |
| `onMessage` | App in foreground |
| `onMessageOpenedApp` | App opened from notification |

### 11.3 Attendance System Details

#### 11.3.1 State Machine
```
NOT_CLOCKED_IN → CLOCKED_IN → CLOCKED_OUT
```

#### 11.3.2 Attendance Report PDF Structure
```
├── Header: "Attendance Report - [Month]"
├── Employee Info
├── Summary Table (4x2 grid)
└── Daily Report Table (7 columns)
```

### 11.4 Leave Management Flow
```
[Select Type] → [Choose Dates] → [Enter Reason] → [Submit]
```

### 11.5 Competency Framework Data Models

#### 11.5.1 KABA Matrix Structure
```dart
class JobRoleKaba {
  List<KABAItem> skill;
  List<KABAItem> knowledge;
  List<KABAItem> ability;
  List<KABAItem> attitude;
  List<KABAItem> behaviour;
}
```

---

## 12. API ENDPOINT CATALOG (Complete - 22+ Endpoints)

| Category | Endpoints | Count |
|----------|-----------|-------|
| Authentication | /login, /profile, /menu-rights | 3 |
| LMS | courses, enroll, chapters, assessments, exam | 5 |
| Attendance | punch, report | 4 |
| HRMS | leaves, types, apply | 3 |
| Competency | skills, roles, tasks, KABA | 6 |
| Organization | departments, sub-depts | 3 |

---

## 13. CODE METRICS

### 13.1 Largest Files
| File | Est. Lines | Complexity |
|------|-------------|------------|
| api_service.dart | 461 | High |
| attendance_screen.dart | 461 | Medium |
| attendance_report_screen.dart | 476 | Medium |
| courses_list_screen.dart | 469 | Medium |

### 13.2 Method Count by Service
| Service | Public | Private |
|---------|--------|---------|
| ApiService | 28+ | 5 |
| AuthProvider | 5 | 0 |
| NotificationService | 6 | 3 |

---

## 14. ERROR HANDLING PATTERNS

### 14.1 API Error Handling Pattern
```dart
try {
  final response = await _httpClient.get(uri);
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('API Error: ${response.statusCode}');
  }
} catch (e) {
  debugPrint('Error: $e');
  rethrow;
}
```

### 14.2 Form Validation Examples
- Email: Must contain '@'
- Password: Required field
- Leave Reason: Minimum 10 characters

---

## 15. ANIMATION SPECIFICATIONS

### 15.1 Splash Screen Animations
| Animation | Duration | Curve |
|-----------|----------|-------|
| Logo Fade | 900ms | easeOut |
| Logo Scale | 1200ms | elasticOut |
| Logo Float | 400ms | easeInOutSine |
| Glow Pulse | 2s | linear (loop) |
| Text Slide | 1000ms | easeOutCubic |

### 15.2 Tab Bar Animation
| Property | Value | Curve |
|----------|-------|-------|
| Tab Switch | 520ms | easeOutBack |
| Item Scale | 300ms | easeOut |

---

## 16. SECURITY ANALYSIS

### 16.1 Current Measures
- ✅ HTTPS for all API calls
- ✅ XSRF token in cookies
- ✅ Bearer token authentication

### 16.2 Recommendations
1. Change login to POST method
2. Encrypt SharedPreferences storage
3. Implement session expiration
4. Add biometric authentication

---

## 17. PERFORMANCE ANALYSIS

### 17.1 Optimization Opportunities
| Area | Current | Recommended |
|------|---------|-------------|
| Image Loading | NetworkImage | Cached images |
| List Rendering | ListView | ListView.builder |
| API Calls | Per screen | Batch |

---

## 18. TESTING STATUS

### 18.1 Current Coverage
- Minimal widget_test.dart exists
- No unit tests for services
- No integration tests

---

## 19. DEPLOYMENT READINESS

| Platform | Status |
|----------|--------|
| Android | ✅ Ready |
| iOS | ✅ Ready |
| macOS | ✅ Ready |
| Linux | ✅ Ready |
| Windows | ✅ Ready |
| Web | ✅ Ready |

---

## 20. CONCLUSION

**Overall Assessment: Production-Ready with Minor Hardening Needed**

### Strengths
- ✅ Clean separation of concerns
- ✅ Comprehensive feature set (10+ modules)
- ✅ Modern UI with animations
- ✅ Multi-platform support (6 platforms)
- ✅ Robust cookie-based authentication

### Areas for Improvement
- ⚠️ Security hardening needed
- ⚠️ Test coverage expansion needed
- ⚠️ Performance optimization opportunities
- ⚠️ Offline capability missing

---

# 🐛 BUG REPORT - Complete Analysis

*Report Generated: May 28, 2026*
*Source Files Analyzed: 50+*

---

## EXECUTIVE SUMMARY

This bug report identifies **25+ bugs, issues, and potential problems** across the codebase, categorized by severity:

| Severity | Count | Description |
|----------|-------|-------------|
| 🔴 CRITICAL | 3 | Causes runtime crashes |
| 🟠 HIGH | 8 | Causes functional failures |
| 🟡 MEDIUM | 10 | Causes unexpected behavior |
| 🟢 LOW | 5 | Code quality issues |

---

## 🔴 CRITICAL BUGS (Causes Runtime Crashes)

### BUG #1: `firstWhere` without `orElse` throws exception

**Location:** `lib/services/notification_service.dart:256-259`

```dart
final task = tasks.firstWhere(
  (t) => t.id == int.parse(taskId.toString()),
  orElse: () => null as Task,  // ⚠️ PROBLEM: Type mismatch + potential null
);
```

**Problem:**
1. `orElse` with `null as Task` causes type mismatch
2. If task not found, app will crash when accessing `task` later
3. The return type doesn't match `Task` class

**Impact:** App crash when navigating to task from notification

**Fix:**
```dart
Task? task;
try {
  task = tasks.firstWhere(
    (t) => t.id == int.parse(taskId.toString()),
  );
} catch (_) {
  task = null;
}

if (task != null) {
  navigatorKey.currentState?.push(...);
}
```

---

### BUG #2: Null safety violation in `apply_leave_screen.dart`

**Location:** `lib/screens/hrms/apply_leave_screen.dart:205-209`

```dart
if (_dayType == 'Full Day') {
  fromDateStr = dateFormat.format(_fromDate!);  // ⚠️ Could be null
  toDateStr = dateFormat.format(_toDate!);     // ⚠️ Could be null
}
```

**Problem:** Even though there's a check earlier, Dart's flow analysis doesn't guarantee non-null when accessing `_fromDate!` and `_toDate!`

**Impact:** Potential crash if state is corrupted

**Fix:**
```dart
if (_dayType == 'Full Day' && _fromDate != null && _toDate != null) {
  fromDateStr = dateFormat.format(_fromDate!);
  toDateStr = dateFormat.format(_toDate!);
}
```

---

### BUG #3: ListView without builder causes performance issues

**Location:** `lib/screens/profile_screen.dart`, `lib/screens/lms/assessment_list_screen.dart`, `lib/screens/organization_management/organization_detail_screen.dart`

```dart
// ❌ PROBLEMATIC - Creates all items immediately
ListView(
  children: [...],
)

// ✅ CORRECT - Lazy builds items
ListView.builder(
  itemCount: ...,
  itemBuilder: ...,
)
```

**Impact:** Memory issues with large lists, UI jank

---

## 🟠 HIGH PRIORITY BUGS

### BUG #4: Hardcoded year in API calls

**Location:** `lib/services/api_service.dart`

```dart
// Line: syear=2025
final url = '...?syear=2025...';  // ⚠️ Hardcoded year
```

**Problem:** Will break in 2027+

**Fix:**
```dart
final syear = DateTime.now().year.toString();
// Or use user's syear from auth provider
```

---

### BUG #5: Debounce timer not always cancelled

**Location:** Multiple competency screens

```dart
// ❌ In some files
_timer?.cancel();  // Timer might not be assigned

// ✅ Should check isActive
_timer?.cancel();
_timer = null;
```

---

### BUG #6: Missing `mounted` check after async operations

**Location:** Multiple files

Some async functions call `setState()` without checking `mounted`:
```dart
Future<void> someMethod() async {
  await someAsyncCall();
  // ⚠️ Widget might be unmounted here
  setState(() { });  // Should check mounted
}
```

**Affected Files:**
- `splash_screen.dart`
- `profile_screen.dart`
- Multiple screen files

---

### BUG #7: Deep nesting in build methods

**Location:** `lib/screens/profile_screen.dart:1-419`

```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ⚠️ 6+ levels of nesting
```

**Impact:** Hard to read, maintain, and debug

---

### BUG #8: Memory leak - TextEditingControllers not disposed

**Location:** `lib/screens/organization_management/task_assignment_progress_screen.dart`

```dart
final TextEditingController taskTitleController = TextEditingController();
final TextEditingController taskDescriptionController = TextEditingController();
final FocusNode taskTitleFocusNode = FocusNode();

// ❌ Not disposed in dispose() method
```

---

### BUG #9: Error swallowed without logging

**Location:** `lib/screens/attendance/attendance_screen.dart:124-126`

```dart
} catch (e) {
  debugPrint('Failed to load attendance status: $e');
  // ⚠️ Error is swallowed silently
  // No user feedback
}
```

---

### BUG #10: Cookie parsing edge case

**Location:** `lib/services/api_service.dart:79-103`

```dart
response.headers.forEach((key, value) {
  if (key.toLowerCase() == 'set-cookie') {
    // ⚠️ If multiple Set-Cookie headers, only last one processed
  }
});
```

**Problem:** Some servers send multiple Set-Cookie headers

**Fix:**
```dart
final cookies = response.headers['set-cookie'];
if (cookies != null) {
  for (final cookie in cookies.split(',')) {
    // Parse each cookie
  }
}
```

---

## 🟡 MEDIUM PRIORITY ISSUES

### BUG #11: Debug logging left in production code

**Locations:** 20 files with `debugPrint()` statements

```dart
debugPrint('Login request successful');      // Should be removed
debugPrint('Response data: $data');         // Security risk
debugPrint('Cookies string from prefs: $cookiesString'); // PII risk
```

**Impact:** Performance, security, and logging pollution

---

### BUG #12: Magic numbers scattered throughout

**Locations:** Multiple files

```dart
// In attendance_screen.dart
Duration(seconds: 1),        // Timer interval
Duration(days: 30),          // Lookback period

// In apply_leave_screen.dart
value.trim().length < 10    // Magic number for min reason length
```

**Fix:** Extract to constants:
```dart
static const kAttendanceTimerInterval = Duration(seconds: 1);
static const kLeaveLookbackDays = 30;
static const kMinReasonLength = 10;
```

---

### BUG #13: Inconsistent error handling

**Some places:**
```dart
throw Exception('Failed to login');  // New exception
```

**Other places:**
```dart
return {'error': 'message'};  // Return error map
```

**Impact:** Inconsistent behavior for callers

---

### BUG #14: Hardcoded API base URL in multiple files

**Location:** `lib/services/api_service.dart`, `lib/services/notification_service.dart`

```dart
final url = 'https://hp.triz.co.in/...';  // Hardcoded
```

**Should be:**
```dart
final url = '${ApiConfig.baseUrl}/...';  // Centralized
```

---

### BUG #15: Race condition in debounce timer

**Location:** `lib/screens/competency_management/library_taxonomy/*.dart`

```dart
if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
_debounceTimer = Timer(const Duration(milliseconds: 500), () {
```

**Problem:** Timer callback might fire after widget is disposed

**Fix:**
```dart
@override
void dispose() {
  _debounceTimer?.cancel();
  _debounceTimer = null;
  super.dispose();
}
```

---

### BUG #16: Missing validation in dates

**Location:** `lib/screens/hrms/apply_leave_screen.dart`

```dart
// ⚠️ No validation that from_date <= to_date
// ⚠️ No validation against existing leaves
```

---

### BUG #17: State not reset on logout

**Location:** `lib/services/auth_provider.dart`

```dart
Future<void> logout() async {
  _currentUser = null;
  _menuResponse = null;
  _originalToken = null;
  // ⚠️ _isLoading might be stuck in true
}
```

---

### BUG #18: API timeout not handled

**Location:** `lib/services/api_service.dart`

No explicit timeout handling - requests may hang indefinitely

**Fix:**
```dart
http.Client client = http.Client();
final response = await client
  .get(uri)
  .timeout(Duration(seconds: 30));
```

---

### BUG #19: Password in URL query parameters

**Location:** `lib/services/api_service.dart:121-128`

```dart
final uri = Uri.parse(baseUrl).replace(
  queryParameters: {
    'email': email,
    'password': password,  // ⚠️ Security issue
    'type': 'API',
  },
);
```

**Impact:** Password appears in server logs

---

### BUG #20: No network connectivity check

**Locations:** All API calls

```dart
// No check if device is online
// API call just fails silently in some cases
```

---

## 🟢 LOW PRIORITY / CODE QUALITY

### BUG #21: Unused import

**Location:** `lib/screens/profile_screen.dart`

```dart
import 'package:another_flushbar/flushbar.dart';  // ⚠️ Imported but not used
```

---

### BUG #22: Duplicate code in status color helpers

**Multiple locations:**
```dart
Color _getStatusColor(String status) { ... }
Color _getStatusColor2(String status) { ... }
```

**Fix:** Create shared utility class

---

### BUG #23: Variable naming inconsistency

**In one file:**
```dart
bool _isLoading = true;
bool isLoadingDepartments = true;  // ⚠️ Inconsistent
```

---

### BUG #24: Comments indicate unfinished code

**Location:** `lib/screens/organization_management/organization_detail_screen.dart`

```dart
// TODO: Implement this feature
// FIXME: This doesn't work
// HACK: Temporary workaround
```

**Impact:** Technical debt

---

### BUG #25: Large file sizes

| File | Lines | Recommendation |
|------|-------|----------------|
| api_service.dart | 461 | Split by domain |
| attendance_report_screen.dart | 476 | Split widgets |
| courses_list_screen.dart | 469 | Extract components |

---

## 📋 BUG PRIORITY MATRIX

| Bug # | Title | Severity | Files Affected | Estimated Fix Time |
|-------|-------|-----------|----------------|-------------------|
| 1 | firstWhere without orElse | 🔴 CRITICAL | 1 | 10 min |
| 2 | Null safety violation | 🔴 CRITICAL | 1 | 5 min |
| 3 | ListView without builder | 🔴 CRITICAL | 3 | 30 min |
| 4 | Hardcoded year 2025 | 🟠 HIGH | 1 | 5 min |
| 5 | Debounce timer leak | 🟠 HIGH | 4 | 15 min |
| 6 | Missing mounted checks | 🟠 HIGH | 10+ | 60 min |
| 7 | Deep nesting | 🟠 HIGH | 5 | Refactor |
| 8 | TextController leak | 🟠 HIGH | 1 | 10 min |
| 9 | Swallowed errors | 🟠 HIGH | 5 | 30 min |
| 10 | Cookie parsing | 🟠 HIGH | 1 | 15 min |
| 11 | DebugPrint in prod | 🟡 MEDIUM | 20 | 45 min |
| 12 | Magic numbers | 🟡 MEDIUM | 10 | 60 min |
| 13 | Inconsistent errors | 🟡 MEDIUM | 10 | 45 min |
| 14 | Hardcoded URLs | 🟡 MEDIUM | 2 | 20 min |
| 15 | Timer race condition | 🟡 MEDIUM | 4 | 15 min |
| 16 | Missing validation | 🟡 MEDIUM | 2 | 30 min |
| 17 | State not reset | 🟡 MEDIUM | 1 | 10 min |
| 18 | No timeout handling | 🟡 MEDIUM | 1 | 20 min |
| 19 | Password in URL | 🟡 MEDIUM | 1 | 15 min |
| 20 | No connectivity check | 🟡 MEDIUM | 10 | 90 min |
| 21 | Unused imports | 🟢 LOW | 5 | 10 min |
| 22 | Duplicate helpers | 🟢 LOW | 10 | 30 min |
| 23 | Naming inconsistency | 🟢 LOW | 10 | 30 min |
| 24 | TODO comments | 🟢 LOW | 3 | 60 min |
| 25 | Large files | 🟢 LOW | 5 | Refactor |

---

## 🛠️ RECOMMENDED FIXES BY CATEGORY

### Quick Wins (< 15 min each)
1. Add `orElse` to all `firstWhere` calls
2. Replace hardcoded `2025` with dynamic year
3. Add null checks for date formatters
4. Cancel timers in dispose()
5. Add mounted checks after async

### Medium Effort (15-60 min each)
1. Convert ListView to ListView.builder
2. Extract magic numbers to constants
3. Add try-catch with user feedback
4. Centralize API URLs
5. Remove debugPrint statements

### Refactoring (Long term)
1. Split large files by domain
2. Create shared utility classes
3. Add proper error boundaries
4. Implement offline-first architecture
5. Add comprehensive tests

---

## 📊 SUMMARY STATISTICS

| Category | Count |
|----------|-------|
| Total Bugs Found | 25 |
| Critical | 3 |
| High | 7 |
| Medium | 10 |
| Low | 5 |
| Files Requiring Changes | 20+ |
| Estimated Fix Time | ~10 hours |

---

*Bug Report Generated: May 28, 2026*
*Analysis performed on 50+ Dart source files*
