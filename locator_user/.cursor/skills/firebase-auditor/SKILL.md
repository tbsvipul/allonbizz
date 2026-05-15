---
name: firebase-auditor
description: Audits a Flutter project’s Firebase integration (firebase_core initialization, firebase_options.dart, google-services.json, Android Gradle Google Services plugin, Auth + Firestore usage, profile storage schema, and related UI screens). Use when the user asks to verify Firebase setup, troubleshoot Firebase errors, or review Firebase-related features/files/screens.
---

# Firebase Auditor (Flutter)

## Goal
Verify that Firebase is correctly connected and that Firebase-related features (Auth, Firestore, profile storage, and profile image URL storage) are wired end-to-end.

## Scope (what to check)
- Flutter deps: `firebase_core`, `firebase_auth`, `cloud_firestore` (and any feature-specific deps like `image_picker`, `http`)
- Firebase initialization: `main.dart` calls `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
- Generated config: `lib/firebase_options.dart` exists and contains Android `appId` matching expected Firebase app
- Android config file: `android/app/google-services.json` exists
- Android Gradle wiring (KTS):
  - `android/settings.gradle.kts` declares `com.google.gms.google-services` plugin version `apply false`
  - `android/app/build.gradle.kts` applies `id("com.google.gms.google-services")`
  - `android/app/build.gradle.kts` `applicationId` matches the package name used when registering the Firebase Android app
- Auth flow:
  - Login/register UI present and reachable
  - `FirebaseAuth` calls for create/sign-in
  - `AuthGate` or routing based on `authStateChanges()`
  - Logout
- Firestore profile:
  - `users/{uid}` document created/merged on register
  - `lastLoginAt` updated on login
  - Profile fields present per current schema
  - Defensive handling when profile doc missing
- Firestore rules assumptions:
  - Flag if the app expects rules allowing users to read/write their own profile doc
- Known pitfalls:
  - Missing/misplaced `google-services.json`
  - AppId/package mismatch
  - Not enabling Email/Password sign-in in Firebase Console
  - Firestore not created / rules blocking reads/writes
  - Web/Windows config present but not initialized with options

## Workflow
1. Identify stack
   - Confirm Flutter project (presence of `pubspec.yaml`, `lib/`).
2. Inventory Firebase-related files
   - `pubspec.yaml`
   - `lib/main.dart`
   - `lib/firebase_options.dart`
   - `android/app/google-services.json`
   - `android/settings.gradle.kts`
   - `android/app/build.gradle.kts`
   - Firebase feature files (Auth screens, repositories, services)
3. Static checks
   - Ensure imports compile, no analyzer errors, and initialization uses `DefaultFirebaseOptions.currentPlatform`.
4. Feature checks
   - Auth: register/login/logout flows and UX error handling.
   - Firestore: write path, merge behavior, timestamps, schema stability.
5. Produce report
   - Use the report template below.
6. If problems are found
   - Propose minimal code changes and exact file edits.
   - Suggest Firebase Console actions only when unavoidable (e.g., enabling provider, Firestore rules).

## Report template (use this)
### Firebase Audit Report
- **Status**: PASS / FAIL / PASS with warnings
- **App/package**:
  - **Android `applicationId`**: <value>
  - **Firebase Android `appId`**: <value from firebase_options.dart>
  - **google-services.json**: present/missing
- **Initialization**:
  - **main.dart**: ok/missing options
  - **firebase_options.dart**: ok/missing/outdated
- **Dependencies**: ok/missing
- **Auth**:
  - **Screens**: ok/missing
  - **Flows**: ok/issues
- **Firestore profile**:
  - **Doc path**: `users/{uid}` ok/issues
  - **Schema fields**: ok/issues
  - **lastLoginAt**: ok/missing
- **Security/rules assumptions**:
  - What rules are required for expected behavior
- **Required fixes**:
  - Bullet list with file paths
- **Optional improvements**:
  - Bullet list

## Notes
- Do not request secrets.
- Never store Firebase/Cloudinary secrets in the client app.
- If the user asks to “verify everything,” run `flutter analyze` after edits and ensure it is clean.

## Additional checklist
See [CHECKLIST.md](CHECKLIST.md).

