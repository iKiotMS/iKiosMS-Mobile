import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/viewmodels/user_profile_provider.dart';
import '../../dashboard/widgets/dashboard_skeleton.dart';
import '../shared/promotion_labels.dart';
import '../shared/promotion_permissions.dart';
import '../viewmodels/promotion_list_view_model.dart';
import '../widgets/promotion_tile.dart';
import 'promotion_detail_view.dart';
import 'promotion_form_view.dart';

/// "Khuyến mãi" — list of promotions, scoped server-side to the caller's
/// own branch/tenant (see `PromotionService.getList`'s role-based filter).
/// Create/edit/deactivate actions only show for TENANT_OWNER/BRANCH_MANAGER
/// (see `promotion_permissions.dart`); STAFF gets a pure view-only screen.
class PromotionListView extends ConsumerWidget {
  const PromotionListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(promotionListViewModelProvider);
    final notifier = ref.read(promotionListViewModelProvider.notifier);
    final promotions = state.filteredPromotions;
    final role = ref.watch(userProfileProvider).value?.role;
    final canManage = canManagePromotions(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khuyến mãi'),
        centerTitle: true,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const PromotionFormView()),
                );
                if (created == true) notifier.refetch();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm khuyến mãi'),
            )
          : null,
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
                hintText: 'Tìm theo tên khuyến mãi...',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
                  for (final status in promotionStatusFilterOptions)
                    DropdownMenuItem<String?>(value: status, child: Text(promotionStatusFilterLabel(status), style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (state.isLoading && state.promotions.isEmpty)
              Column(
                children: List.generate(
                  5,
                  (i) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: DashboardSkeleton(height: 110),
                  ),
                ),
              )
            else if (promotions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.local_offer_outlined, size: 32, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Không có khuyến mãi nào phù hợp',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              ...promotions.map(
                (promotion) => PromotionTile(
                  promotion: promotion,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PromotionDetailView(promotionId: promotion.id)),
                  ),
                ),
              ),
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
          Expanded(child: Text(message, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
