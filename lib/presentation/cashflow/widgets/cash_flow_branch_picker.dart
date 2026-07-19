import 'package:flutter/material.dart';

import '../../../data/models/branch_option.dart';

/// Dropdown that lets a TENANT_OWNER filter the ledger by branch.
///
/// A `null` selection means "all branches". Not shown for branch/warehouse
/// managers, whose scope is fixed server-side.
class CashFlowBranchPicker extends StatelessWidget {
  final List<BranchOption> branches;
  final String? selectedBranchId;
  final ValueChanged<String?> onChanged;

  const CashFlowBranchPicker({
    super.key,
    required this.branches,
    required this.selectedBranchId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: selectedBranchId,
      isExpanded: true,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.storefront_outlined),
        labelText: 'Chi nhánh',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Tất cả chi nhánh'),
        ),
        for (final b in branches)
          DropdownMenuItem<String?>(
            value: b.id,
            child: Text(b.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
