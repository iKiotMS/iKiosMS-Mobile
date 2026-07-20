import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/stock_movement_repository.dart';

const _debounceDuration = Duration(milliseconds: 300);

/// Bottom sheet: search the full product catalog and tap one to add it as an
/// import line. Results not present in [linkedProductIds] (the chosen
/// supplier's already-linked products) are flagged "Chưa thuộc NCC" — the
/// create view then offers to attach the supplier before letting the order
/// submit, mirroring the web app's `imports-create-dialog.tsx` search panel.
class ImportProductPickerSheet extends ConsumerStatefulWidget {
  final Set<String> linkedProductIds;

  const ImportProductPickerSheet({super.key, required this.linkedProductIds});

  static Future<StockMovementProductItemOption?> show(
    BuildContext context, {
    required Set<String> linkedProductIds,
  }) {
    return showModalBottomSheet<StockMovementProductItemOption>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ImportProductPickerSheet(linkedProductIds: linkedProductIds),
    );
  }

  @override
  ConsumerState<ImportProductPickerSheet> createState() => _ImportProductPickerSheetState();
}

class _ImportProductPickerSheetState extends ConsumerState<ImportProductPickerSheet> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  Timer? _debounce;

  bool _isLoading = true;
  String? _errorMessage;
  List<StockMovementProductItemOption> _items = const [];

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
      final repository = ref.read(stockMovementRepositoryProvider);
      final items = await repository.searchProductItems(query);
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Tìm kiếm sản phẩm thất bại';
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
        final isLinked = widget.linkedProductIds.contains(item.id);
        return ListTile(
          title: Text(item.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.sku.isNotEmpty) Text(item.sku),
              if (!isLinked)
                Text(
                  'Chưa thuộc NCC',
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 12, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          trailing: Text(
            _currencyFormat.format(item.costPrice),
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          onTap: () => Navigator.of(context).pop(item),
        );
      },
    );
  }
}
