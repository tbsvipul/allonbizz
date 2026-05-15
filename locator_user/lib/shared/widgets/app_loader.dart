import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_colors.dart';

enum AppLoaderVariant { fullScreen, inline, shimmer }

/// Universal App Loader for buffering displays and skeletons.
class AppLoader extends StatelessWidget {
  const AppLoader._({
    required this.variant,
    this.size = 40.0,
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
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitPulse(color: color, size: size),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message!,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        );
      case AppLoaderVariant.inline:
        return SpinKitThreeBounce(color: color, size: size / 2);
      case AppLoaderVariant.shimmer:
        // Stand-in for full shimmer without introducing more libraries. Basic animated container or fallback.
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(12),
          ),
        );
    }
  }
}

class _AppLoaderFullScreen extends AppLoader {
  const _AppLoaderFullScreen({
    super.size = 60.0,
    super.color = AppColors.primary,
    super.message,
  }) : super._(variant: AppLoaderVariant.fullScreen);
}

class _AppLoaderInline extends AppLoader {
  const _AppLoaderInline({super.size = 30.0, super.color = AppColors.primary})
    : super._(variant: AppLoaderVariant.inline);
}

class _AppLoaderShimmer extends AppLoader {
  const _AppLoaderShimmer({super.width, super.height})
    : super._(variant: AppLoaderVariant.shimmer);
}
