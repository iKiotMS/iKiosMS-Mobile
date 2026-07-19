import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/cash_flow_model.dart';

/// A single ledger row: icon + title/meta on the left, signed amount on the right.
class CashFlowTile extends StatelessWidget {
  final CashFlowEntry entry;

  const CashFlowTile({super.key, required this.entry});

  static final DateFormat _fmt = DateFormat('dd/MM/yyyy • HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = <String>[
      if (entry.createdAt != null) _fmt.format(entry.createdAt!.toLocal()),
      if (entry.paymentMethodLabel != null) entry.paymentMethodLabel!,
      if (entry.locationName != null) entry.locationName!,
    ].join(' · ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: entry.flowColor.withValues(alpha: 0.12),
        child: Icon(
          entry.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
          color: entry.flowColor,
          size: 20,
        ),
      ),
      title: Text(
        entry.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: meta.isEmpty
          ? null
          : Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: Text(
        entry.signedAmountLabel,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: entry.flowColor,
        ),
      ),
    );
  }
}
