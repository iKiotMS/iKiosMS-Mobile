import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/inventory_dashboard_view_model.dart';

/// Debounced search field ("theo tên hoặc SKU") + a low-stock-only filter chip.
class InventorySearchFilterBar extends ConsumerStatefulWidget {
  const InventorySearchFilterBar({super.key});

  @override
  ConsumerState<InventorySearchFilterBar> createState() => _InventorySearchFilterBarState();
}

class _InventorySearchFilterBarState extends ConsumerState<InventorySearchFilterBar> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(inventoryDashboardViewModelProvider.notifier).setSearch(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLowStockOnly = ref.watch(
      inventoryDashboardViewModelProvider.select((s) => s.isLowStockOnly),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Tìm theo tên hoặc SKU...',
            prefixIcon: Icon(Icons.search_rounded),
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilterChip(
          label: const Text('Chỉ hiện tồn kho thấp'),
          selected: isLowStockOnly,
          onSelected: (value) {
            ref.read(inventoryDashboardViewModelProvider.notifier).toggleLowStockOnly(value);
          },
        ),
      ],
    );
  }
}
