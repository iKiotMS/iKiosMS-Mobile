// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/viewmodels/user_profile_provider.dart';
import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/stock_movement_repository.dart';
import '../viewmodels/transfers_provider.dart';

class TransferDetailView extends ConsumerStatefulWidget {
  final String transferId;

  const TransferDetailView({
    super.key,
    required this.transferId,
  });

  @override
  ConsumerState<TransferDetailView> createState() => _TransferDetailViewState();
}

class _TransferDetailViewState extends ConsumerState<TransferDetailView> {
  StockMovementModel? _transfer;
  bool _isLoading = true;
  String? _error;
  bool _isActionLoading = false;

  // Receive form state
  bool _showReceiveForm = false;
  final Map<String, TextEditingController> _receivedControllers = {};

  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    for (final controller in _receivedControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(stockMovementRepositoryProvider);
      final detail = await repo.getById(widget.transferId);
      setState(() {
        _transfer = detail;
        _isLoading = false;
        _initReceiveControllers(detail);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _initReceiveControllers(StockMovementModel detail) {
    for (final item in detail.details) {
      final initialQty = item.receivedQuantity > 0 ? item.receivedQuantity : item.quantity;
      _receivedControllers[item.productItemId] = TextEditingController(text: initialQty.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProfile = ref.watch(userProfileProvider).value;
    final role = userProfile?.role ?? '';
    final isTenantOwner = role == 'TENANT_OWNER';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết chuyển kho')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _transfer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết chuyển kho')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('Không thể tải chi tiết: ${_error ?? "Không tìm thấy phiếu"}'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadDetail,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final transfer = _transfer!;
    final isDraft = transfer.status == 'DRAFT';
    final isOpening = transfer.status == 'OPENING';
    final isClosed = transfer.status == 'CLOSED';
    final isInTransit = transfer.status == 'IN_TRANSIT';
    final isReceived = transfer.status == 'RECEIVED';

    // Role scope logic
    final isSender = isTenantOwner || transfer.fromLocationId != null;
    final isReceiver = isTenantOwner || transfer.toLocationId.isNotEmpty;

    final canOpenDraft = isDraft && isSender;
    final canShipClosed = isClosed && isSender;
    final canReceiveTransit = isInTransit && isReceiver;
    final canReturnGoods = (isReceived || isInTransit) && isReceiver;
    final canCancel = isSender && !isReceived && transfer.status != 'CANCELLED' && transfer.status != 'COMPLETED';

    final dateStr = transfer.createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(transfer.createdAt!)
        : '—';

    return Scaffold(
      appBar: AppBar(
        title: Text('Mã phiếu: #${transfer.id.length > 10 ? transfer.id.substring(transfer.id.length - 8) : transfer.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDetail,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yêu cầu ${transfer.movementType == "RETURN" ? "Trả hàng" : "Chuyển kho"}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: transfer.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: transfer.statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    transfer.statusLabel,
                    style: TextStyle(
                      color: transfer.statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Route Section (From -> To)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Icon(
                                  transfer.fromLocationType == 'warehouse'
                                      ? Icons.warehouse_rounded
                                      : Icons.storefront_rounded,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                transfer.fromLocationName ?? 'Nơi gửi',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                transfer.fromLocationType == 'warehouse' ? 'Kho xuất' : 'Chi nhánh xuất',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary, size: 28),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: theme.colorScheme.secondaryContainer,
                                child: Icon(
                                  transfer.toLocationType == 'warehouse'
                                      ? Icons.warehouse_rounded
                                      : Icons.storefront_rounded,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                transfer.toLocationName.isNotEmpty ? transfer.toLocationName : 'Nơi nhận',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                transfer.toLocationType == 'warehouse' ? 'Kho nhận' : 'Chi nhánh nhận',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // General Info Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person_outline_rounded, 'Người yêu cầu', transfer.requestedByName ?? '—', theme),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.calendar_today_rounded, 'Ngày tạo', dateStr, theme),
                    if (transfer.note != null && transfer.note!.isNotEmpty) ...[
                      const Divider(height: 20),
                      _buildInfoRow(Icons.note_outlined, 'Ghi chú đơn', transfer.note!, theme),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Product Items Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách sản phẩm (${transfer.details.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tổng: ${transfer.totalQty} sp',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Receive Form Banner (if active)
            if (_showReceiveForm && canReceiveTransit)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nhập số lượng thực nhận cho từng mặt hàng bên dưới:',
                        style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Products Details List
            ...transfer.details.map((item) => _buildProductItemCard(item, theme, isInTransit, isReceived)),

            const SizedBox(height: 12),

            // Total Value Summary Card
            Card(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng giá trị chuyển kho', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      currencyFormat.format(transfer.totalValue),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),

      // Bottom Persistent Action Bar
      bottomNavigationBar: _isActionLoading
          ? const SafeArea(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())))
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Cancel Button
                  if (canCancel)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleCancel,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Hủy phiếu'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (canCancel && (canOpenDraft || canShipClosed || canReceiveTransit || canReturnGoods || isOpening))
                    const SizedBox(width: 12),

                  // Main Action Button
                  if (canOpenDraft)
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _handleOpenDraft,
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Mở phiếu soạn'),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),

                  if (isOpening)
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _handleShipFromOpening,
                        icon: const Icon(Icons.local_shipping_rounded),
                        label: const Text('Chốt & Xuất kho'),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),

                  if (canShipClosed)
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _handleShip,
                        icon: const Icon(Icons.local_shipping_rounded),
                        label: const Text('Xuất kho'),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),

                  if (canReceiveTransit)
                    Expanded(
                      flex: 2,
                      child: _showReceiveForm
                          ? FilledButton.icon(
                              onPressed: _handleConfirmReceive,
                              icon: const Icon(Icons.check_circle_outline_rounded),
                              label: const Text('Xác nhận nhận hàng'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            )
                          : FilledButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showReceiveForm = true;
                                });
                              },
                              icon: const Icon(Icons.move_to_inbox_rounded),
                              label: const Text('Nhận hàng'),
                              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                            ),
                    ),

                  if (canReturnGoods && !isInTransit)
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: _handleReturnGoods,
                        icon: const Icon(Icons.assignment_return_rounded),
                        label: const Text('Trả hàng'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildProductItemCard(StockMovementDetailModel item, ThemeData theme, bool isInTransit, bool isReceived) {
    final controller = _receivedControllers[item.productItemId];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName.isNotEmpty ? item.productName : item.productItemId,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (item.sku.isNotEmpty)
              Text(
                'SKU: ${item.sku}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đơn giá: ${currencyFormat.format(item.importPrice)}', style: theme.textTheme.bodySmall),
                Text('Số lượng: ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (isReceived || (isInTransit && !_showReceiveForm))
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Đã thực nhận: ${item.receivedQuantity}',
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            if (_showReceiveForm && controller != null) ...[
              const Divider(height: 16),
              Row(
                children: [
                  const Text('SL Thực nhận:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    height: 40,
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Thành tiền:', style: TextStyle(fontSize: 12)),
                Text(
                  currencyFormat.format(item.totalPrice),
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Action handlers
  Future<void> _handleOpenDraft() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(transfersProvider.notifier).openTransfer(widget.transferId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã mở phiếu soạn')));
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleShipFromOpening() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(transfersProvider.notifier).closeTransfer(widget.transferId);
      await ref.read(transfersProvider.notifier).shipTransfer(widget.transferId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chốt và xuất kho')));
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleShip() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(transfersProvider.notifier).shipTransfer(widget.transferId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xuất hàng thành công')));
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleConfirmReceive() async {
    final List<Map<String, dynamic>> payload = [];
    for (final item in _transfer!.details) {
      final ctrl = _receivedControllers[item.productItemId];
      final rQty = int.tryParse(ctrl?.text ?? '0') ?? 0;
      payload.add({
        'productItemId': item.productItemId,
        'receivedQuantity': rQty,
      });
    }

    setState(() => _isActionLoading = true);
    try {
      await ref.read(transfersProvider.notifier).receiveTransfer(widget.transferId, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xác nhận nhận hàng thành công!')));
      setState(() {
        _showReceiveForm = false;
      });
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleReturnGoods() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận trả hàng'),
        content: const Text('Bạn có chắc chắn muốn trả lại hàng cho nơi gửi không? Action không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Trả hàng')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(transfersProvider.notifier).returnGoods(_transfer!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo và xuất phiếu trả hàng!')));
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy phiếu'),
        content: const Text('Bạn có chắc chắn muốn hủy phiếu này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Quay lại')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy phiếu'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(transfersProvider.notifier).cancelTransfer(widget.transferId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy phiếu thành công')));
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }
}
