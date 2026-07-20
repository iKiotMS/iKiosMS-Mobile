// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/stock_movement_repository.dart';
import '../../auth/viewmodels/user_profile_provider.dart';
import '../shared/import_permissions.dart';
import '../shared/import_pricing.dart';
import '../viewmodels/imports_provider.dart';

/// "Chi tiết đơn nhập hàng" — header (supplier/destination/requester/note),
/// line items (editable while PENDING for the destination actor), and a
/// lifecycle action bar (Cập nhật phiếu / Giao hàng / Nhận hàng / Huỷ đơn)
/// gated by [computeImportActionFlags]. Mirrors `transfers/transfer_detail_view.dart`.
class ImportDetailView extends ConsumerStatefulWidget {
  final String importId;

  const ImportDetailView({super.key, required this.importId});

  @override
  ConsumerState<ImportDetailView> createState() => _ImportDetailViewState();
}

class _ImportDetailViewState extends ConsumerState<ImportDetailView> {
  StockMovementModel? _movement;
  bool _isLoading = true;
  String? _error;
  bool _isActionLoading = false;

  List<StockMovementProductItemOption> _destinationProducts = const [];
  List<_EditLine> _editLines = [];

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
    for (final line in _editLines) {
      line.dispose();
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
      final detail = await repo.getById(widget.importId);
      List<StockMovementProductItemOption> destinationProducts = const [];
      try {
        destinationProducts = await repo.getProductItemsForDestination(detail.toLocationId, detail.toLocationType);
      } catch (_) {
        // Best-effort only — used for retail-price hints and the "add
        // product" picker while editing; edit UI still works without it.
      }
      if (!mounted) return;
      setState(() {
        _movement = detail;
        _destinationProducts = destinationProducts;
        _isLoading = false;
        _initReceiveControllers(detail);
        _initEditLines(detail);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _initReceiveControllers(StockMovementModel detail) {
    for (final controller in _receivedControllers.values) {
      controller.dispose();
    }
    _receivedControllers.clear();
    for (final item in detail.details) {
      final initialQty = item.receivedQuantity > 0 ? item.receivedQuantity : item.quantity;
      _receivedControllers[item.productItemId] = TextEditingController(text: initialQty.toString());
    }
  }

  void _initEditLines(StockMovementModel detail) {
    for (final line in _editLines) {
      line.dispose();
    }
    _editLines = detail.details.map((d) {
      final catalogMatch = _destinationProducts.where((p) => p.id == d.productItemId);
      final retail = catalogMatch.isNotEmpty ? catalogMatch.first.retailPrice : null;
      return _EditLine(
        productItemId: d.productItemId,
        productName: d.productName.isNotEmpty ? d.productName : d.productItemId,
        sku: d.sku,
        retailPrice: retail,
        qty: d.quantity,
        price: d.importPrice,
        note: d.note,
      );
    }).toList();
  }

  Future<void> _addEditLine() async {
    final existingIds = _editLines.map((l) => l.productItemId).toSet();
    final candidates = _destinationProducts.where((p) => !existingIds.contains(p.id)).toList();
    final picked = await showModalBottomSheet<StockMovementProductItemOption>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DestinationProductPickerSheet(items: candidates),
    );
    if (picked == null) return;
    setState(() {
      _editLines.add(_EditLine(
        productItemId: picked.id,
        productName: picked.name,
        sku: picked.sku,
        retailPrice: picked.retailPrice,
        qty: 1,
        price: resolveImportPrice(picked),
      ));
    });
  }

  void _removeEditLine(int index) {
    if (_editLines.length <= 1) return;
    setState(() {
      _editLines[index].dispose();
      _editLines.removeAt(index);
    });
  }

  Future<void> _saveDetails() async {
    final details = <Map<String, dynamic>>[];
    for (final line in _editLines) {
      final qty = int.tryParse(line.qtyController.text) ?? 0;
      final price = double.tryParse(line.priceController.text) ?? 0;
      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Số lượng "${line.productName}" phải lớn hơn 0')));
        return;
      }
      if (price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Giá nhập "${line.productName}" phải lớn hơn 0')));
        return;
      }
      if (line.retailPrice != null && line.retailPrice! > 0 && price > line.retailPrice!) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Giá nhập "${line.productName}" không được cao hơn giá bán')));
        return;
      }
      details.add({
        'productItemId': line.productItemId,
        'quantity': qty,
        'importPrice': price,
        if (line.noteController.text.trim().isNotEmpty) 'note': line.noteController.text.trim(),
      });
    }
    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cần ít nhất 1 mặt hàng')));
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      await ref.read(importsProvider.notifier).updateDetails(widget.importId, details);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật danh sách hàng')));
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleShip() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(importsProvider.notifier).shipImport(widget.importId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã giao hàng')));
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleConfirmReceive() async {
    final List<Map<String, dynamic>> payload = [];
    for (final item in _movement!.details) {
      final ctrl = _receivedControllers[item.productItemId];
      final rQty = int.tryParse(ctrl?.text ?? '0') ?? 0;
      payload.add({
        'productItemId': item.productItemId,
        'receivedQuantity': rQty < 0 ? 0 : rQty,
      });
    }

    if (payload.every((d) => (d['receivedQuantity'] as int) == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số lượng thực nhận không được toàn bộ bằng 0')));
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      await ref.read(importsProvider.notifier).receiveImport(widget.importId, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xác nhận nhận hàng thành công!')));
      setState(() => _showReceiveForm = false);
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn nhập hàng này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Quay lại')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(importsProvider.notifier).cancelImport(widget.importId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy đơn nhập hàng')));
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết đơn nhập hàng')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _movement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết đơn nhập hàng')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('Không thể tải chi tiết: ${_error ?? "Không tìm thấy đơn"}'),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _loadDetail, icon: const Icon(Icons.refresh_rounded), label: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final movement = _movement!;
    final profile = ref.watch(userProfileProvider).value;
    final flags = computeImportActionFlags(role: profile?.role, userWarehouseId: profile?.warehouseId, movement: movement);
    final isPending = movement.status == 'PENDING';
    final isInTransit = movement.status == 'IN_TRANSIT';
    final isReceived = movement.status == 'RECEIVED';
    final showEditableLines = flags.canEditDetails && isPending;

    final dateStr = movement.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(movement.createdAt!) : '—';

    return Scaffold(
      appBar: AppBar(
        title: Text('Mã đơn: #${movement.id.length > 8 ? movement.id.substring(movement.id.length - 8) : movement.id}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadDetail, tooltip: 'Làm mới'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đơn nhập hàng', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: movement.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: movement.statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    movement.statusLabel,
                    style: TextStyle(color: movement.statusColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.local_shipping_rounded, color: theme.colorScheme.onPrimaryContainer),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            movement.supplierName ?? 'Nhà cung cấp',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          Text('Nhà cung cấp', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary, size: 28),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            child: Icon(
                              movement.toLocationType == 'warehouse' ? Icons.warehouse_rounded : Icons.storefront_rounded,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            movement.toLocationName.isNotEmpty ? movement.toLocationName : 'Nơi nhận',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            movement.toLocationType == 'warehouse' ? 'Kho nhận' : 'Chi nhánh nhận',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                    _buildInfoRow(Icons.person_outline_rounded, 'Người tạo', movement.requestedByName ?? '—', theme),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.calendar_today_rounded, 'Ngày tạo', dateStr, theme),
                    if (movement.note != null && movement.note!.isNotEmpty) ...[
                      const Divider(height: 20),
                      _buildInfoRow(Icons.note_outlined, 'Ghi chú đơn', movement.note!, theme),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách sản phẩm (${showEditableLines ? _editLines.length : movement.details.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (showEditableLines)
                  OutlinedButton.icon(
                    onPressed: _addEditLine,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thêm sản phẩm'),
                  )
                else
                  Text(
                    'Tổng: ${movement.totalQty} sp',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_showReceiveForm && flags.canReceive)
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
            if (showEditableLines)
              ..._editLines.asMap().entries.map((entry) => _buildEditLineCard(entry.key, entry.value, theme))
            else
              ...movement.details.map((item) => _buildProductItemCard(item, theme, isInTransit, isReceived)),
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng giá trị đơn nhập', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      currencyFormat.format(movement.totalValue),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _isActionLoading
          ? const SafeArea(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())))
          : _buildActionBar(theme, flags, showEditableLines),
    );
  }

  Widget? _buildActionBar(ThemeData theme, ImportActionFlags flags, bool showEditableLines) {
    final buttons = <Widget>[];

    if (showEditableLines) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saveDetails,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Cập nhật phiếu'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      );
    }

    if (flags.canShip) {
      buttons.add(
        Row(
          children: [
            if (flags.canCancel) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Hủy đơn'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _handleShip,
                icon: const Icon(Icons.local_shipping_rounded),
                label: const Text('Giao hàng'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
      );
    }

    if (flags.canReceive && !_showReceiveForm) {
      buttons.add(
        Row(
          children: [
            if (flags.canCancel) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Hủy đơn'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => setState(() => _showReceiveForm = true),
                icon: const Icon(Icons.move_to_inbox_rounded),
                label: const Text('Nhận hàng'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
      );
    }

    if (flags.canReceive && _showReceiveForm) {
      buttons.add(
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showReceiveForm = false),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text('Đóng'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _handleConfirmReceive,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Xác nhận nhận hàng'),
                style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
      );
    }

    if (flags.canCancel && !flags.canShip && !flags.canReceive) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Hủy đơn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            buttons[i],
          ],
        ],
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
        Expanded(flex: 2, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
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
              Text('SKU: ${item.sku}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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

  Widget _buildEditLineCard(int index, _EditLine line, ThemeData theme) {
    final price = double.tryParse(line.priceController.text);
    final priceOverRetail = line.retailPrice != null && line.retailPrice! > 0 && price != null && price > line.retailPrice!;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.sku.isNotEmpty ? '${line.productName} (${line.sku})' : line.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                if (_editLines.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: () => _removeEditLine(index),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: line.priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Giá nhập (đ) *',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      errorText: priceOverRetail ? 'Không được cao hơn giá bán' : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: line.noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditLine {
  final String productItemId;
  final String productName;
  final String sku;
  final double? retailPrice;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  final TextEditingController noteController;

  _EditLine({
    required this.productItemId,
    required this.productName,
    required this.sku,
    this.retailPrice,
    required int qty,
    required double price,
    String? note,
  })  : qtyController = TextEditingController(text: qty.toString()),
        priceController = TextEditingController(text: price.toStringAsFixed(0)),
        noteController = TextEditingController(text: note ?? '');

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
    noteController.dispose();
  }
}

/// Small fetch-once + client-filter picker for adding a new line while
/// editing a PENDING import's line items, sourced from
/// `getProductItemsForDestination` (already fetched by the parent view).
class _DestinationProductPickerSheet extends StatefulWidget {
  final List<StockMovementProductItemOption> items;

  const _DestinationProductPickerSheet({required this.items});

  @override
  State<_DestinationProductPickerSheet> createState() => _DestinationProductPickerSheetState();
}

class _DestinationProductPickerSheetState extends State<_DestinationProductPickerSheet> {
  String _query = '';

  List<StockMovementProductItemOption> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text('Chọn sản phẩm', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo tên hoặc SKU...',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'Không tìm thấy sản phẩm nào',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: item.sku.isNotEmpty ? Text(item.sku) : null,
                            onTap: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
