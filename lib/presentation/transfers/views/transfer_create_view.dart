// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/stock_movement_repository.dart';

class TransferCreateView extends ConsumerStatefulWidget {
  const TransferCreateView({super.key});

  @override
  ConsumerState<TransferCreateView> createState() => _TransferCreateViewState();
}

class _TransferCreateViewState extends ConsumerState<TransferCreateView> {
  final _formKey = GlobalKey<FormState>();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  List<StockMovementLocationOption> _locations = [];
  List<StockMovementProductItemOption> _sourceProducts = [];
  bool _isLoadingLocations = true;
  bool _isLoadingProducts = false;
  bool _isSubmitting = false;

  String? _fromLocationId;
  String? _toLocationId;
  final TextEditingController _noteController = TextEditingController();

  // Selected items list
  final List<_CreateItemRow> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _addNewItemRow();
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final row in _selectedItems) {
      row.dispose();
    }
    super.dispose();
  }

  void _addNewItemRow() {
    setState(() {
      _selectedItems.add(_CreateItemRow());
    });
  }

  void _removeItemRow(int index) {
    if (_selectedItems.length <= 1) return;
    setState(() {
      _selectedItems[index].dispose();
      _selectedItems.removeAt(index);
    });
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoadingLocations = true);
    try {
      final repo = ref.read(stockMovementRepositoryProvider);
      final locs = await repo.getLocationOptions();
      setState(() {
        _locations = locs;
        _isLoadingLocations = false;
        if (locs.isNotEmpty) {
          _fromLocationId = locs.first.id;
          _loadSourceProducts();
        }
      });
    } catch (e) {
      setState(() => _isLoadingLocations = false);
    }
  }

  Future<void> _loadSourceProducts() async {
    if (_fromLocationId == null) return;
    final fromLoc = _locations.firstWhere((l) => l.id == _fromLocationId, orElse: () => _locations.first);

    setState(() {
      _isLoadingProducts = true;
      _sourceProducts = [];
    });

    try {
      final repo = ref.read(stockMovementRepositoryProvider);
      final items = await repo.getProductItemsAtSource(_fromLocationId!, fromLoc.type);
      setState(() {
        _sourceProducts = items;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
    }
  }

  double get _totalPrice {
    double total = 0;
    for (final row in _selectedItems) {
      final qty = int.tryParse(row.qtyController.text) ?? 0;
      final price = double.tryParse(row.priceController.text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final validToLocations = _locations.where((l) => l.id != _fromLocationId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo yêu cầu chuyển kho'),
      ),
      body: _isLoadingLocations
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Route selection (From -> To)
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
                            Text(
                              'Thông tin nơi gửi / nơi nhận',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            // From Location Dropdown
                            DropdownButtonFormField<String>(
                              value: _fromLocationId,
                              decoration: const InputDecoration(
                                labelText: 'Nơi gửi (Nguồn xuất) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.warehouse_outlined),
                              ),
                              items: _locations.map((loc) {
                                return DropdownMenuItem(
                                  value: loc.id,
                                  child: Text('${loc.name} (${loc.type == 'warehouse' ? 'Kho' : 'Chi nhánh'})'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null && val != _fromLocationId) {
                                  setState(() {
                                    _fromLocationId = val;
                                    if (_toLocationId == val) _toLocationId = null;
                                  });
                                  _loadSourceProducts();
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // To Location Dropdown
                            DropdownButtonFormField<String>(
                              value: _toLocationId,
                              decoration: const InputDecoration(
                                labelText: 'Nơi nhận (Đích đến) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.storefront_outlined),
                              ),
                              items: validToLocations.map((loc) {
                                return DropdownMenuItem(
                                  value: loc.id,
                                  child: Text('${loc.name} (${loc.type == 'warehouse' ? 'Kho' : 'Chi nhánh'})'),
                                );
                              }).toList(),
                              validator: (val) => val == null || val.isEmpty ? 'Vui lòng chọn nơi nhận' : null,
                              onChanged: (val) {
                                setState(() {
                                  _toLocationId = val;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // Order note
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

                    // Section 2: Product Items Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Danh sách mặt hàng (${_selectedItems.length})',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        OutlinedButton.icon(
                          onPressed: _addNewItemRow,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Thêm dòng'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_isLoadingProducts)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_sourceProducts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Không có hàng hóa còn tồn kho tại nơi gửi đã chọn.',
                                style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._selectedItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        return _buildItemRowCard(index, row, theme);
                      }),

                    const SizedBox(height: 16),

                    // Section 3: Total Price & Submit
                    Card(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng giá trị chuyển kho', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              currencyFormat.format(_totalPrice),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
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
                        onPressed: _isSubmitting ? null : _submitExport,
                        icon: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(_isSubmitting ? 'Đang tạo...' : 'Tạo yêu cầu chuyển kho'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildItemRowCard(int index, _CreateItemRow row, ThemeData theme) {
    final selectedProduct = _sourceProducts.firstWhere(
      (p) => p.id == row.selectedProductItemId,
      orElse: () => _sourceProducts.first,
    );

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
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: row.selectedProductItemId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Mặt hàng *',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: _sourceProducts.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.name} (Tồn: ${p.stock})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          row.selectedProductItemId = val;
                          final p = _sourceProducts.firstWhere((x) => x.id == val);
                          row.priceController.text = p.costPrice.toStringAsFixed(0);
                        });
                      }
                    },
                  ),
                ),
                if (_selectedItems.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: () => _removeItemRow(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: row.qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số lượng * (Tồn: ${row.selectedProductItemId != null ? selectedProduct.stock : "-"})',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      final q = int.tryParse(val ?? '0');
                      if (q == null || q <= 0) return 'Số lượng > 0';
                      if (row.selectedProductItemId != null && q > selectedProduct.stock) {
                        return 'Tồn không đủ';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: row.priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Đơn giá (đ) *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      final p = double.tryParse(val ?? '0');
                      if (p == null || p < 0) return 'Giá >= 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitExport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromLocationId == null || _toLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn nơi gửi và nơi nhận')));
      return;
    }

    final fromLoc = _locations.firstWhere((l) => l.id == _fromLocationId);
    final toLoc = _locations.firstWhere((l) => l.id == _toLocationId);

    final movementType = (fromLoc.type == 'branch' && toLoc.type == 'warehouse') ? 'RETURN' : 'EXPORT';

    final List<Map<String, dynamic>> details = [];
    for (final row in _selectedItems) {
      if (row.selectedProductItemId == null) continue;
      final qty = int.tryParse(row.qtyController.text) ?? 1;
      final price = double.tryParse(row.priceController.text) ?? 0;
      details.add({
        'productItemId': row.selectedProductItemId,
        'quantity': qty,
        'importPrice': price,
      });
    }

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất 1 mặt hàng')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(stockMovementRepositoryProvider);
      await repo.createExport({
        'movementType': movementType,
        'fromLocationId': _fromLocationId,
        'fromLocationType': fromLoc.type,
        'toLocationId': _toLocationId,
        'toLocationType': toLoc.type,
        if (_noteController.text.trim().isNotEmpty) 'note': _noteController.text.trim(),
        'details': details,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo yêu cầu thành công!')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể tạo yêu cầu: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _CreateItemRow {
  String? selectedProductItemId;
  final TextEditingController qtyController = TextEditingController(text: '1');
  final TextEditingController priceController = TextEditingController(text: '0');

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}
