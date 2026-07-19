import 'package:flutter/material.dart';

/// Placeholder box shown while a dashboard widget's data is loading.
///
/// Mobile equivalent of the web dashboard's shared shadcn `<Skeleton>`.
class DashboardSkeleton extends StatelessWidget {
  final double height;

  const DashboardSkeleton({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
