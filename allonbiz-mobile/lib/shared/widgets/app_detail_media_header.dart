import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_decorations.dart';
import 'app_glass.dart';
import 'app_image.dart';

/// Shared image carousel + avatar treatment for detail screens.
class AppDetailMediaHeader extends StatefulWidget {
  const AppDetailMediaHeader({
    super.key,
    required this.images,
    required this.avatarImageUrl,
    this.height = 240,
    this.heroHeight = 200,
  });

  final List<String> images;
  final String? avatarImageUrl;
  final double height;
  final double heroHeight;

  @override
  State<AppDetailMediaHeader> createState() => _AppDetailMediaHeaderState();
}

class _AppDetailMediaHeaderState extends State<AppDetailMediaHeader> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images.where((image) => image.isNotEmpty).toList();
    final avatarImageUrl = widget.avatarImageUrl?.isNotEmpty == true
        ? widget.avatarImageUrl
        : '';

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: widget.heroHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: images.isNotEmpty
                  ? CarouselSlider(
                      options: CarouselOptions(
                        height: widget.heroHeight,
                        viewportFraction: 1,
                        autoPlay: images.length > 1,
                        autoPlayInterval: const Duration(seconds: 3),
                        onPageChanged: (index, reason) {
                          if (!mounted) {
                            return;
                          }
                          setState(() => _currentPage = index);
                        },
                      ),
                      items: images
                          .map((image) {
                            return AppImage.network(
                              image,
                              fit: BoxFit.cover,
                              height: widget.heroHeight,
                              width: double.infinity,
                            );
                          })
                          .toList(growable: false),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.appBackgroundLight,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.36),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: AnimatedSmoothIndicator(
                    activeIndex: _currentPage,
                    count: images.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 6,
                      dotWidth: 6,
                      activeDotColor: AppColors.primary,
                      dotColor: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            bottom: 0,
            child: GlassmorphicContainer(
              padding: const EdgeInsets.all(5),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: AppDecorations.mediaHeaderAvatar(
                  Theme.of(context).scaffoldBackgroundColor,
                ),
                child: ClipOval(
                  child: AppImage.network(
                    avatarImageUrl ?? '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
