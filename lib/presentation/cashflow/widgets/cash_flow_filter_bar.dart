import 'package:flutter/material.dart';

import '../viewmodels/cash_flow_view_model.dart';

/// Two rows of filter chips: the date-range preset and the income/expense type.
class CashFlowFilterBar extends StatelessWidget {
  final CashFlowRange range;
  final CashFlowTypeFilter typeFilter;
  final ValueChanged<CashFlowRange> onRangeChanged;
  final ValueChanged<CashFlowTypeFilter> onTypeChanged;

  const CashFlowFilterBar({
    super.key,
    required this.range,
    required this.typeFilter,
    required this.onRangeChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final r in CashFlowRange.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(r.label),
                    selected: r == range,
                    onSelected: (_) => onRangeChanged(r),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final t in CashFlowTypeFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(t.label),
                  selected: t == typeFilter,
                  onSelected: (_) => onTypeChanged(t),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
