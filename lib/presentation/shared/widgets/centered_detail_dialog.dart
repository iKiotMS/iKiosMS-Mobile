import 'package:flutter/material.dart';

/// Shows a centered card dialog (better than full-width bottom sheet on web).
Future<T?> showCenteredCardDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double maxWidth = 420,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: media.size.height * 0.85,
          ),
          child: Material(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            elevation: 6,
            shadowColor: Colors.black26,
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

/// Shared content shell for detail cards shown via [showCenteredCardDialog].
class CenteredDetailCard extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Color? statusColor;
  final String? statusLabel;
  final List<Widget> children;

  const CenteredDetailCard({
    super.key,
    required this.title,
    this.actions,
    this.statusColor,
    this.statusLabel,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          if (statusLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              statusLabel!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: statusColor ?? theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...children,
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 20),
            ...actions!.expand(
              (w) => [w, const SizedBox(height: 8)],
            ).toList()
              ..removeLast(),
          ],
        ],
      ),
    );
  }
}

/// Full-width pill outlined / filled action used in detail cards.
class DetailActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool filled;
  final bool destructive;

  const DetailActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.filled = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: const StadiumBorder(),
            backgroundColor: destructive ? theme.colorScheme.error : null,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.45)),
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
        ),
        child: child,
      ),
    );
  }
}
