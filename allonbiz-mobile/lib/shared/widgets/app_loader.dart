import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'app_glass.dart';

enum AppLoaderVariant { fullScreen, inline, shimmer }

/// Universal App Loader for buffering displays and skeletons.
class AppLoader extends StatelessWidget {
  const AppLoader._({
    required this.variant,
    this.size = AppDimensions.iconXl,
    this.color = AppColors.primary,
    this.message,
    this.width,
    this.height,
  });

  final AppLoaderVariant variant;
  final double size;
  final Color color;
  final String? message;
  final double? width;
  final double? height;

  const factory AppLoader.fullScreen({
    double size,
    Color color,
    String? message,
  }) = _AppLoaderFullScreen;
  const factory AppLoader.inline({double size, Color color}) = _AppLoaderInline;
  const factory AppLoader.shimmer({
    required double width,
    required double height,
  }) = _AppLoaderShimmer;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppLoaderVariant.fullScreen:
        return GradientBackground(
          child: Center(
            child: GlassmorphicContainer(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpinKitPulse(color: color, size: size),
                  if (message != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      case AppLoaderVariant.inline:
        return SpinKitThreeBounce(color: color, size: size / 2);
      case AppLoaderVariant.shimmer:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.35, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Opacity(opacity: value, child: child);
          },
          onEnd: () {},
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.grey200.withValues(alpha: 0.78),
                  AppColors.champagne.withValues(alpha: 0.7),
                  AppColors.grey200.withValues(alpha: 0.78),
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
          ),
        );
    }
  }
}

class _AppLoaderFullScreen extends AppLoader {
  const _AppLoaderFullScreen({
    super.size = AppDimensions.xxxl,
    super.color = AppColors.primary,
    super.message,
  }) : super._(variant: AppLoaderVariant.fullScreen);
}

class _AppLoaderInline extends AppLoader {
  const _AppLoaderInline({
    super.size = AppDimensions.iconLg,
    super.color = AppColors.primary,
  }) : super._(variant: AppLoaderVariant.inline);
}

class _AppLoaderShimmer extends AppLoader {
  const _AppLoaderShimmer({super.width, super.height})
    : super._(variant: AppLoaderVariant.shimmer);
}
