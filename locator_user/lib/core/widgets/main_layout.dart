import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/app_routes.dart';
import '../constants/app_colors.dart';
import '../providers/app_bar_provider.dart';
import 'package:locator/l10n/app_localizations.dart';
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

    return Scaffold(
      extendBody: true,
      appBar: (showAppBar)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Consumer(
                builder: (context, ref, child) {
                  final appBarConfig = ref.watch(appBarProvider);
                  if (!appBarConfig.showAppBar) return const SizedBox.shrink();

                  final Widget titleWidget =
                      appBarConfig.title ?? _getDefaultTitle(currentIndex, l10n);

                  return AppBar(
                    title: titleWidget,
                    actions: [
                      if (appBarConfig.actions != null) ...appBarConfig.actions!,
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded),
                        onPressed: () {
                          context.push(AppRoutes.notifications);
                        },
                      ),
                    ],
                    leading: appBarConfig.leading,
                    backgroundColor:
                        appBarConfig.backgroundColor ??
                        (isDark ? AppColors.surfaceDark : AppColors.white),
                    centerTitle: appBarConfig.centerTitle,
                    elevation: 0,
                  );
                },
              ),
            )
          : null,
      body: child,
      bottomNavigationBar: showNavBar
          ? CustomNavBar(currentIndex: currentIndex, onTap: onTabSelected)
          : null,
    );
  }

  Widget _getDefaultTitle(int index, AppLocalizations l10n) {
    String title;
    switch (index) {
      case 0:
        title = l10n.navHome;
        break;
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
