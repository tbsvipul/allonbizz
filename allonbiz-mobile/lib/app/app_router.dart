import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/auth_screens.dart';
import '../features/discover/detail_screens.dart';
import '../features/discover/discover_screen.dart';
import '../features/home/home_screen.dart';
import '../features/navigate/map_screen.dart';
import '../features/navigate/search_screen.dart';
import '../features/profile/profile_screens.dart';
import '../features/trips/trips_screen.dart';
import 'providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);
  const publicPaths = {
    '/splash',
    '/onboarding',
    '/login',
    '/register',
    '/forgot-password',
    '/verify-otp',
    '/reset-password',
  };

  return GoRouter(
    initialLocation: _initialLocationFor(auth),
    refreshListenable: auth,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.uri.path;

      if (!authState.initialized) {
        return location == '/splash' ? null : '/splash';
      }

      if (!authState.isAuthenticated) {
        if (!authState.hasSeenOnboarding) {
          return location == '/onboarding' ? null : '/onboarding';
        }
        return publicPaths.contains(location) ? null : '/login';
      }

      if (publicPaths.contains(location)) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const SplashScreen(statusText: 'Checking session...'),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => OtpVerificationScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          initialToken: state.uri.queryParameters['token'],
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
                routes: [
                  GoRoute(
                    path: 'search',
                    builder: (context, state) => const SearchScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationScreen(),
                  ),
                  GoRoute(
                    path: 'journeys',
                    builder: (context, state) => const PastJourneysScreen(),
                  ),
                  GoRoute(
                    path: 'saved',
                    builder: (context, state) => const SavedOffersScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/offer/:offerId',
        builder: (context, state) =>
            OfferDetailScreen(offerId: state.pathParameters['offerId']!),
      ),
      GoRoute(
        path: '/shop/:shopId',
        builder: (context, state) =>
            ShopDetailScreen(shopId: state.pathParameters['shopId']!),
      ),
      GoRoute(
        path: '/trips',
        builder: (context, state) =>
            TripsScreen(journeyId: state.uri.queryParameters['journeyId']),
      ),
    ],
  );
});

String _initialLocationFor(AuthController auth) {
  if (!auth.initialized) {
    return '/splash';
  }

  if (auth.isAuthenticated) {
    return '/home';
  }

  return auth.hasSeenOnboarding ? '/login' : '/onboarding';
}

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
