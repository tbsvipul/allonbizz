import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/repositories/notifications_repository.dart';

class SupportReplyScreen extends StatelessWidget {
  const SupportReplyScreen({super.key, required this.notification});

  final UserNotification? notification;

  @override
  Widget build(BuildContext context) {
    final notification = this.notification;

    if (notification == null) {
      return const Scaffold(
        body: GradientBackground(
          child: AppEmptyState(
            title: 'Reply not available',
            subtitle: 'Open this reply again from your notifications.',
            icon: Icons.support_agent_rounded,
          ),
        ),
      );
    }

    final subject = notification.supportSubject ?? notification.title;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Support Reply')),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              Text(
                subject,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                DateFormat.yMMMd().add_jm().format(notification.sentAt),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.grey500,
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Text(
                          'Admin message',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      notification.message,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              AppButton.primary(
                label: 'Contact support',
                icon: Icons.reply_rounded,
                onPressed: () => context.push(AppRoutes.contactSupport),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
