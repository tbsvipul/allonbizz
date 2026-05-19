import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_stat_item.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../navigate/presentation/controllers/navigation_controller.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/theme_mode_provider.dart';
import '../../../../core/services/locale_provider.dart';
import '../widgets/profile_tile_widget.dart';
import '../widgets/profile_switch_tile_widget.dart';
import '../widgets/profile_vertical_divider_widget.dart';
import '../../../../core/services/preference_providers.dart';
import 'edit_profile_screen.dart';

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
    final String loyaltyPoints = '${user?.loyaltyPoints ?? 0}';
    final String tripsCount = '${user?.totalTrips ?? 0}';
    final String totalSaved =
        '\$${(user?.totalSaved ?? 0.0).toStringAsFixed(2)}';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // AppBar title is managed by MainLayout based on current index.

    return CustomScrollView(
      slivers: [
        // ── Profile Banner Section ───────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.xl),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.surface,
                    child: Icon(
                      Icons.person_rounded,
                      size: 50,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white.withValues(alpha: 0.2),
                      foregroundColor: AppColors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              children: [
                // Loyalty Stats
                AppSurface(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  borderColor: AppColors.tierGold.withValues(alpha: 0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AppStatItem(
                        label: l10n.totalSaved,
                        value: totalSaved,
                        valueStyle: textTheme.titleMedium?.copyWith(
                          color: AppColors.tierGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const ProfileVerticalDividerWidget(),
                      AppStatItem(
                        label: l10n.points,
                        value: loyaltyPoints,
                        valueStyle: textTheme.titleMedium?.copyWith(
                          color: AppColors.tierGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const ProfileVerticalDividerWidget(),
                      AppStatItem(
                        label: l10n.trips,
                        value: tripsCount,
                        valueStyle: textTheme.titleMedium?.copyWith(
                          color: AppColors.tierGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: AppDimensions.xxl),

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
                  icon: Icons.security_rounded,
                  title: l10n.privacySecurity,
                  onTap: () {},
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
                  icon: Icon(
                    Icons.logout_rounded,
                    color: colorScheme.error,
                  ),
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
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }
}
