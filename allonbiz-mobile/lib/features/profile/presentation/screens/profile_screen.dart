import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../navigate/presentation/controllers/navigation_controller.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/theme_mode_provider.dart';
import '../../../../core/services/locale_provider.dart';
import '../widgets/profile_tile_widget.dart';
import '../widgets/profile_switch_tile_widget.dart';
import '../../../../core/services/preference_providers.dart';
import '../../../../shared/widgets/app_glass.dart';

/// User profile, statistics, and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider.select((s) => s.user));

    // Derived stats or defaults
    final String displayName = user?.displayName ?? 'Guest User';
    final String displayEmail = user?.email ?? 'Not signed in';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // AppBar title is managed by MainLayout based on current index.

    return CustomScrollView(
      slivers: [
        // ── Profile Banner Section ───────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: GlassmorphicContainer(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.xl),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.white.withValues(
                          alpha: 0.22,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayEmail,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.editProfile),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white.withValues(
                            alpha: 0.2,
                          ),
                          foregroundColor: AppColors.white,
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              children: [
                // ── Preferences ────────────────────────────────────
                AppSectionHeader(
                  title: l10n.preferences,
                  padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                ),

                ProfileSwitchTileWidget(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  value: ref.watch(
                    themeModeProvider.select((s) => s == ThemeMode.dark),
                  ),
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).setDarkMode(val);
                  },
                ),
                ProfileSwitchTileWidget(
                  icon: Icons.notifications_active_rounded,
                  title: l10n.notifications,
                  value: ref.watch(notificationsEnabledProvider),
                  onChanged: (val) {
                    ref.read(notificationsEnabledProvider.notifier).toggle(val);
                  },
                ),
                ProfileSwitchTileWidget(
                  icon: Icons.location_on_rounded,
                  title: l10n.navNavigate, // Using navNavigate as placeholder
                  value: ref.watch(locationTrackingEnabledProvider),
                  onChanged: (val) {
                    ref
                        .read(locationTrackingEnabledProvider.notifier)
                        .toggle(val);
                  },
                ),
                // Discovery Radius Preference
                ProfileTileWidget(
                  icon: Icons.radar_rounded,
                  title: 'Discovery Radius',
                  trailing: DropdownButton<double>(
                    value: ref.watch(discoveryRadiusProvider),
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [500.0, 1000.0, 2000.0, 5000.0].map((radius) {
                      return DropdownMenuItem(
                        value: radius,
                        child: Text('${(radius / 1000).toStringAsFixed(1)} km'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(discoveryRadiusProvider.notifier).state = val;
                      }
                    },
                  ),
                ),

                // Location Marker Preference
                ProfileTileWidget(
                  icon: Icons.person_pin_circle_rounded,
                  title: 'Location Marker',
                  trailing: DropdownButton<String>(
                    value: ref.watch(locationMarkerProvider),
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'ripple',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.my_location_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text('Ripple'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'blue_car.png',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/location_marker/blue_car.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('Blue Car'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'man.png',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/location_marker/man.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('Man'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'weman.png',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/location_marker/weman.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('Woman'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'yellow_car.png',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/location_marker/yellow_car.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('Yellow Car'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(locationMarkerProvider.notifier)
                            .setMarker(val);
                      }
                    },
                  ),
                ),

                const SizedBox(height: AppDimensions.xl),

                // ── Account ────────────────────────────────────────
                AppSectionHeader(
                  title: l10n.account,
                  padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                ),

                ProfileTileWidget(
                  icon: Icons.email_rounded,
                  title: l10n.email,
                  subtitle: displayEmail,
                ),
                ProfileTileWidget(
                  icon: Icons.bookmark_rounded,
                  title: 'Saved Items',
                  onTap: () => context.push(AppRoutes.savedItems),
                ),
                ProfileTileWidget(
                  icon: Icons.history_rounded,
                  title: l10n.pastJourneys,
                  onTap: () => context.push(AppRoutes.pastJourneys),
                ),
                ProfileTileWidget(
                  icon: Icons.lock_reset_rounded,
                  title: 'Change Password',
                  onTap: () => context.push(AppRoutes.changePassword),
                ),
                ProfileTileWidget(
                  icon: Icons.security_rounded,
                  title: l10n.privacySecurity,
                  onTap: () {},
                ),
                ProfileTileWidget(
                  icon: Icons.support_agent_rounded,
                  title: 'Contact Support',
                  onTap: () => context.push(AppRoutes.contactSupport),
                ),

                const SizedBox(height: AppDimensions.xl),

                // ── Regional ───────────────────────────────────────
                const AppSectionHeader(
                  title: 'Regional Settings',
                  padding: EdgeInsets.only(bottom: AppDimensions.sm),
                ),

                // App Language Preference
                ProfileTileWidget(
                  icon: Icons.language_rounded,
                  title: 'App Language',
                  trailing: DropdownButton<String>(
                    value: ref.watch(localeProvider).languageCode,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    items: LocaleNotifier.supportedLanguages.entries.map((
                      entry,
                    ) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(localeProvider.notifier).setLocale(val);
                      }
                    },
                  ),
                ),

                const SizedBox(height: AppDimensions.xl),

                // ── Logout ──────────────────────────────────────────
                TextButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                  icon: Icon(Icons.logout_rounded, color: colorScheme.error),
                  label: Text(
                    l10n.signOut,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: 188 + MediaQuery.of(context).padding.bottom,
          ),
        ),
      ],
    );
  }
}
