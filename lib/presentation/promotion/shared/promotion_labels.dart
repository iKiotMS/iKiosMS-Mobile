/// Vietnamese labels for promotion fields, mirroring the web app's
/// promotion form/table labels. Status label/color live directly on
/// [PromotionModel] since they depend on instance state (expiry check).
library;

String discountTypeLabel(String discountType) {
  switch (discountType) {
    case 'PERCENT':
      return 'Giảm theo %';
    case 'FIXED_AMOUNT':
      return 'Giảm số tiền cố định';
    default:
      return discountType;
  }
}

String applicableRuleTypeLabel(String type) {
  switch (type) {
    case 'category':
      return 'Theo danh mục';
    case 'product':
      return 'Theo sản phẩm';
    default:
      return 'Tất cả sản phẩm';
  }
}

const List<String> promotionStatusFilterOptions = ['ACTIVE', 'INACTIVE'];

String promotionStatusFilterLabel(String status) {
  switch (status) {
    case 'ACTIVE':
      return 'Đang chạy';
    case 'INACTIVE':
      return 'Đã tắt';
    default:
      return status;
  }
}
