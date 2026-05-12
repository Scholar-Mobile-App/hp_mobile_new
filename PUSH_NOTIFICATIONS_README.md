# Push Notifications Implementation

This implementation adds push notification support to the G2G Mobile app so that employees receive notifications when tasks are assigned to them, even when the application is closed.

## Features Implemented

1. **Firebase Cloud Messaging (FCM)** integration (ready for backend)
2. **Background message handling** - notifications work when app is closed (when Firebase configured)
3. **Foreground message handling** - notifications work when app is open (when Firebase configured)
4. **System Notification Drawer** - notifications appear in mobile notification drawer for FCM messages
5. **Local Notifications** - flutter_local_notifications plugin for displaying system notifications
6. **In-App Notifications** - immediate visual feedback using Flushbar when tasks are assigned
7. **Permission management** - automatic request for notification permissions
8. **Task assigner notifications** - notifications shown to person assigning tasks
9. **Test notifications** - button to test notification drawer functionality
10. **Graceful degradation** - app works without Firebase configuration

**Current Limitation**: Task assignee notifications require backend server implementation to send FCM messages to the assignee's device.

## Files Modified/Added

### New Files
- `lib/services/notification_service.dart` - Main notification service
- `FIREBASE_SETUP.md` - Setup instructions for Firebase

### Modified Files
- `pubspec.yaml` - Added Firebase dependencies
- `lib/main.dart` - Added Firebase initialization
- `lib/screens/organization_management/task_assignment_progress_screen.dart` - Added notification logic
- `android/build.gradle.kts` - Added Google services plugin
- `android/app/build.gradle.kts` - Added Google services plugin
- `android/app/src/main/AndroidManifest.xml` - Added notification permissions and Firebase service

## Setup Instructions

### 1. Firebase Project Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Enable Firebase Cloud Messaging

### 2. Android Configuration
1. Add Android app with package name: `com.triz.g2g`
2. Download `google-services.json`
3. Place it in `android/app/`

### 3. iOS Configuration ✅ COMPLETED
1. iOS app configured with bundle ID: `com.triz.g2g`
2. `GoogleService-Info.plist` placed in `ios/Runner/`
3. Notification permissions added to `Info.plist`
4. Firebase messaging configured in `AppDelegate.swift`

## How It Works

### Current Implementation
- **System Notifications**: FCM messages now appear in the mobile notification drawer for both foreground and background scenarios
- **Local Notifications**: flutter_local_notifications displays system notifications with proper channels and importance
- **In-App Notifications**: When a task is assigned, an attractive Flushbar notification appears immediately on the assigner's device
- **FCM Token**: The app retrieves FCM tokens for users (tokens are logged for backend integration)
- **Background Handling**: Firebase handles messages when app is closed/terminated (when configured), with local notifications for consistency
- **Logging**: All notification requests are logged for debugging and future backend integration

### Production Implementation
✅ **COMPLETED**: Backend server now stores FCM tokens for users
✅ **COMPLETED**: Mobile app sends FCM tokens to backend on app startup and token refresh
⚠️ **PENDING**: Backend needs to send FCM push notifications to assignees when tasks are assigned

**Remaining Backend Tasks**:
1. When a task is assigned, send FCM push notifications to the **assignee's** device (not the assigner's)
2. Use Firebase Cloud Messaging API to send notifications with proper payload structure
3. Handle token updates and cleanup

**Current Status**: The mobile app now sends FCM tokens to the backend. Assignees will receive notifications once the backend implements FCM message sending.

**Backend FCM Message Structure**:
```json
{
  "to": "assignee_fcm_token",
  "notification": {
    "title": "New Task Assigned",
    "body": "You have been assigned: [task_title]"
  },
  "data": {
    "type": "task_assigned",
    "task_title": "[task_title]",
    "assigned_by": "[assigner_name]",
    "employee_id": "[assignee_id]"
  }
}
```

## Testing

To test the implementation:

1. **Install dependencies**: `flutter pub get`
2. **Run the app on two devices**:
   - Device 1: Log in as the assigner (admin/manager)
   - Device 2: Log in as the assignee (employee)
3. **Check FCM tokens**: Both devices automatically send FCM tokens to backend on startup
4. **Test local notifications**: Tap the notification bell icon in dashboard to verify notification drawer works
5. **Assign a task**: From Device 1, assign a task to the employee on Device 2
6. **Check notifications**:
   - Device 1 (assigner): Should see in-app notification
   - Device 2 (assignee): Should receive push notification in notification drawer

**Important**: Both users must log in on their respective devices so their FCM tokens are stored in the backend.

**Note**: FCM tokens are automatically sent to your backend API at `https://hp.triz.co.in/api/update-fcm-token` when users log in.

**Note**: Currently, only the task assigner receives notifications. The assignee will receive notifications once the backend server sends FCM messages to their device.

## Future Enhancements

1. **Backend Integration**: Server-side push notification sending
2. **User Token Management**: Store and manage FCM tokens in database
3. **Notification History**: Store sent notifications for analytics
4. **Rich Notifications**: Add images, actions, and deep linking
5. **Notification Settings**: Allow users to customize notification preferences

## Technical Details

### Notification Flow
1. User assigns task via `task_assignment_progress_screen.dart`
2. `assignTask` API call succeeds
3. Flushbar notification appears immediately on assigner's device
4. `NotificationService.sendPushNotification()` logs the request for backend integration
5. FCM handles background messages when app is closed (when Firebase is configured)

### Permissions
- Android: `POST_NOTIFICATIONS`, `VIBRATE`, `INTERNET`
- iOS: Will require notification permissions (not yet implemented)

### Dependencies
- `firebase_core: ^2.24.2`
- `firebase_messaging: ^14.7.10`
- `another_flushbar: ^1.12.30`
- `flutter_local_notifications: ^17.0.0`