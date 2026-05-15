# Locator (allonbiz User App)

Flutter app integrated with a custom **ASP.NET Core Backend API**, utilizing **PostgreSQL** for data storage and **JWT (JSON Web Tokens)** for secure authentication.

## Backend setup
- Ensure the ASP.NET API is running.
- Update the `.env` file with your `API_BASE_URL`.

## Getting Started

1.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
2.  **Environment Variables**:
    Create a `.env` file in the root directory (copy from `.env.example` if available) and set your `API_BASE_URL`.
3.  **Run the app**:
    ```bash
    flutter run
    ```

## Authentication
The application uses a custom identity system on the backend. Authentication flows include:
- **Login**: `/api/v1/auth/user-login`
- **Registration**: `/api/v1/auth/register-user`
- **Profile**: `/api/v1/user/profile`

## Features
- **Smart Navigation**: Discover deals and shops along your route.
- **Dynamic Tags & Categories**: Managed via the Admin Panel and synchronized in real-time.
- **Loyalty System**: Earn points and track savings (managed by the backend).
