import 'package:flutter/material.dart';

import '../../shared/widgets/app_glass.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final double? elevation;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.elevation,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      borderRadius: BorderRadius.zero,
      child: AppBar(
        title: title,
        actions: actions,
        leading: leading,
        backgroundColor: backgroundColor ?? Colors.transparent,
        elevation: elevation ?? 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: centerTitle,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomSliverAppBar extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final double? expandedHeight;
  final bool floating;
  final bool snap;
  final bool pinned;
  final Widget? flexibleSpace;
  final double? elevation;

  const CustomSliverAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.expandedHeight,
    this.floating = false,
    this.snap = false,
    this.pinned = false,
    this.flexibleSpace,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: title,
      actions: actions,
      leading: leading,
      backgroundColor: backgroundColor ?? Colors.transparent,
      expandedHeight: expandedHeight,
      floating: floating,
      snap: snap,
      pinned: pinned,
      flexibleSpace: flexibleSpace,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    );
  }
}
