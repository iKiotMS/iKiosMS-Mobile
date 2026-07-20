// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/stock_movement_repository.dart';
import '../../auth/viewmodels/user_profile_provider.dart';
import '../shared/import_pricing.dart';
import '../widgets/import_product_picker_sheet.dart';
import '../widgets/supplier_picker_sheet.dart';

/// "Tạo đơn nhập hàng" — pick a supplier, a receiving location (locked to
/// the caller's own warehouse for WAREHOUSE_MANAGER, pickable for
/// TENANT_OWNER), add line items, then submit. Mirrors the web app's
/// `imports-create-dialog.tsx`, including the "attach supplier to product"
/// flow for catalog products not yet linked to the chosen supplier.
class ImportCreateView extends ConsumerStatefulWidget {
  const ImportCreateView({super.key});

  @override
  ConsumerState<ImportCreateView> createState() => _ImportCreateViewState();
}

class _ImportCreateViewState extends ConsumerState<ImportCreateView> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final TextEditingController _noteController = TextEditingController();

  bool _isLoadingInit = true;
  String? _initError;

  bool _requiresLocationPicker = false;
  List<StockMovementLocationOption> _locationOptions = const [];
  String? _toLocationId;
  String? _toLocationType;
  String? _toLocationLabel;

  SupplierOption? _supplier;
  Set<String> _linkedProductIds = {};
  bool _isLoadingSupplierProducts = false;

  final List<_ImportDraftLine> _lines = [];
  String? _attachingItemId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    final profile = await ref.read(userProfileProvider.future);
    if (!mounted) return;

    if (profile == null) {
      setState(() {
        _isLoadingInit = false;
        _initError = 'Không tìm thấy thông tin tài khoản.';
      });
      return;
    }

    if (profile.role == 'WAREHOUSE_MANAGER' && profile.warehouseId != null) {
      setState(() {
        _toLocationId = profile.warehouseId;
        _toLocationType = 'warehouse';
        _toLocationLabel = 'Kho của tôi';
        _requiresLocationPicker = false;
        _isLoadingInit = false;
      });
      return;
    }

    if (profile.role == 'TENANT_OWNER') {
      setState(() => _requiresLocationPicker = true);
      final repo = ref.read(stockMovementRepositoryProvider);
      final locations = await repo.getLocationOptions();
      if (!mounted) return;
      setState(() {
        _locationOptions = locations;
        _isLoadingInit = false;
      });
      return;
    }

    setState(() {
      _isLoadingInit = false;
      _initError = 'Tài khoản của bạn không có quyền tạo đơn nhập hàng.';
    });
  }

  Future<void> _pickSupplier() async {
    final selected = await SupplierPickerSheet.show(context);
    if (selected == null) return;

    for (final line in _lines) {
      line.dispose();
    }
    setState(() {
      _supplier = selected;
      _lines.clear();
      _linkedProductIds = {};
    });
    _loadSupplierProducts(selected.id);
  }

  Future<void> _loadSupplierProducts(String supplierId) async {
    setState(() => _isLoadingSupplierProducts = true);
    try {
      final repo = ref.read(stockMovementRepositoryProvider);
      final items = await repo.getSupplierProductItems(supplierId);
      if (!mounted) return;
      setState(() {
        _linkedProductIds = items.map((e) => e.id).toSet();
        _isLoadingSupplierProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSupplierProducts = false);
    }
  }

  Future<void> _pickProduct() async {
    if (_supplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn nhà cung cấp trước')));
      return;
    }

    final picked = await ImportProductPickerSheet.show(context, linkedProductIds: _linkedProductIds);
    if (picked == null) return;

    final existingIndex = _lines.indexWhere((l) => l.productItemId == picked.id);
    if (existingIndex != -1) {
      setState(() {
        final current = int.tryParse(_lines[existingIndex].qtyController.text) ?? 0;
        _lines[existingIndex].qtyController.text = (current + 1).toString();
      });
      return;
    }

    setState(() {
      _lines.add(_ImportDraftLine(
        productItemId: picked.id,
        productName: picked.name,
        sku: picked.sku,
        retailPrice: picked.retailPrice,
        initialPrice: resolveImportPrice(picked),
      ));
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  Future<void> _attachSupplier(_ImportDraftLine line) async {
    if (_supplier == null) return;
    setState(() => _attachingItemId = line.productItemId);
    try {
      final repo = ref.read(stockMovementRepositoryProvider);
      await repo.attachSupplierToProductItem(line.productItemId, _supplier!.id);
      if (!mounted) return;
      setState(() {
        _linkedProductIds = {..._linkedProductIds, line.productItemId};
        _attachingItemId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm nhà cung cấp cho sản phẩm')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _attachingItemId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể thêm nhà cung cấp: $e')));
    }
  }

  double get _totalPrice {
    double total = 0;
    for (final line in _lines) {
      final qty = int.tryParse(line.qtyController.text) ?? 0;
      final price = double.tryParse(line.priceController.text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  bool get _canSubmit {
    if (_supplier == null || _toLocationId == null || _toLocationType == null) return false;
    if (_lines.isEmpty) return false;
    if (_attachingItemId != null) return false;
    for (final line in _lines) {
      if (!_linkedProductIds.contains(line.productItemId)) return false;
      final qty = int.tryParse(line.qtyController.text) ?? 0;
      if (qty <= 0) return false;
      final price = double.tryParse(line.priceController.text) ?? -1;
      if (price <= 0) return false;
      if (line.retailPrice != null && line.retailPrice! > 0 && price > line.retailPrice!) return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(stockMovementRepositoryProvider);
      final details = _lines.map((line) {
        return {
          'productItemId': line.productItemId,
          'quantity': int.tryParse(line.qtyController.text) ?? 1,
          'importPrice': double.tryParse(line.priceController.text) ?? 0,
          if (line.noteController.text.trim().isNotEmpty) 'note': line.noteController.text.trim(),
        };
      }).toList();

      // fromLocationId/Type deliberately mirror toLocationId/Type so the
      // destination warehouse manager can later ship/cancel this request
      // (see StockMovementService's `_checkLocationAuth` for ship/cancel).
      await repo.createImport({
        'movementType': 'IMPORT',
        'fromSupplierId': _supplier!.id,
        'toLocationId': _toLocationId,
        'toLocationType': _toLocationType,
        'fromLocationId': _toLocationId,
        'fromLocationType': _toLocationType,
        if (_noteController.text.trim().isNotEmpty) 'note': _noteController.text.trim(),
        'details': details,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo đơn nhập hàng thành công!')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể tạo đơn: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingInit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tạo đơn nhập hàng')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tạo đơn nhập hàng')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 40, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text(_initError!, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo đơn nhập hàng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin đơn nhập', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickSupplier,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Nhà cung cấp *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_shipping_outlined),
                        ),
                        child: Text(_supplier?.name ?? 'Chọn nhà cung cấp'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_requiresLocationPicker)
                      DropdownButtonFormField<String>(
                        value: _toLocationId,
                        decoration: const InputDecoration(
                          labelText: 'Kho/Chi nhánh nhận *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warehouse_outlined),
                        ),
                        items: _locationOptions.map((loc) {
                          return DropdownMenuItem(
                            value: loc.id,
                            child: Text('${loc.name} (${loc.type == 'warehouse' ? 'Kho' : 'Chi nhánh'})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final loc = _locationOptions.firstWhere((l) => l.id == val);
                          setState(() {
                            _toLocationId = loc.id;
                            _toLocationType = loc.type;
                          });
                        },
                      )
                    else
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Kho nhận',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warehouse_outlined),
                        ),
                        child: Text(_toLocationLabel ?? '—'),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú đơn (tùy chọn)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Danh sách mặt hàng (${_lines.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: _pickProduct,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Thêm sản phẩm'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingSupplierProducts)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (_lines.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Chưa có sản phẩm nào. Nhấn "Thêm sản phẩm" để bắt đầu.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else
              ..._lines.asMap().entries.map((entry) => _buildLineCard(entry.key, entry.value, theme)),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng giá trị đơn nhập', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      currencyFormat.format(_totalPrice),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _canSubmit && !_isSubmitting ? _submit : null,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(_isSubmitting ? 'Đang tạo...' : 'Tạo đơn nhập hàng'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLineCard(int index, _ImportDraftLine line, ThemeData theme) {
    final isLinked = _linkedProductIds.contains(line.productItemId);
    final price = double.tryParse(line.priceController.text);
    final priceOverRetail = line.retailPrice != null && line.retailPrice! > 0 && price != null && price > line.retailPrice!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () => _removeLine(index),
                ),
              ],
            ),
            if (!isLinked)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hàng chưa thuộc nhà cung cấp đã chọn.',
                        style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _attachingItemId == line.productItemId ? null : () => _attachSupplier(line),
                      icon: _attachingItemId == line.productItemId
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.link_rounded, size: 16),
                      label: const Text('Thêm NCC', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
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

class _ImportDraftLine {
  final String productItemId;
  final String productName;
  final String sku;
  final double? retailPrice;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  final TextEditingController noteController;

  _ImportDraftLine({
    required this.productItemId,
    required this.productName,
    required this.sku,
    this.retailPrice,
    required double initialPrice,
  })  : qtyController = TextEditingController(text: '1'),
        priceController = TextEditingController(text: initialPrice.toStringAsFixed(0)),
        noteController = TextEditingController();

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
    noteController.dispose();
  }
}
