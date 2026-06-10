import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/home_repository.dart';
import 'deal_section_widget.dart';

/// Async home offers section with consistent loading and error states.
class HomeOffersSection extends ConsumerWidget {
  const HomeOffersSection({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final user = ref.watch(authControllerProvider).user;

    if (user == null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppDimensions.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Center(
            child: Text(
              'No offers available right now',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    return ref
        .watch(homeOffersProvider)
        .when(
          data: (deals) => DealSectionWidget(
            title: l10n.bestDealsNearby,
            icon: Icons.local_offer_rounded,
            iconColor: colorScheme.primary,
            deals: deals,
            l10n: l10n,
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(AppDimensions.xl),
            child: Center(child: AppLoader.inline(size: AppDimensions.iconLg)),
          ),
          error: (error, stackTrace) => AppErrorWidget(
            title: 'Unable to load deals',
            message: 'Please try again to refresh nearby recommendations.',
            onRetry: () => ref.invalidate(homeOffersProvider),
          ),
        );
  }
}
