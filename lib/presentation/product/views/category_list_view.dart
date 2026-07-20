import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/category_model.dart';
import '../viewmodels/category_list_view_model.dart';

class CategoryListView extends ConsumerStatefulWidget {
  const CategoryListView({super.key});

  @override
  ConsumerState<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends ConsumerState<CategoryListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryListViewModelProvider.notifier).fetchCategories(isRefresh: true);
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
      ref.read(categoryListViewModelProvider.notifier).fetchCategories();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(categoryListViewModelProvider.notifier).search(query);
    });
  }

  void _showCategoryDialog([CategoryModel? category]) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    String status = category?.status ?? 'ACTIVE';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Sửa danh mục' : 'Thêm danh mục'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên danh mục *',
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
                        const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
                      );
                      return;
                    }

                    final payload = {
                      'name': nameController.text.trim(),
                      'description': descController.text.trim(),
                      'status': status,
                    };

                    bool success;
                    if (isEditing) {
                      success = await ref.read(categoryListViewModelProvider.notifier)
                          .updateCategory(category.id, payload);
                    } else {
                      success = await ref.read(categoryListViewModelProvider.notifier)
                          .createCategory(payload);
                    }

                    if (success) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEditing ? 'Đã cập nhật danh mục' : 'Đã thêm danh mục')),
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

  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa danh mục "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref.read(categoryListViewModelProvider.notifier)
                    .deleteCategory(category.id);
                if (success) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa danh mục')),
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
    final state = ref.watch(categoryListViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Danh mục'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm danh mục...',
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

  Widget _buildBody(CategoryListState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Đã xảy ra lỗi: ${state.error}', style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(categoryListViewModelProvider.notifier).refresh(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state.categories.isEmpty) {
      return const Center(child: Text('Không tìm thấy danh mục nào.'));
    }

    final parentCategories = state.categories.where((c) => c.parentId == null || c.parentId!.isEmpty).toList();
    final childCategories = state.categories.where((c) => c.parentId != null && c.parentId!.isNotEmpty).toList();

    final Map<String, List<CategoryModel>> childrenMap = {};
    for (final child in childCategories) {
      childrenMap.putIfAbsent(child.parentId!, () => []).add(child);
    }

    final List<CategoryModel> sortedCategories = [];
    for (final parent in parentCategories) {
      sortedCategories.add(parent);
      if (childrenMap.containsKey(parent.id)) {
        sortedCategories.addAll(childrenMap[parent.id]!);
      }
    }
    
    final Set<String> sortedIds = sortedCategories.map((c) => c.id).toSet();
    final orphaned = state.categories.where((c) => !sortedIds.contains(c.id)).toList();
    sortedCategories.addAll(orphaned);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(categoryListViewModelProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: sortedCategories.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == sortedCategories.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final category = sortedCategories[index];
          final isActive = category.status == 'ACTIVE';
          final isSubcategory = category.parentId != null && category.parentId!.isNotEmpty;

          return Card(
            margin: EdgeInsets.only(
              bottom: 8.0,
              left: isSubcategory ? 32.0 : 0.0,
            ),
            elevation: isSubcategory ? 0 : 1,
            color: isSubcategory ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSubcategory 
                    ? Colors.transparent 
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.5)
              ),
            ),
            child: ListTile(
              leading: isSubcategory 
                  ? Icon(Icons.subdirectory_arrow_right, color: theme.colorScheme.primary, size: 20)
                  : Icon(Icons.folder_outlined, color: theme.colorScheme.primary),
              title: Text(category.name, style: TextStyle(fontWeight: isSubcategory ? FontWeight.normal : FontWeight.bold)),
              subtitle: category.description.isNotEmpty 
                ? Text(category.description, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
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
                        _showCategoryDialog(category);
                      } else if (value == 'delete') {
                        _confirmDelete(category);
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
