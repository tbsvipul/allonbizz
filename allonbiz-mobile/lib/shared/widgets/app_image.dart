import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_colors.dart';

enum AppImageVariant { network, asset, avatar }

/// Universal App Image builder standardizing CachedNetworkImage and asset loading.
class AppImage extends StatelessWidget {
  const AppImage._({
    required this.variant,
    this.url,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
  });

  final AppImageVariant variant;
  final String? url;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;
  final Widget? errorWidget;

  const factory AppImage.network(
    String url, {
    double? width,
    double? height,
    BoxFit fit,
    BorderRadiusGeometry? borderRadius,
    Widget? errorWidget,
  }) = _AppImageNetwork;

  const factory AppImage.asset(
    String assetPath, {
    double? width,
    double? height,
    BoxFit fit,
    BorderRadiusGeometry? borderRadius,
    Widget? errorWidget,
  }) = _AppImageAsset;

  const factory AppImage.avatar(
    String? url, {
    double size,
    Widget? errorWidget,
  }) = _AppImageAvatar;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    switch (variant) {
      case AppImageVariant.network:
        if (url == null || url!.isEmpty) {
          imageWidget = _buildFallback();
        } else {
          imageWidget = CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => Container(
              color: AppColors.grey200,
              width: width,
              height: height,
              child: const Center(
                child: SpinKitPulse(color: AppColors.primary, size: 24),
              ),
            ),
            errorWidget: (context, url, error) =>
                errorWidget ?? _buildFallback(),
          );
        }
        break;

      case AppImageVariant.asset:
        if (assetPath == null || assetPath!.isEmpty) {
          imageWidget = _buildFallback();
        } else {
          imageWidget = Image.asset(
            assetPath!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                errorWidget ?? _buildFallback(),
          );
        }
        break;

      case AppImageVariant.avatar:
        imageWidget = Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.grey100,
          ),
          clipBehavior: Clip.antiAlias,
          child: (url == null || url!.isEmpty)
              ? Icon(
                  Icons.person_rounded,
                  size: (width ?? 40) * 0.6,
                  color: AppColors.grey500,
                )
              : CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: SpinKitPulse(color: AppColors.primary, size: 20),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person_rounded,
                    size: (width ?? 40) * 0.6,
                    color: AppColors.grey500,
                  ),
                ),
        );
        return imageWidget; // Avatar is intrinsically rounded
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.grey200,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: AppColors.grey400,
        ),
      ),
    );
  }
}

class _AppImageNetwork extends AppImage {
  const _AppImageNetwork(
    String url, {
    super.width,
    super.height,
    super.fit = BoxFit.cover,
    super.borderRadius,
    super.errorWidget,
  }) : super._(variant: AppImageVariant.network, url: url);
}

class _AppImageAsset extends AppImage {
  const _AppImageAsset(
    String assetPath, {
    super.width,
    super.height,
    super.fit = BoxFit.cover,
    super.borderRadius,
    super.errorWidget,
  }) : super._(variant: AppImageVariant.asset, assetPath: assetPath);
}

class _AppImageAvatar extends AppImage {
  const _AppImageAvatar(String? url, {double size = 48, super.errorWidget})
    : super._(
        variant: AppImageVariant.avatar,
        url: url,
        width: size,
        height: size,
      );
}
