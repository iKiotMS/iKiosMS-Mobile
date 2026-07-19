// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/stock_movement_model.dart';
import '../viewmodels/transfers_provider.dart';
import 'transfer_create_view.dart';
import 'transfer_detail_view.dart';

class TransfersListView extends ConsumerStatefulWidget {
  const TransfersListView({super.key});

  @override
  ConsumerState<TransfersListView> createState() => _TransfersListViewState();
}

class _TransfersListViewState extends ConsumerState<TransfersListView> {
  final TextEditingController _searchController = TextEditingController();

  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  final List<Map<String, String>> _statusOptions = [
    {'value': 'ALL', 'label': 'Tất cả'},
    {'value': 'DRAFT', 'label': 'Nháp / Cần xử lý'},
    {'value': 'OPENING', 'label': 'Đang soạn'},
    {'value': 'CLOSED', 'label': 'Đã chốt'},
    {'value': 'IN_TRANSIT', 'label': 'Đang vận chuyển'},
    {'value': 'RECEIVED', 'label': 'Đã nhận hàng'},
    {'value': 'CANCELLED', 'label': 'Đã huỷ'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transfersProvider);
    final notifier = ref.read(transfersProvider.notifier);
    final theme = Theme.of(context);
    final items = state.filteredTransfers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyển kho / Chuyển hàng'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search & Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => notifier.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã phiếu, địa điểm, người yêu cầu...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
          ),

          // Status Filter Horizontal Chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _statusOptions.length,
              itemBuilder: (context, index) {
                final option = _statusOptions[index];
                final isSelected = state.statusFilter == option['value'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(option['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        notifier.setStatusFilter(option['value']!);
                      }
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Main List Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.fetchTransfers(),
              child: state.isLoading && items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                                const SizedBox(height: 12),
                                Text('Có lỗi xảy ra: ${state.error}'),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => notifier.fetchTransfers(),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.outline),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Chưa có yêu cầu chuyển kho nào',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final transfer = items[index];
                                return _buildTransferCard(context, transfer, theme);
                              },
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TransferCreateView(),
            ),
          );
          if (res == true) {
            notifier.fetchTransfers();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo yêu cầu'),
      ),
    );
  }

  Widget _buildTransferCard(BuildContext context, StockMovementModel transfer, ThemeData theme) {
    final dateStr = transfer.createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(transfer.createdAt!)
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransferDetailView(transferId: transfer.id),
            ),
          );
          ref.read(transfersProvider.notifier).fetchTransfers();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Code & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '#${transfer.id.length > 10 ? transfer.id.substring(transfer.id.length - 8) : transfer.id}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: transfer.statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: transfer.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      transfer.statusLabel,
                      style: TextStyle(
                        color: transfer.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Route (From -> To)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                transfer.fromLocationType == 'warehouse'
                                    ? Icons.warehouse_outlined
                                    : Icons.storefront_outlined,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  transfer.fromLocationName ?? 'Nơi gửi',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            transfer.fromLocationType == 'warehouse' ? 'Kho' : 'Chi nhánh',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_forward_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                transfer.toLocationType == 'warehouse'
                                    ? Icons.warehouse_outlined
                                    : Icons.storefront_outlined,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  transfer.toLocationName.isNotEmpty ? transfer.toLocationName : 'Nơi nhận',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            transfer.toLocationType == 'warehouse' ? 'Kho' : 'Chi nhánh',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Row 3: Summary details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${transfer.totalQty} sp',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.attach_money_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      Text(
                        currencyFormat.format(transfer.totalValue),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        dateStr,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
