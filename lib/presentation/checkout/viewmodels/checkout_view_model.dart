import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/services/order_api_service.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

part 'checkout_view_model.g.dart';

class CartItemModel {
  final String productItemId;
  final String productCode;
  final String sku;
  final String name;
  final String? barcode;
  final num unitPrice;
  final int quantity;
  final num discountAmount;
  final String? imageUrl;

  CartItemModel({
    required this.productItemId,
    required this.productCode,
    required this.sku,
    required this.name,
    this.barcode,
    required this.unitPrice,
    this.quantity = 1,
    this.discountAmount = 0,
    this.imageUrl,
  });

  CartItemModel copyWith({
    int? quantity,
    num? unitPrice,
    num? discountAmount,
  }) {
    return CartItemModel(
      productItemId: productItemId,
      productCode: productCode,
      sku: sku,
      name: name,
      barcode: barcode,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
      imageUrl: imageUrl,
    );
  }
}

class CheckoutState {
  final List<CartItemModel> items;
  final Map<String, dynamic>? selectedCustomer;
  final String paymentMethod; // 'CASH' or 'SEPAY'
  final num discount;
  final String discountType; // 'cash' or 'percent'
  final num customerPay;
  final String note;
  final bool isSubmitting;
  final String? error;

  CheckoutState({
    this.items = const [],
    this.selectedCustomer,
    this.paymentMethod = 'CASH',
    this.discount = 0,
    this.discountType = 'cash',
    this.customerPay = 0,
    this.note = '',
    this.isSubmitting = false,
    this.error,
  });

  num get subtotal => items.fold(0, (sum, item) => sum + item.quantity * (item.unitPrice - item.discountAmount));
  
  num get grandTotal {
    final discountVal = discountType == 'cash' ? discount : (subtotal * discount / 100);
    return (subtotal - discountVal) > 0 ? (subtotal - discountVal) : 0;
  }

  CheckoutState copyWith({
    List<CartItemModel>? items,
    Map<String, dynamic>? selectedCustomer,
    String? paymentMethod,
    num? discount,
    String? discountType,
    num? customerPay,
    String? note,
    bool? isSubmitting,
    String? error,
    bool clearCustomer = false,
  }) {
    return CheckoutState(
      items: items ?? this.items,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      customerPay: customerPay ?? this.customerPay,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

@riverpod
class CheckoutViewModel extends _$CheckoutViewModel {
  @override
  CheckoutState build() {
    return CheckoutState();
  }

  void addItem(Map<String, dynamic> productItem) {
    final id = productItem['_id']?.toString() ?? '';
    final existingIndex = state.items.indexWhere((item) => item.productItemId == id);

    if (existingIndex > -1) {
      final updated = List<CartItemModel>.from(state.items);
      updated[existingIndex] = updated[existingIndex].copyWith(
        quantity: updated[existingIndex].quantity + 1,
      );
      state = state.copyWith(items: updated);
    } else {
      final newItem = CartItemModel(
        productItemId: id,
        productCode: productItem['productCode']?.toString() ?? '',
        sku: productItem['sku']?.toString() ?? '',
        name: productItem['productName']?.toString() ?? '',
        barcode: productItem['barcode']?.toString(),
        unitPrice: num.tryParse(productItem['retailPrice']?.toString() ?? '0') ?? 0,
        imageUrl: productItem['images']?.isNotEmpty == true ? productItem['images'][0]['url'] : null,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateItemQuantity(String id, int quantity) {
    if (quantity < 1) return;
    final updated = state.items.map((e) => e.productItemId == id ? e.copyWith(quantity: quantity) : e).toList();
    state = state.copyWith(items: updated);
  }

  void removeItem(String id) {
    final updated = state.items.where((e) => e.productItemId != id).toList();
    state = state.copyWith(items: updated);
  }

  void setCustomer(Map<String, dynamic>? customer) {
    state = state.copyWith(selectedCustomer: customer, clearCustomer: customer == null);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setCustomerPay(num pay) {
    state = state.copyWith(customerPay: pay);
  }

  Future<void> submitOrder() async {
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Giỏ hàng trống');
      return;
    }

    final grandTotal = state.grandTotal;
    if (state.paymentMethod == 'CASH' && state.customerPay < grandTotal) {
      state = state.copyWith(error: 'Khách thanh toán phải >= Tổng tiền');
      return;
    }

    final userProfile = ref.read(userProfileProvider).value;
    final branchId = userProfile?.branchId;

    if (branchId == null || branchId.isEmpty) {
      state = state.copyWith(error: 'Không tìm thấy chi nhánh');
      return;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final api = ref.read(orderApiServiceProvider);
      
      final payload = {
        'customerId': state.selectedCustomer?['_id'],
        'branchId': branchId,
        'paymentMethod': state.paymentMethod,
        'grandTotal': grandTotal,
        'customerPay': state.customerPay,
        'note': state.note,
        'discountType': state.discount > 0 ? 'ORDER' : null,
        'discountValue': state.discount > 0 ? (state.discountType == 'cash' ? state.discount : (state.subtotal * state.discount / 100)) : 0,
        'items': state.items.map((e) => {
          'productItemId': e.productItemId,
          'productName': e.name,
          'quantity': e.quantity,
          'unitPrice': e.unitPrice,
          'discountAmount': e.discountAmount,
        }).toList(),
      };

      await api.createOrder(payload);
      
      // Reset after success
      state = CheckoutState();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isSubmitting: false);
      throw e;
    }
  }
}
