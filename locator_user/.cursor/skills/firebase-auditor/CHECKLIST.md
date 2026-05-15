# Firebase Auditor Checklist (Flutter)

## Config & build wiring
- [ ] `android/app/google-services.json` exists
- [ ] `android/app/build.gradle.kts` applies `com.google.gms.google-services`
- [ ] `android/settings.gradle.kts` declares plugin version `apply false`
- [ ] `android/app/build.gradle.kts` `applicationId` matches Firebase Android app package
- [ ] `lib/firebase_options.dart` exists and contains Android `appId`
- [ ] `lib/main.dart` initializes Firebase with `DefaultFirebaseOptions.currentPlatform`

## Firebase Console prerequisites (cannot be validated locally)
- [ ] Auth provider enabled (Email/Password)
- [ ] Firestore created
- [ ] Firestore rules allow the app’s reads/writes

## Auth flow
- [ ] `authStateChanges()` gate exists
- [ ] Register creates user and handles common errors
- [ ] Login signs in and handles common errors
- [ ] Logout implemented

## Firestore profile flow
- [ ] On register: upsert `users/{uid}` with required fields
- [ ] On login: set `lastLoginAt` (and `updatedAt`)
- [ ] Home/profile screen reads `users/{uid}` and renders data
- [ ] Missing doc fallback is safe (doesn’t crash)

## Profile image URL
- [ ] If using external image hosting (e.g., Cloudinary), app stores only the returned URL in Firestore
- [ ] No API secrets stored in client
- [ ] Upload method matches hosting requirements (e.g., unsigned upload preset for Cloudinary)

