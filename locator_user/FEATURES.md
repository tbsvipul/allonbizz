# 🚀 allonbiz - Feature Ecosystem

allonbiz is a state-of-the-art navigation and discovery platform designed to bridge the gap between getting to a destination and discovering valuable opportunities along the way.

---

## 📍 1. Smart Navigation & Pathfinding
Master your journey with precision and flexibility.
*   **Intelligent Search**: Find origins and destinations using a professional autocomplete system powered by the **Photon API**.
*   **Dynamic Routing**: Real-time route generation between any two coordinates with smart fallbacks.
*   **Journey Lifecycle**: A dedicated "Start Journey" workflow that initializes UI navigation and backend tracking simultaneously.
*   **Real-time Tracking**: Live GPS positioning mapped against predicted routes.

## 🔍 2. Dynamic Discovery Engine
Discover what matters to you, perfectly synced with your route.
*   **Backend Integration**: All categories, tags, and points of interest are managed dynamically via a custom **ASP.NET Core Backend API**.
*   **Triple-Row Horizontal Grid**: A premium, high-performance category browser allowing users to swipe through 30+ interests (ATM, Food, Petrol, etc.) seamlessly.
*   **Smart Keyword Mapper**: Type any custom interest, and the app automatically assigns relevant Material Icons and filters based on your text.
*   **Interest-Based Filtering**: Only see the markers and deals that match your selected tags.

## 🌍 3. Free Roam Mode
Exploration without boundaries.
*   **Destination-less Search**: Start a "Free Roam" session to discover nearby deals and facilities without a fixed route.
*   **Proximity Discovery**: Automatically detects and notifies you of points of interest within a configurable radius of your live position.

## 📊 4. Journey Analytics & History
Every trip tells a story. Securely recorded and easily accessible.
*   **Rich Metadata**: Every journey records:
    *   **Coordinates**: Start and end locations.
    *   **Timestamps**: Exact start and completion times.
    *   **Logistics**: Automatically calculated distance (meters) and duration (seconds).
    *   **Labels**: Human-readable location names for easy browsing.
*   **Trip History**: A dedicated `Trips` feature module to review past journeys and exported route data.

## 🎨 5. Premium UI/UX Implementation
Designed for a smooth, modern, and "alive" feel.
*   **Interactive NavBar**: A custom-built bottom navigation system featuring a floating, state-aware "Start/End Journey" button.
*   **Micro-Animations**: Extensive use of `flutter_animate`, `Lottie`, and `Shimmer` for a professional, high-end feel.
*   **Dynamic Themes**: Seamless switching between curated Dark and Light modes with deep brand integration.
*   **Responsive Interest Chips**: Premium animated chips that react to user interaction with smooth color and size transitions.

## 🛡️ 6. Technical Excellence & Security
Solid foundations for a production-ready experience.
*   **Custom Auth API**:
    *   **Secure Identity**: Email/Password registration and login handled by the ASP.NET backend.
    *   **JWT Protection**: All data-writing features are protected by JSON Web Tokens.
    *   **PostgreSQL Persistence**: Durable and scalable relational database for all user profiles, trips, and offers.
*   **Background Intelligence**: Utilizes `flutter_background_service` and `geolocator` for persistent tracking even when the app is minimized.
*   **State Management**: Powered by **Riverpod** for a predictable, high-performance architecture.

## ⚙️ 7. Configuration & Integrations
The technical stack and external services powering the application.

### 🔑 API Keys & Identifiers
*   **Google Maps API**: Used for platform-specific services (Map rendering).
*   **Photon API**: Open-source API used for search autocomplete and reverse geocoding.
*   **OSRM Routing Engine**: Project OSRM used for real-time driving polyline generation.

### 🔗 Integrated Services
*   **Maps & Geodata**:
    *   **OpenStreetMap**: Custom map tiles rendered via `flutter_map`.
    *   **Photon (Komoot)**: Search and reverse geocoding engine.
    *   **OSRM**: Road-routing and distance/duration calculations.
*   **Backend Stack**:
    *   **ASP.NET Core**: Primary API handling business logic and auth.
    *   **PostgreSQL**: Relational DB for users, trips, and offers.
    *   **JWT**: Secure, stateless authentication.
*   **Locality & Persistence**:
    *   **Hive**: High-performance local caching for offline support.
    *   **Geolocator**: Precision GPS handling.
    *   **Background Services**: Reliable background location tracking.

---
*Created with ❤️ for the Locator Project.*
