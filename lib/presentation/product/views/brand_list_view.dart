import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/brand_model.dart';
import '../viewmodels/brand_list_view_model.dart';

class BrandListView extends ConsumerStatefulWidget {
  const BrandListView({super.key});

  @override
  ConsumerState<BrandListView> createState() => _BrandListViewState();
}

class _BrandListViewState extends ConsumerState<BrandListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brandListViewModelProvider.notifier).fetchBrands(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(brandListViewModelProvider.notifier).fetchBrands();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(brandListViewModelProvider.notifier).search(query);
    });
  }

  void _showBrandDialog([BrandModel? brand]) {
    final isEditing = brand != null;
    final nameController = TextEditingController(text: brand?.name ?? '');
    final descController = TextEditingController(text: brand?.description ?? '');
    final webController = TextEditingController(text: brand?.website ?? '');
    String status = brand?.status ?? 'ACTIVE';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Sửa thương hiệu' : 'Thêm thương hiệu'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên thương hiệu *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: webController,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('Hoạt động')),
                        DropdownMenuItem(value: 'INACTIVE', child: Text('Ngừng hoạt động')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => status = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập tên thương hiệu')),
                      );
                      return;
                    }

                    final payload = {
                      'name': nameController.text.trim(),
                      'description': descController.text.trim(),
                      'website': webController.text.trim(),
                      'status': status,
                    };

                    bool success;
                    if (isEditing) {
                      success = await ref.read(brandListViewModelProvider.notifier)
                          .updateBrand(brand.id, payload);
                    } else {
                      success = await ref.read(brandListViewModelProvider.notifier)
                          .createBrand(payload);
                    }

                    if (success) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEditing ? 'Đã cập nhật thương hiệu' : 'Đã thêm thương hiệu')),
                      );
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDelete(BrandModel brand) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa thương hiệu "${brand.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref.read(brandListViewModelProvider.notifier)
                    .deleteBrand(brand.id);
                if (success) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa thương hiệu')),
                  );
                }
              },
              child: Text('Xóa', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(brandListViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Thương hiệu'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBrandDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thương hiệu...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _buildBody(state, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BrandListState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.brands.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Đã xảy ra lỗi: ${state.error}', style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(brandListViewModelProvider.notifier).refresh(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state.brands.isEmpty) {
      return const Center(child: Text('Không tìm thấy thương hiệu nào.'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(brandListViewModelProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: state.brands.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.brands.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final brand = state.brands[index];
          final isActive = brand.status == 'ACTIVE';

          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: ListTile(
              title: Text(brand.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand.website != null && brand.website!.isNotEmpty)
                    Text(brand.website!, style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
                  if (brand.description.isNotEmpty)
                    Text(brand.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive 
                          ? Colors.green.withValues(alpha: 0.1) 
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isActive ? 'Hoạt động' : 'Ngừng',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showBrandDialog(brand);
                      } else if (value == 'delete') {
                        _confirmDelete(brand);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                      const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
