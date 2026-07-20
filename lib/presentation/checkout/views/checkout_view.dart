import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../data/services/product_api_service.dart';
import '../viewmodels/checkout_view_model.dart';
import '../widgets/customer_picker_bottom_sheet.dart';
import '../widgets/create_customer_bottom_sheet.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      try {
        final result = await ref.read(productApiServiceProvider).getProducts(search: query, limit: 10);
        
        final userProfile = ref.read(userProfileProvider).value;
        final branchId = userProfile?.branchId;

        final flattened = <Map<String, dynamic>>[];
        for (var product in result.data) {
          for (var item in product.items) {
            int branchStock = 0;
            if (branchId != null && branchId.isNotEmpty) {
              for (var stock in item.stockDetails) {
                if (stock['locationId'] == branchId) {
                  branchStock += (num.tryParse(stock['stock']?.toString() ?? '0') ?? 0).toInt();
                }
              }
            } else {
              branchStock = item.stock;
            }

            flattened.add({
              '_id': item.id,
              'productCode': item.productCode,
              'sku': item.sku,
              'barcode': item.barcode,
              'productName': '${product.name} (${item.sku})',
              'retailPrice': item.retailPrice,
              'stock': branchStock,
              'images': product.thumbnail != null ? [{'url': product.thumbnail, 'isThumbnail': true}] : null,
            });
          }
        }
        
        if (mounted) {
          setState(() {
            _searchResults = flattened;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  void _onProductSelected(Map<String, dynamic> product) {
    ref.read(checkoutViewModelProvider.notifier).addItem(product);
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchResults = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm ${product['productName']}'), duration: const Duration(seconds: 1)),
    );
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$kBaseUrl$path';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutViewModelProvider);
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,##0', 'vi_VN');

    // Sync customerPay with grandTotal if cash payment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.paymentMethod == 'CASH' && state.customerPay < state.grandTotal && !state.isSubmitting) {
        ref.read(checkoutViewModelProvider.notifier).setCustomerPay(state.grandTotal);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo hóa đơn'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tìm sản phẩm, quét mã vạch...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : const Icon(Icons.qr_code_scanner),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),

              // Cart Items
              Expanded(
                child: state.items.isEmpty
                    ? const Center(
                        child: Text(
                          'Giỏ hàng trống.\nVui lòng tìm kiếm sản phẩm phía trên.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          final imgUrl = _getImageUrl(item.imageUrl);
                          
                          return Dismissible(
                            key: Key(item.productItemId),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => ref.read(checkoutViewModelProvider.notifier).removeItem(item.productItemId),
                            background: Container(
                              color: theme.colorScheme.error,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: Icon(Icons.delete, color: theme.colorScheme.onError),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: imgUrl.isNotEmpty
                                    ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image))
                                    : const Icon(Icons.image),
                              ),
                              title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${numberFormat.format(item.unitPrice)} đ', style: TextStyle(color: theme.colorScheme.primary)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => ref.read(checkoutViewModelProvider.notifier).updateItemQuantity(item.productItemId, item.quantity - 1),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => ref.read(checkoutViewModelProvider.notifier).updateItemQuantity(item.productItemId, item.quantity + 1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Sheet Summary
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Khách hàng',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final customer = await CreateCustomerBottomSheet.show(context);
                                if (customer != null) {
                                  ref.read(checkoutViewModelProvider.notifier).setCustomer(customer);
                                }
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Thêm mới'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Customer Picker
                        InkWell(
                          onTap: () async {
                            final customer = await CustomerPickerBottomSheet.show(context);
                            if (customer != null) {
                              ref.read(checkoutViewModelProvider.notifier).setCustomer(customer);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.selectedCustomer != null ? (state.selectedCustomer!['name'] ?? 'Khách hàng') : 'Chọn khách hàng (Tuỳ chọn)',
                                    style: TextStyle(
                                      color: state.selectedCustomer != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                      fontWeight: state.selectedCustomer != null ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (state.selectedCustomer != null)
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () => ref.read(checkoutViewModelProvider.notifier).setCustomer(null),
                                  )
                                else
                                  const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Payment Method
                        Row(
                          children: [
                            Expanded(
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(value: 'CASH', label: Text('Tiền mặt')),
                                  ButtonSegment(value: 'SEPAY', label: Text('Chuyển khoản QR')),
                                ],
                                selected: {state.paymentMethod},
                                onSelectionChanged: (set) {
                                  ref.read(checkoutViewModelProvider.notifier).setPaymentMethod(set.first);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Totals
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng số lượng:'),
                            Text('${state.items.fold(0, (sum, i) => sum + i.quantity)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tạm tính:'),
                            Text('${numberFormat.format(state.subtotal)} đ'),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Khách cần trả:',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${numberFormat.format(state.grandTotal)} đ',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Error message
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(state.error!, style: TextStyle(color: theme.colorScheme.error)),
                          ),

                        // Checkout Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: state.isSubmitting || state.items.isEmpty
                                ? null
                                : () async {
                                    try {
                                      await ref.read(checkoutViewModelProvider.notifier).submitOrder();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Tạo hóa đơn thành công!')),
                                        );
                                      }
                                    } catch (_) {}
                                  },
                            child: state.isSubmitting
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Thanh Toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Search Dropdown Overlay
          if (_searchController.text.isNotEmpty && (_searchResults.isNotEmpty || _isSearching))
            Positioned(
              top: 76,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isSearching
                      ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final product = _searchResults[index];
                            return ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: (product['images'] != null && product['images'].isNotEmpty && product['images'][0]['url'] != null)
                                    ? Image.network(_getImageUrl(product['images'][0]['url']), fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image))
                                    : const Icon(Icons.image),
                              ),
                              title: Text(product['productName'] ?? ''),
                              subtitle: Text(
                                'SKU: ${product['sku']} - ${numberFormat.format(product['retailPrice'] ?? 0)} đ',
                                style: TextStyle(color: theme.colorScheme.primary),
                              ),
                              trailing: Text('Tồn: ${product['stock'] ?? 0}'),
                              onTap: () => _onProductSelected(product),
                            );
                          },
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
