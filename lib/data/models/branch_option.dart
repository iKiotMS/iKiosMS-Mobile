/// A minimal branch reference used by pickers/filters (id + display name).
///
/// Maps to a subset of the backend `Branch` model returned by `GET /branches`.
class BranchOption {
  final String id;
  final String name;

  const BranchOption({required this.id, required this.name});

  factory BranchOption.fromJson(Map<String, dynamic> json) {
    return BranchOption(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Chi nhánh',
    );
  }
}
