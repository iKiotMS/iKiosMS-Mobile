import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/stock_movement_repository.dart';

/// Bottom sheet: pick a supplier for a "Nhập hàng" order. Fetches the
/// supplier list once (small tenant-scoped list) and filters client-side as
/// the user types, unlike the debounced remote search used for products.
class SupplierPickerSheet extends ConsumerStatefulWidget {
  const SupplierPickerSheet({super.key});

  static Future<SupplierOption?> show(BuildContext context) {
    return showModalBottomSheet<SupplierOption>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SupplierPickerSheet(),
    );
  }

  @override
  ConsumerState<SupplierPickerSheet> createState() => _SupplierPickerSheetState();
}

class _SupplierPickerSheetState extends ConsumerState<SupplierPickerSheet> {
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<SupplierOption> _suppliers = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(stockMovementRepositoryProvider);
      final suppliers = await repository.getSupplierOptions();
      if (!mounted) return;
      setState(() {
        _suppliers = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Tải danh sách nhà cung cấp thất bại';
      });
    }
  }

  List<SupplierOption> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _suppliers;
    return _suppliers.where((s) => s.name.toLowerCase().contains(q)).toList();
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
                    Text('Chọn nhà cung cấp', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo tên nhà cung cấp...',
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
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text('Không tìm thấy nhà cung cấp nào', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final supplier = items[index];
        return ListTile(
          title: Text(supplier.name),
          onTap: () => Navigator.of(context).pop(supplier),
        );
      },
    );
  }
}
