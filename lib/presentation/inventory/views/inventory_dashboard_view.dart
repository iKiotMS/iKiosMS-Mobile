import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/widgets/dashboard_skeleton.dart';
import '../viewmodels/inventory_dashboard_view_model.dart';
import '../widgets/inventory_item_tile.dart';
import '../widgets/inventory_search_filter_bar.dart';
import '../widgets/inventory_summary_cards.dart';

/// "Dashboard, Quản lý tồn kho / kho" — warehouse/branch inventory screen.
///
/// TENANT_OWNER/BRANCH_MANAGER/WAREHOUSE_MANAGER can all edit the low-stock
/// threshold (`inventory:update`); only TENANT_OWNER/WAREHOUSE_MANAGER can
/// remove an item from a location (`DELETE /inventory/:id`'s role gate
/// excludes BRANCH_MANAGER) — see [InventoryDashboardState.canEditMinStock]/
/// [InventoryDashboardState.canRemove]. Not reachable by STAFF (not present
/// in their work-menu groups).
class InventoryDashboardView extends ConsumerStatefulWidget {
  const InventoryDashboardView({super.key});

  @override
  ConsumerState<InventoryDashboardView> createState() => _InventoryDashboardViewState();
}

class _InventoryDashboardViewState extends ConsumerState<InventoryDashboardView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(inventoryDashboardViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(inventoryDashboardViewModelProvider);
    final notifier = ref.read(inventoryDashboardViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tồn kho'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refetch,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            if (state.errorMessage != null) ...[
              _ErrorBanner(message: state.errorMessage!, onRetry: notifier.refetch),
              const SizedBox(height: 12),
            ],
            const InventorySummaryCards(),
            const SizedBox(height: 16),
            const InventorySearchFilterBar(),
            const SizedBox(height: 12),
            if (state.isLoadingList && state.items.isEmpty)
              Column(
                children: List.generate(
                  5,
                  (i) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: DashboardSkeleton(height: 68),
                  ),
                ),
              )
            else if (state.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 32, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      state.isLowStockOnly || state.search.isNotEmpty
                          ? 'Không tìm thấy sản phẩm phù hợp'
                          : 'Chưa có sản phẩm nào tại vị trí này',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else ...[
              ...state.items.map((item) => InventoryItemTile(
                    item: item,
                    canEditMinStock: state.canEditMinStock,
                    canRemove: state.canRemove,
                  )),
              if (state.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ],
        ),
      ),
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
          Expanded(
            child: Text(message, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
