import '../../models/product_item_option_model.dart';

/// Abstract interface for the product-item-option repository (used only by
/// the promotion form's product multi-select picker).
abstract class ProductItemOptionRepository {
  Future<List<ProductItemOption>> getProductItemOptions({String? search});
}
