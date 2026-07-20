import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../viewmodels/order_list_view_model.dart';
import '../../../data/models/order_model.dart';

class OrderListView extends ConsumerStatefulWidget {
  const OrderListView({super.key});

  @override
  ConsumerState<OrderListView> createState() => _OrderListViewState();
}

class _OrderListViewState extends ConsumerState<OrderListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(orderListViewModelProvider.notifier).loadMore();
    }
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'RETURNED':
        return Colors.blue;
      case 'CANCELLED':
        return colorScheme.error;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'RETURNED':
        return 'Trả hàng';
      case 'CANCELLED':
        return 'Đã huỷ';
      default:
        return status;
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'CASH':
        return 'Tiền mặt';
      case 'SEPAY':
        return 'Chuyển khoản QR';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản';
      case 'MOMO':
        return 'MoMo';
      case 'VNPAY':
        return 'VNPay';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListViewModelProvider);
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,##0', 'vi_VN');
    final dateFormat = DateFormat('HH:mm dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Hóa đơn'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(orderListViewModelProvider.notifier).refresh();
        },
        child: Column(
          children: [
            // Filters
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => ref.read(orderListViewModelProvider.notifier).setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo mã HĐ, tên, mã khách...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(orderListViewModelProvider.notifier).setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: state.statusFilter,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          hint: const Text('Tất cả trạng thái', style: TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis)),
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Tất cả trạng thái')),
                            DropdownMenuItem(value: 'COMPLETED', child: Text('Đã hoàn thành')),
                            DropdownMenuItem(value: 'PENDING', child: Text('Chờ thanh toán')),
                            DropdownMenuItem(value: 'RETURNED', child: Text('Trả hàng')),
                            DropdownMenuItem(value: 'CANCELLED', child: Text('Đã huỷ')),
                          ],
                          onChanged: (val) => ref.read(orderListViewModelProvider.notifier).setStatusFilter(val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: state.paymentMethodFilter,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          hint: const Text('Tất cả PT', style: TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis)),
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Tất cả PT')),
                            DropdownMenuItem(value: 'CASH', child: Text('Tiền mặt')),
                            DropdownMenuItem(value: 'SEPAY', child: Text('Chuyển khoản QR')),
                            DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Chuyển khoản')),
                          ],
                          onChanged: (val) => ref.read(orderListViewModelProvider.notifier).setPaymentMethodFilter(val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Order List
            Expanded(
              child: state.isLoading && state.orders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.orders.isEmpty
                      ? Center(child: Text('Lỗi: ${state.error}', style: TextStyle(color: theme.colorScheme.error)))
                      : state.orders.isEmpty
                          ? const Center(child: Text('Không tìm thấy hóa đơn nào.'))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: state.orders.length + (state.page < state.totalPages ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == state.orders.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final order = state.orders[index];
                                final statusColor = _getStatusColor(order.status, theme.colorScheme);
                                DateTime? createdAt;
                                try {
                                  createdAt = DateTime.parse(order.createdAt).toLocal();
                                } catch (_) {}

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                                  ),
                                  elevation: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header: Order ID & Status
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              order.id.startsWith('ORD') ? order.id : 'ORD-${order.id.substring(order.id.length > 8 ? order.id.length - 8 : 0).toUpperCase()}',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _getStatusText(order.status),
                                                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Customer & Seller
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                order.customerName ?? 'Khách vãng lai',
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Icon(Icons.support_agent, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              order.userName ?? 'Hệ thống',
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        // Totals & Time
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  createdAt != null ? dateFormat.format(createdAt) : '',
                                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _getPaymentMethodText(order.paymentMethod),
                                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                const Text('Tổng tiền', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                                Text(
                                                  '${numberFormat.format(order.grandTotal)} đ',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
