import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/navigate/presentation/screens/map_screen.dart';
import '../../features/navigate/presentation/screens/search_screen.dart';
import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/discover/presentation/screens/offer_detail_screen.dart';
import '../../features/discover/presentation/screens/shop_detail_screen.dart';
import '../../features/profile/presentation/screens/past_journeys_screen.dart';
import '../../features/profile/presentation/screens/notification_screen.dart';
import '../../features/profile/presentation/screens/saved_offers_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/journey_detail_screen.dart';
import '../../features/profile/presentation/screens/contact_support_screen.dart';
import '../../features/profile/presentation/screens/support_reply_screen.dart';
import '../../features/profile/data/repositories/notifications_repository.dart';
import '../../shared/screens/app_error_screen.dart';
import '../../shared/models/offer.dart';
import '../../core/models/journey_model.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/main_layout.dart';

/// A utility to bridge Streams (like Riverpod StateNotifier streams) to Listenable.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// GoRouter configuration with auth-aware routing restrictions.
final appRouterProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(storageServiceProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authControllerProvider.notifier).stream,
    ),
    redirect: (context, state) {
      // PRESERVED: splash/auth/onboarding redirects are tightly coupled to
      // session restoration and active journey recovery. Review carefully
      // before changing any branch in this block.
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.user != null;
      final hasResolvedSession = authState.hasResolvedSession;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isLogin = state.matchedLocation == AppRoutes.login;
      final isRegister = state.matchedLocation == AppRoutes.register;
      final isForgotPassword =
          state.matchedLocation == AppRoutes.forgotPassword;

      // Keep users on splash until API restores any persisted session.
      if (!hasResolvedSession) {
        return isSplash ? null : AppRoutes.splash;
      }

      // DO NOT route away from splash immediately via redirect!
      // We must wait for the 2.8s animation to finish.
      // SplashScreen widget will call context.go() when it's done.
      if (isSplash) {
        return null;
      }

      // If logged in, redirect away from auth pages
      if (isLoggedIn &&
          (isOnboarding || isLogin || isRegister || isForgotPassword)) {
        return storage.activeJourneySession != null
            ? AppRoutes.navigate
            : AppRoutes.home;
      }

      // If not logged in and not on auth pages, redirect to login
      if (!isLoggedIn &&
          !isOnboarding &&
          !isLogin &&
          !isRegister &&
          !isForgotPassword) {
        if (!storage.hasSeenOnboarding) return AppRoutes.onboarding;
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => SplashScreen(
          onComplete: () {
            // PRESERVED: SplashScreen owns the final transition after its
            // animation completes. Do not shortcut this in redirect().
            if (!context.mounted) return;
            final authState = ref.read(authControllerProvider);
            if (!authState.hasResolvedSession) return;
            final isLoggedIn = authState.user != null;
            if (isLoggedIn) {
              if (storage.activeJourneySession != null) {
                context.go(AppRoutes.navigate);
              } else {
                context.go(AppRoutes.home);
              }
            } else if (!storage.hasSeenOnboarding) {
              context.go(AppRoutes.onboarding);
            } else {
              context.go(AppRoutes.login);
            }
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => OnboardingScreen(
          onComplete: () {
            if (!context.mounted) return;
            storage.hasSeenOnboarding = true;
            context.go(AppRoutes.login);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => ForgotPasswordScreen(
          initialEmail: state.extra is String ? state.extra as String : null,
        ),
      ),

      // ── Main Shell (Bottom Nav) ─────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.navigate,
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.discover,
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    name: 'pastJourneys',
                    builder: (context, state) => const PastJourneysScreen(),
                  ),
                  GoRoute(
                    path: 'saved',
                    name: 'savedItems',
                    builder: (context, state) => const SavedOffersScreen(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    name: 'changePassword',
                    builder: (context, state) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'support',
                    name: 'contactSupport',
                    builder: (context, state) => const ContactSupportScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Search ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => MainLayout(
          currentIndex: -1,
          onTabSelected: (_) {},
          showNavBar: false,
          child: const SearchScreen(),
        ),
      ),

      // ── Offer Detail ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.offerDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          final initialOffer = state.extra as Offer?;

          return MainLayout(
            currentIndex: 2,
            onTabSelected: (_) {},
            showNavBar: false,
            child: OfferDetailScreen(offerId: id, initialOffer: initialOffer),
          );
        },
      ),
      // ── Shop Detail ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.shopDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return MainLayout(
            currentIndex: 2,
            onTabSelected: (_) {},
            showNavBar: false,
            child: ShopDetailScreen(shopId: id!),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => MainLayout(
          currentIndex: 3,
          onTabSelected: (_) {},
          showNavBar: false,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.journeyDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          final initialJourney = state.extra as JourneyModel?;

          return MainLayout(
            currentIndex: 3,
            onTabSelected: (_) {},
            showNavBar: false,
            child: JourneyDetailScreen(
              journeyId: id!,
              initialJourney: initialJourney,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.supportReply,
        builder: (context, state) => SupportReplyScreen(
          notification: state.extra is UserNotification
              ? state.extra as UserNotification
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.error,
        builder: (context, state) => const AppErrorScreen(),
      ),
    ],
  );
});

class _MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _MainShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final hideAppBar =
        navigationShell.currentIndex == 1 || location == AppRoutes.pastJourneys;

    return MainLayout(
      currentIndex: navigationShell.currentIndex,
      onTabSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      showAppBar: !hideAppBar, // Hide AppBar on MapScreen and PastJourneys
      child: navigationShell,
    );
  }
}
