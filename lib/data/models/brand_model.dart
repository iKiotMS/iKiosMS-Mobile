class BrandModel {
  final String id;
  final String tenantId;
  final String name;
  final String description;
  final String? website;
  final String status;
  final String createdAt;

  const BrandModel({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description = '',
    this.website,
    required this.status,
    required this.createdAt,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] ?? json['_id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      website: json['website'],
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      if (website != null) 'website': website,
      'status': status,
    };
  }
}

class BrandListResult {
  final List<BrandModel> data;
  final int total;
  final int page;
  final int totalPages;

  const BrandListResult({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory BrandListResult.fromJson(Map<String, dynamic> json) {
    return BrandListResult(
      data: (json['data'] as List?)
              ?.map((e) => BrandModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['pagination']?['total'] ?? 0,
      page: json['pagination']?['page'] ?? 1,
      totalPages: json['pagination']?['totalPages'] ?? 1,
    );
  }
}
