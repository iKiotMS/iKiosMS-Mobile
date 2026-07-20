import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/viewmodels/user_profile_provider.dart';
import '../../dashboard/widgets/dashboard_skeleton.dart';
import '../../stock_adjustment/shared/movement_labels.dart';
import '../shared/import_permissions.dart';
import '../viewmodels/imports_provider.dart';
import '../widgets/import_tile.dart';
import 'import_create_view.dart';
import 'import_detail_view.dart';

const List<String> _importStatusFilterOptions = ['PENDING', 'IN_TRANSIT', 'RECEIVED', 'CANCELLED'];

/// "Nhập hàng" — list of IMPORT stock-movement requests (create new ones via
/// the FAB, restricted to TENANT_OWNER/WAREHOUSE_MANAGER; tap a row to view
/// detail and ship/receive/cancel).
///
/// Mobile equivalent of the web app's `/exchange/imports` page.
class ImportListView extends ConsumerWidget {
  const ImportListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(importsProvider);
    final notifier = ref.read(importsProvider.notifier);
    final role = ref.watch(userProfileProvider).value?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập hàng'),
        centerTitle: true,
      ),
      floatingActionButton: canCreateImport(role)
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const ImportCreateView()),
                );
                if (created == true) notifier.fetchImports();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo đơn nhập hàng'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: notifier.fetchImports,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (state.error != null) ...[
              _ErrorBanner(message: state.error!, onRetry: notifier.fetchImports),
              const SizedBox(height: 12),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusChip(label: 'Tất cả', selected: state.statusFilter == 'ALL', onTap: () => notifier.setStatusFilter('ALL')),
                  for (final status in _importStatusFilterOptions) ...[
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: movementStatusConfig(status).label,
                      selected: state.statusFilter == status,
                      onTap: () => notifier.setStatusFilter(status),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (state.isLoading && state.imports.isEmpty)
              Column(
                children: List.generate(
                  4,
                  (i) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: DashboardSkeleton(height: 110),
                  ),
                ),
              )
            else if (state.imports.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.move_to_inbox_outlined, size: 32, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có đơn nhập hàng nào',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              ...state.imports.map(
                (item) => ImportTile(
                  request: item,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ImportDetailView(importId: item.id)),
                    );
                    notifier.fetchImports();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
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
