import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/location_option_api_service.dart';
import '../../../data/services/category_api_service.dart';
import '../../auth/viewmodels/user_profile_provider.dart';
import '../viewmodels/product_list_view_model.dart';
import 'package:barcode_widget/barcode_widget.dart';

class ProductListView extends ConsumerStatefulWidget {
  const ProductListView({super.key});

  @override
  ConsumerState<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends ConsumerState<ProductListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productListViewModelProvider.notifier).fetchProducts(isRefresh: true);
      _loadFilters();
    });
  }

  Future<void> _loadFilters() async {
    try {
      final branches = await ref.read(locationOptionApiServiceProvider).getBranches();
      final warehouses = await ref.read(locationOptionApiServiceProvider).getWarehouses();
      final categories = await ref.read(categoryApiServiceProvider).getList(limit: 100);
      setState(() {
        _locations = [...branches, ...warehouses];
        _categories = categories;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListViewModelProvider.notifier).fetchProducts();
    }
  }

  String _getBranchName(String locationId) {
    final location = _locations.firstWhere(
      (loc) => loc['_id']?.toString() == locationId,
      orElse: () => <String, dynamic>{},
    );
    return location['name']?.toString() ?? 'Kho khác';
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(productListViewModelProvider.notifier).search(query);
    });
  }

  void _showBranchPicker() async {
    final user = await ref.read(userProfileProvider.future);
    
    List<Map<String, dynamic>> allowedLocations = _locations;
    if (user != null && user.role != 'TENANT_OWNER') {
      allowedLocations = _locations.where((loc) {
        final locId = loc['_id']?.toString();
        return locId == user.branchId || locId == user.warehouseId;
      }).toList();
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Toàn hệ thống'),
              onTap: () {
                ref.read(productListViewModelProvider.notifier).setLocation(null);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ...allowedLocations.map((loc) => ListTile(
              title: Text(loc['name'] ?? ''),
              onTap: () {
                ref.read(productListViewModelProvider.notifier).setLocation(loc['_id']);
                Navigator.pop(context);
              },
            )),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListViewModelProvider);
    final theme = Theme.of(context);

    // Get filter names for display
    final branchName = state.selectedLocationId == null 
        ? 'Toàn hệ thống' 
        : _locations.firstWhere((b) => b['_id'] == state.selectedLocationId, orElse: () => {'name': 'Kho/Chi nhánh'})['name'];
        
    final categoryName = state.selectedCategoryId == null 
        ? 'Danh mục' 
        : _categories.firstWhere((c) => c['_id'] == state.selectedCategoryId, orElse: () => {'name': 'Danh mục'})['name'];

    final statusName = state.selectedStatus == null 
        ? 'Trạng thái' 
        : (state.selectedStatus == 'ACTIVE' ? 'Đang bán' : 'Ngừng bán');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách hàng hoá'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm hàng hoá...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          // Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _showBranchPicker,
                  icon: const Icon(Icons.storefront, size: 16),
                  label: Text(branchName),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  initialValue: state.selectedCategoryId,
                  onSelected: (val) => ref.read(productListViewModelProvider.notifier).setCategory(val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: null, child: Text('Tất cả danh mục')),
                    ..._categories.map((c) => PopupMenuItem(value: c['_id']?.toString(), child: Text(c['name'] ?? ''))),
                  ],
                  child: Chip(
                    label: Text(categoryName),
                    deleteIcon: state.selectedCategoryId != null ? const Icon(Icons.close, size: 16) : null,
                    onDeleted: state.selectedCategoryId != null 
                        ? () => ref.read(productListViewModelProvider.notifier).setCategory(null) 
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  initialValue: state.selectedStatus,
                  onSelected: (val) => ref.read(productListViewModelProvider.notifier).setStatus(val),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: null, child: Text('Tất cả trạng thái')),
                    PopupMenuItem(value: 'ACTIVE', child: Text('Đang bán')),
                    PopupMenuItem(value: 'INACTIVE', child: Text('Ngừng bán')),
                    PopupMenuItem(value: 'DISCONTINUED', child: Text('Ngừng sản xuất')),
                  ],
                  child: Chip(
                    label: Text(statusName),
                    deleteIcon: state.selectedStatus != null ? const Icon(Icons.close, size: 16) : null,
                    onDeleted: state.selectedStatus != null 
                        ? () => ref.read(productListViewModelProvider.notifier).setStatus(null) 
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildBody(state, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ProductListState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi: ${state.error}',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(productListViewModelProvider.notifier).refresh();
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state.products.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy hàng hoá nào.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(productListViewModelProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: state.products.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.products.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final product = state.products[index];
          return _ProductCard(
            product: product,
            selectedLocationId: state.selectedLocationId,
            getBranchName: _getBranchName,
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final String? selectedLocationId;
  final String Function(String) getBranchName;

  const _ProductCard({
    super.key,
    required this.product,
    required this.selectedLocationId,
    required this.getBranchName,
  });

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${kBaseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,##0', 'vi_VN');
    final imageUrl = _getImageUrl(product.thumbnail);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(12.0),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.hardEdge,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.inventory_2_outlined, color: theme.colorScheme.onSurfaceVariant),
                      )
                    : Icon(Icons.inventory_2_outlined, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (product.categoryName != null) product.categoryName!,
                        if (product.brandName != null) product.brandName!,
                      ].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tồn kho: ${numberFormat.format(product.totalStock)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: product.totalStock > 0 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.status == 'ACTIVE'
                                ? Colors.green.withOpacity(0.1)
                                : theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.status == 'ACTIVE' ? 'Đang bán' : 'Ngừng',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: product.status == 'ACTIVE'
                                  ? Colors.green[700]
                                  : theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: product.items.isEmpty
              ? [const Padding(padding: EdgeInsets.all(16.0), child: Text('Không có phiên bản nào'))]
              : product.items.map((item) {
                  return Container(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.thumbnail != null && item.thumbnail!.isNotEmpty) ...[
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Image.network(
                              _getImageUrl(item.thumbnail),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.inventory_2_outlined, color: theme.colorScheme.onSurfaceVariant, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text('SKU: ${item.sku}', style: theme.textTheme.bodySmall),
                              if (item.barcode != null && item.barcode!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: BarcodeWidget(
                                    barcode: Barcode.code128(),
                                    data: item.barcode!,
                                    drawText: true,
                                    style: const TextStyle(fontSize: 10),
                                    errorBuilder: (context, error) => Text('Mã vạch: ${item.barcode}', style: theme.textTheme.bodySmall),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${numberFormat.format(item.retailPrice)} đ',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              const SizedBox(height: 4),
                              if (selectedLocationId == null && item.stockDetails.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: item.stockDetails.map((detail) {
                                    final locId = detail['locationId']?.toString() ?? '';
                                    final stockStr = numberFormat.format(detail['stock'] ?? 0);
                                    return Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9), // Light green tint
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${getBranchName(locId)}: $stockStr',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF0F9D58),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                )
                              else
                                Text('Tồn: ${numberFormat.format(item.stock)}', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }
}
