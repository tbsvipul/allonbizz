import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/base_api.dart';

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
    final normalizedUrl = _normalizeUrl(url);

    switch (variant) {
      case AppImageVariant.network:
        if (normalizedUrl == null || normalizedUrl.isEmpty) {
          imageWidget = _buildFallback();
        } else if (normalizedUrl.startsWith('data:image') ||
            (!normalizedUrl.startsWith('http') && normalizedUrl.length > 100)) {
          try {
            final base64String =
                (normalizedUrl.startsWith('data:image')
                        ? normalizedUrl.split(',').last
                        : normalizedUrl)
                    .replaceAll(RegExp(r'\s+'), '');
            final bytes = base64Decode(base64String);
            imageWidget = Image.memory(
              bytes,
              width: width,
              height: height,
              fit: fit,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  errorWidget ?? _buildFallback(),
            );
          } catch (_) {
            imageWidget = _buildFallback();
          }
        } else {
          imageWidget = CachedNetworkImage(
            imageUrl: normalizedUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => Container(
              decoration: const BoxDecoration(
                gradient: AppColors.appBackgroundLight,
              ),
              width: width,
              height: height,
              child: const Center(
                child: SpinKitPulse(color: AppColors.secondary, size: 24),
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
            gradient: AppColors.primaryGradient,
          ),
          clipBehavior: Clip.antiAlias,
          child: (url == null || url!.isEmpty)
              ? Icon(
                  Icons.person_rounded,
                  size: (width ?? 40) * 0.6,
                  color: AppColors.white,
                )
              : normalizedUrl!.startsWith('data:image') ||
                    (!normalizedUrl.startsWith('http') &&
                        normalizedUrl.length > 100)
              ? Image.memory(
                  base64Decode(
                    (normalizedUrl.startsWith('data:image')
                            ? normalizedUrl.split(',').last
                            : normalizedUrl)
                        .replaceAll(RegExp(r'\s+'), ''),
                  ),
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.person_rounded,
                    size: (width ?? 40) * 0.6,
                    color: AppColors.white,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: normalizedUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: SpinKitPulse(color: AppColors.secondary, size: 20),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person_rounded,
                    size: (width ?? 40) * 0.6,
                    color: AppColors.white,
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

  String? _normalizeUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('data:image')) {
      return trimmed;
    }

    if (!trimmed.startsWith('http') &&
        !trimmed.startsWith('/') &&
        trimmed.length > 200) {
      // Very likely a raw base64 string
      return trimmed;
    }

    final sanitized = trimmed.replaceAll('\\', '/');
    final parsed = Uri.tryParse(sanitized);
    if (parsed?.hasScheme == true) {
      return sanitized;
    }

    final backendUri = Uri.tryParse(BaseApi.backendBaseUrl);
    if (backendUri == null || backendUri.host.isEmpty) {
      return sanitized;
    }

    if (sanitized.startsWith('//')) {
      return '${backendUri.scheme}:$sanitized';
    }

    final originUri = Uri(
      scheme: backendUri.scheme,
      host: backendUri.host,
      port: backendUri.hasPort ? backendUri.port : null,
      path: '/',
    );

    if (sanitized.startsWith('/') || _looksLikeRootHostedAsset(sanitized)) {
      return originUri.resolve(sanitized).toString();
    }

    final backendBaseUri = backendUri.path.endsWith('/')
        ? backendUri
        : backendUri.replace(path: '${backendUri.path}/');
    return backendBaseUri.resolve(sanitized).toString();
  }

  bool _looksLikeRootHostedAsset(String rawUrl) {
    final normalized = rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl;
    return normalized.startsWith('uploads/') ||
        normalized.startsWith('images/') ||
        normalized.startsWith('media/') ||
        normalized.startsWith('files/');
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(gradient: AppColors.dealGradient),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: AppColors.secondaryDark,
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
