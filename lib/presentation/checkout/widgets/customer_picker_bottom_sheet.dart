import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/customer_api_service.dart';

class CustomerPickerBottomSheet extends ConsumerStatefulWidget {
  const CustomerPickerBottomSheet({super.key});

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CustomerPickerBottomSheet(),
    );
  }

  @override
  ConsumerState<CustomerPickerBottomSheet> createState() => _CustomerPickerBottomSheetState();
}

class _CustomerPickerBottomSheetState extends ConsumerState<CustomerPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await ref.read(customerApiServiceProvider).searchCustomers(query: query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chọn khách hàng',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, SĐT...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty 
                    ? const Center(child: Text('Không tìm thấy khách hàng nào'))
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final customer = _results[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(Icons.person, color: theme.colorScheme.primary),
                            ),
                            title: Text(customer['name'] ?? 'Không tên'),
                            subtitle: Text(customer['phone'] ?? 'Không có SĐT'),
                            onTap: () {
                              Navigator.pop(context, customer);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
