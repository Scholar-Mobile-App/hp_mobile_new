# Firebase Configuration (Optional)

**Important:** Firebase setup is optional. The app will work without Firebase, but push notifications will only work locally. Follow these steps to enable full push notifications.

## Configuration Files Required

For Android: Place `google-services.json` in `android/app/`
For iOS: Place `GoogleService-Info.plist` in `ios/Runner/`

## Setup Steps

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Enable Firebase Cloud Messaging in the console
4. Add Android app with package name: `com.triz.g2g`
5. Download `google-services.json` and place in `android/app/`
6. Add iOS app with bundle ID: `com.example.g2gMobile`
7. Download `GoogleService-Info.plist` and place in `ios/Runner/`

## Without Firebase

If you don't set up Firebase:
- App runs normally
- Task assignment works
- Local notifications show on assigner's device
- Push notifications to other devices won't work
- Background notifications won't work when app is closed

## With Firebase

When Firebase is properly configured:
- Push notifications work when app is closed
- Cross-device notifications work
- Background message handling works
- Full notification functionality available