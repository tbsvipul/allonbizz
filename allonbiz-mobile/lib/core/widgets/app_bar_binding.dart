import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_bar_provider.dart';

export '../providers/app_bar_provider.dart';

/// Keeps a screen-specific app bar config bound for the lifetime of a subtree.
class AppBarBinding extends ConsumerStatefulWidget {
  const AppBarBinding({super.key, required this.config, required this.child});

  final AppBarConfig config;
  final Widget child;

  @override
  ConsumerState<AppBarBinding> createState() => _AppBarBindingState();
}

class _AppBarBindingState extends ConsumerState<AppBarBinding> {
  late final AppBarNotifier _appBarNotifier;
  final Object _bindingOwner = Object();
  AppBarConfig? _pendingConfig;
  bool _syncScheduled = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _appBarNotifier = ref.read(appBarProvider.notifier);
    _scheduleConfigSync(widget.config);
  }

  void _scheduleConfigSync(AppBarConfig config) {
    _pendingConfig = config;
    if (_syncScheduled) {
      return;
    }

    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (_isDisposed) {
        return;
      }

      final nextConfig = _pendingConfig;
      if (nextConfig == null) {
        return;
      }

      _appBarNotifier.bindConfig(_bindingOwner, nextConfig);
    });
  }

  void _scheduleUnbind() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appBarNotifier.unbindConfig(_bindingOwner);
    });
  }

  @override
  void didUpdateWidget(covariant AppBarBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleConfigSync(widget.config);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scheduleUnbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
