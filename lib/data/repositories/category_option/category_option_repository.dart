import '../../models/category_option_model.dart';

/// Abstract interface for the category-option repository (used only by the
/// promotion form's category multi-select picker).
abstract class CategoryOptionRepository {
  Future<List<CategoryOption>> getCategoryOptions({String? search});
}
