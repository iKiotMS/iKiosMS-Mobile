import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/inventory_item_model.dart';
import '../../../data/repositories/inventory/inventory_repository_provider.dart';

const int _pageLimit = 30;
const _debounceDuration = Duration(milliseconds: 400);

/// Bottom sheet: search products at [locationId]/[locationType] (shows each
/// product's current system stock) and tap one to add it to the adjustment
/// draft. Opened via [show].
class ProductPickerSheet extends ConsumerStatefulWidget {
  final String locationId;
  final String locationType;

  const ProductPickerSheet({super.key, required this.locationId, required this.locationType});

  static Future<InventoryItem?> show(BuildContext context, {required String locationId, required String locationType}) {
    return showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductPickerSheet(locationId: locationId, locationType: locationType),
    );
  }

  @override
  ConsumerState<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<ProductPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = true;
  String? _errorMessage;
  List<InventoryItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(inventoryRepositoryProvider);
      final items = await repository.getList(
        locationId: widget.locationId,
        locationType: widget.locationType,
        search: query.isEmpty ? null : query,
        page: 1,
        limit: _pageLimit,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Tải danh sách sản phẩm thất bại';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onQueryChanged,
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo tên hoặc SKU...',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 28, color: theme.colorScheme.error),
              const SizedBox(height: 8),
              Text(_errorMessage!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => _search(_searchController.text), child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text('Không tìm thấy sản phẩm nào', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];
        return ListTile(
          title: Text(item.productName),
          subtitle: item.sku != null ? Text(item.sku!) : null,
          trailing: Text(
            'Tồn: ${item.stock}',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          onTap: () => Navigator.of(context).pop(item),
        );
      },
    );
  }
}
