import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../providers/app_bar_provider.dart';
import '../../features/profile/data/repositories/notifications_repository.dart';
import '../../shared/widgets/app_glass.dart';
import 'custom_navbar.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onTabSelected;
  final bool showNavBar;
  final bool showAppBar;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
    this.showNavBar = true,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use specific title if provided, else use index-based default
    // MOVED inside Consumer below to support reactive state narrowing

    return GradientBackground(
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: (showAppBar)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: Consumer(
                  builder: (context, ref, child) {
                    final appBarConfig = ref.watch(appBarProvider);
                    if (!appBarConfig.showAppBar) return const SizedBox.shrink();

                    final colorScheme = Theme.of(context).colorScheme;
                    final titleColor = isDark ? AppColors.pearl : AppColors.ink;
                    final Widget titleWidget =
                        appBarConfig.title ??
                        _getDefaultTitle(currentIndex, l10n);

                    return AppBar(
                      title: titleWidget,
                      actions: [
                        if (appBarConfig.actions != null)
                          ...appBarConfig.actions!,
                        Consumer(
                          builder: (context, ref, child) {
                            final unreadCountAsync = ref.watch(
                              unreadNotificationCountProvider,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      (isDark
                                              ? AppColors.surfaceElevatedDark
                                              : AppColors.white)
                                          .withValues(alpha: 0.88),
                                  foregroundColor: titleColor,
                                  minimumSize: const Size(46, 46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                                icon: Badge(
                                  isLabelVisible:
                                      unreadCountAsync.valueOrNull != null &&
                                      unreadCountAsync.valueOrNull! > 0,
                                  label: Text(
                                    '${unreadCountAsync.valueOrNull ?? 0}',
                                  ),
                                  backgroundColor: AppColors.error,
                                  child: const Icon(
                                    Icons.notifications_none_rounded,
                                  ),
                                ),
                                onPressed: () {
                                  context.push(AppRoutes.notifications).then((_) {
                                    ref.invalidate(
                                      unreadNotificationCountProvider,
                                    );
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ],
                      leading: appBarConfig.leading,
                      backgroundColor: appBarConfig.backgroundColor ?? Colors.transparent,
                      foregroundColor: titleColor,
                      iconTheme: IconThemeData(color: titleColor),
                      actionsIconTheme: IconThemeData(color: titleColor),
                      titleTextStyle: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                      centerTitle: appBarConfig.centerTitle,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      surfaceTintColor: Colors.transparent,
                      systemOverlayStyle: isDark
                          ? SystemUiOverlayStyle.light
                          : SystemUiOverlayStyle.dark,
                    );
                  },
                ),
              )
            : null,
        body: child,
        bottomNavigationBar: showNavBar
            ? CustomNavBar(currentIndex: currentIndex, onTap: onTabSelected)
            : null,
      ),
    );
  }

  Widget _getDefaultTitle(int index, AppLocalizations l10n) {
    if (index == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/tranperentlogo.png', height: 60),
          const SizedBox(width: 8),
          Text(l10n.appName),
        ],
      );
    }

    String title;
    switch (index) {
      case 1:
        title = l10n.navNavigate;
        break;
      case 2:
        title = l10n.navDiscover;
        break;
      case 3:
        title = l10n.profile; // Index 3 is Profile in app_router
        break;
      default:
        title = l10n.appName;
    }
    return Text(title);
  }
}
