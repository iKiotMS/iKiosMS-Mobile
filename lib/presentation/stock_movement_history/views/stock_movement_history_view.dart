import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/widgets/dashboard_skeleton.dart';
import '../shared/movement_labels.dart';
import '../viewmodels/stock_movement_history_view_model.dart';
import '../widgets/stock_movement_tile.dart';
import 'stock_movement_detail_view.dart';

/// "Lịch sử nhập/xuất kho" — read-only history of IMPORT/EXPORT/RETURN
/// stock movements, scoped server-side to the caller's own branch/warehouse
/// (see `StockMovementService.getList`'s role-based filter).
class StockMovementHistoryView extends ConsumerWidget {
  const StockMovementHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(stockMovementHistoryViewModelProvider);
    final notifier = ref.read(stockMovementHistoryViewModelProvider.notifier);
    final movements = state.filteredMovements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử nhập/xuất kho'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.errorMessage != null) ...[
              _ErrorBanner(message: state.errorMessage!, onRetry: notifier.refetch),
              const SizedBox(height: 12),
            ],
            TextField(
              onChanged: notifier.setSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Tìm theo mã, vị trí, nhà cung cấp, người tạo...',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TypeChip(label: 'Tất cả', selected: state.typeFilter == null, onTap: () => notifier.setTypeFilter(null)),
                  for (final type in state.visibleTypes) ...[
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: movementTypeConfig(type).label,
                      selected: state.typeFilter == type,
                      onTap: () => notifier.setTypeFilter(type),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: DropdownButton<String?>(
                value: state.statusFilter,
                underline: const SizedBox.shrink(),
                isDense: true,
                hint: Text('Tất cả trạng thái', style: theme.textTheme.bodySmall),
                onChanged: notifier.setStatusFilter,
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text('Tất cả trạng thái', style: theme.textTheme.bodySmall)),
                  for (final status in movementStatusFilterOptions)
                    DropdownMenuItem<String?>(value: status, child: Text(movementStatusConfig(status).label, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (state.isLoading && state.movements.isEmpty)
              Column(
                children: List.generate(
                  5,
                  (i) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: DashboardSkeleton(height: 110),
                  ),
                ),
              )
            else if (movements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 32, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Không có phiếu nhập/xuất nào phù hợp',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              ...movements.map(
                (movement) => StockMovementTile(
                  movement: movement,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => StockMovementDetailView(movementId: movement.id)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
