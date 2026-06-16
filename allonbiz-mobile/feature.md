# routent Mobile Application - Screen Features

This document outlines the core functional features of each screen in the `routent-mobile` application, focusing entirely on functionality and business logic rather than UI/UX representation.

## Authentication & Onboarding
*   **Splash Screen (`splash_screen.dart`)**
    *   Initializes core application services.
    *   Verifies existing user session/authentication state.
    *   Routes the user to either the Onboarding, Login, or Home screen based on session validity.
*   **Onboarding Screen (`onboarding_screen.dart`)**
    *   Educates new users about the core value propositions of the app (e.g., discovering offers, journey tracking).
    *   Handles the first-time user experience flags to prevent re-displaying on subsequent app launches.
*   **Login Screen (`login_screen.dart`)**
    *   Authenticates existing users via email/username and password.
    *   Validates user credentials against the backend authentication service.
    *   Manages secure token storage upon successful authentication.
*   **Register Screen (`register_screen.dart`)**
    *   Captures new user information for account creation.
    *   Validates input data (e.g., email format, password strength).
    *   Submits registration data to the backend to provision a new user account.
*   **Forgot Password Screen (`forgot_password_screen.dart`)**
    *   Initiates the password recovery workflow.
    *   Requests a password reset link or OTP to be sent to the user's registered email/phone.

## Home & Dashboard
*   **Home Screen (`home_screen.dart`)**
    *   Acts as the central dashboard aggregating data from various modules.
    *   Retrieves and displays a summarized view of recent user journeys.
    *   Fetches and highlights top or personalized offers for quick access.

## Discover & Offers
*   **Discover Screen (`discover_screen.dart`)**
    *   Queries and aggregates a list of available shops and active promotional offers.
    *   Applies filtering and sorting logic to help users find relevant content.
*   **Offer Detail Screen (`offer_detail_screen.dart`)**
    *   Retrieves comprehensive data about a specific offer (validity dates, terms, description).
    *   Handles the logic for offer interaction, such as saving/bookmarking the offer or tracking its proximity status.
*   **Shop Detail Screen (`shop_detail_screen.dart`)**
    *   Fetches the profile and metadata of a specific merchant or shop.
    *   Loads all active offers specifically associated with that merchant.

## Navigation & Tracking
*   **Map Screen (`map_screen.dart`)**
    *   Handles real-time GPS location tracking and synchronization.
    *   Manages journey states (e.g., Free Roam vs. Active Route).
    *   Triggers proximity calculations to detect when a user is near a registered offer or landmark.
    *   Processes reverse geocoding to resolve coordinates into readable landmark names.
*   **Search Screen (`search_screen.dart`)**
    *   Queries location or points of interest (POI) databases based on user input.
    *   Returns geocoded coordinates for selected destinations to initiate new journeys.

## Trips & Journeys
*   **Trips Screen (`trips_screen.dart`)**
    *   Manages the active or planned trips.
    *   Coordinates the start, pause, or end functionalities of a tracking session.

## Profile & Settings
*   **Profile Screen (`profile_screen.dart`)**
    *   Fetches and serves as the central hub for the user's account details and statistics.
    *   Handles user logout logic and session termination.
*   **Edit Profile Screen (`edit_profile_screen.dart`)**
    *   Allows modification of user-specific metadata (e.g., name, contact info).
    *   Validates and synchronizes updated profile data with the backend servers.
*   **Change Password Screen (`change_password_screen.dart`)**
    *   Securely updates the user's authentication credentials.
    *   Validates old password before authorizing a change to the new password.
*   **Notification Screen (`notification_screen.dart`)**
    *   Retrieves the history of system alerts and proximity notifications.
    *   Manages the read/unread status of individual notification items.
*   **Past Journeys Screen (`past_journeys_screen.dart`)**
    *   Queries the backend for a historical log of completed journeys.
    *   Provides pagination or chronological sorting of the user's travel history.
*   **Journey Detail Screen (`journey_detail_screen.dart`)**
    *   Fetches granular metrics for a single completed journey (e.g., distance, duration, route data).
    *   Processes and structures the analytical data for review.
*   **Saved Offers Screen (`saved_offers_screen.dart`)**
    *   Retrieves the specific list of promotional offers the user has explicitly bookmarked.
    *   Provides management features like removing an offer from the saved list.

## System & Shared
*   **App Error Screen (`app_error_screen.dart`)**
    *   Acts as a global error boundary for the application.
    *   Captures unhandled exceptions and routing failures.
    *   Provides functional fallback options (like "Retry" or "Return Home") to recover from app failures.
