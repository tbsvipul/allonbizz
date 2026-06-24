import 'dart:convert';
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
                        backgroundImage: user?.photoUrl != null && user!.photoUrl!.startsWith('data:image')
                            ? MemoryImage(base64Decode(user.photoUrl!.split(',').last)) as ImageProvider
                            : null,
                        child: (user?.photoUrl == null || !user!.photoUrl!.startsWith('data:image'))
                            ? Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: AppColors.secondaryLight,
                              )
                            : null,
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


                // Location Marker Preference
                ProfileTileWidget(
                  icon: Icons.person_pin_circle_rounded,
                  title: 'Location Marker',
                  trailing: DropdownMenu<String>(
                    initialSelection: ref.watch(locationMarkerProvider),
                    leadingIcon: ref.watch(locationMarkerProvider) == 'ripple'
                        ? const Icon(Icons.my_location_rounded, size: 20, color: AppColors.primary)
                        : Image.asset('assets/images/location_marker/${ref.watch(locationMarkerProvider)}', width: 20, height: 20),
                    width: 160,
                    menuStyle: MenuStyle(
                      backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    textStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    inputDecorationTheme: const InputDecorationTheme(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      isDense: true,
                    ),
                    onSelected: (val) {
                      if (val != null) {
                        ref.read(locationMarkerProvider.notifier).setMarker(val);
                      }
                    },
                    dropdownMenuEntries: [
                      DropdownMenuEntry(
                        value: 'ripple',
                        label: 'Ripple',
                        leadingIcon: const Icon(
                          Icons.my_location_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      DropdownMenuEntry(
                        value: 'blue_car.png',
                        label: 'Blue Car',
                        leadingIcon: Image.asset(
                          'assets/images/location_marker/blue_car.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      DropdownMenuEntry(
                        value: 'man.png',
                        label: 'Man',
                        leadingIcon: Image.asset(
                          'assets/images/location_marker/man.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      DropdownMenuEntry(
                        value: 'weman.png',
                        label: 'Woman',
                        leadingIcon: Image.asset(
                          'assets/images/location_marker/weman.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      DropdownMenuEntry(
                        value: 'yellow_car.png',
                        label: 'Yellow Car',
                        leadingIcon: Image.asset(
                          'assets/images/location_marker/yellow_car.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ],
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
                  trailing: DropdownMenu<String>(
                    initialSelection: ref.watch(localeProvider).languageCode,
                    width: 140,
                    menuStyle: MenuStyle(
                      backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    textStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    inputDecorationTheme: const InputDecorationTheme(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      isDense: true,
                    ),
                    onSelected: (val) {
                      if (val != null) {
                        ref.read(localeProvider.notifier).setLocale(val);
                      }
                    },
                    dropdownMenuEntries: LocaleNotifier.supportedLanguages.entries.map((entry) {
                      return DropdownMenuEntry(
                        value: entry.key,
                        label: entry.value,
                      );
                    }).toList(),
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
