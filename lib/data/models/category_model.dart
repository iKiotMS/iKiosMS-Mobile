class CategoryModel {
  final String id;
  final String tenantId;
  final String name;
  final String description;
  final String? parentId;
  final String status;
  final String createdAt;

  const CategoryModel({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description = '',
    this.parentId,
    required this.status,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String? parentIdStr;
    if (json['parentId'] is Map) {
      parentIdStr = json['parentId']['id'] ?? json['parentId']['_id'];
    } else if (json['parentId'] is String) {
      parentIdStr = json['parentId'];
    }

    return CategoryModel(
      id: json['id'] ?? json['_id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      parentId: parentIdStr,
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      if (parentId != null) 'parentId': parentId,
      'status': status,
    };
  }
}

class CategoryListResult {
  final List<CategoryModel> data;
  final int total;
  final int page;
  final int totalPages;

  const CategoryListResult({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory CategoryListResult.fromJson(Map<String, dynamic> json) {
    return CategoryListResult(
      data: (json['data'] as List?)
              ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['pagination']?['total'] ?? 0,
      page: json['pagination']?['page'] ?? 1,
      totalPages: json['pagination']?['totalPages'] ?? 1,
    );
  }
}
