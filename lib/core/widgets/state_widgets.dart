import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'buttons.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.titleKey,
    this.messageKey,
    this.actionKey,
    this.onAction,
  });

  final IconData icon;
  final String titleKey;
  final String? messageKey;
  final String? actionKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(titleKey.tr, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            if (messageKey != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(messageKey!.tr, textAlign: TextAlign.center),
            ],
            if (actionKey != null && onAction != null) ...<Widget>[
              const SizedBox(height: 20),
              PrimaryButton(label: actionKey!.tr, onPressed: onAction, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, this.messageKey, this.message, this.onRetry});

  final String? messageKey;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message ?? (messageKey ?? 'err_generic').tr, textAlign: TextAlign.center),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              SecondaryButton(
                  label: 'retry'.tr, onPressed: onRetry, icon: Icons.refresh, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pulsing placeholder list. Stops animating when the system asks to reduce motion.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.outline.withValues(alpha: 0.35);
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6)),
        );
    return Semantics(
      label: 'loading'.tr,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) =>
              Opacity(opacity: 0.45 + 0.55 * _controller.value, child: child),
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: widget.itemCount,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: <Widget>[
                  Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: base, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[bar(140, 14), const SizedBox(height: 8), bar(90, 12)],
                    ),
                  ),
                  bar(60, 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown in app bars: data lives on this device and works offline.
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'saved_on_device'.tr,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.smartphone, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text('on_device'.tr, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
