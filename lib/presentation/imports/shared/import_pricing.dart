import '../../../data/models/stock_movement_model.dart';

/// Backend `importPrice` field cap (`StockMovementService` validates against
/// this; the web app's `MAX_IMPORT_PRICE` mirrors the same number).
const double kMaxImportPrice = 1000000000000;

/// Suggested import price for a picked product: prefer cost price, but never
/// exceed retail price — mirrors the web app's `resolveItemImportPrice`.
double resolveImportPrice(StockMovementProductItemOption item) {
  double price = item.costPrice > 0 ? item.costPrice : (item.retailPrice ?? 0);
  if (item.retailPrice != null && item.retailPrice! > 0 && price > item.retailPrice!) {
    price = item.retailPrice!;
  }
  if (price < 0) price = 0;
  if (price > kMaxImportPrice) price = kMaxImportPrice;
  return price;
}
