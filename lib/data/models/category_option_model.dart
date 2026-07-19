/// One entry of `GET /categories`, used only to populate the category
/// multi-select in the promotion create/edit form.
class CategoryOption {
  final String id;
  final String name;

  const CategoryOption({required this.id, required this.name});

  factory CategoryOption.fromJson(Map<String, dynamic> json) {
    return CategoryOption(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
