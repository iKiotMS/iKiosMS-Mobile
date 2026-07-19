// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/viewmodels/user_profile_provider.dart';
import '../../location_settings/views/location_settings_view.dart';
import '../../schedule/views/schedule_view.dart';
import '../../stock_adjustment/views/adjustment_list_view.dart';
import '../../stock_movement_history/views/stock_movement_history_view.dart';
import 'feature_placeholder_view.dart';

class WorkView extends ConsumerWidget {
  const WorkView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Công việc'),
        centerTitle: true,
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Không tìm thấy thông tin nhân viên.'));
          }

          final role = profile.role;
          final groups = _getGroupsForRole(role);

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                  child: ExpansionTile(
                    leading: Icon(group.icon, color: theme.colorScheme.primary),
                    title: Text(
                      group.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    shape: const Border(), // Removes bottom/top borders when expanded
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    initiallyExpanded: true,
                    children: group.items.map((item) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
                        leading: Icon(item.icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        title: Text(item.name),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => item.builder(),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Lỗi tải danh mục công việc: $err'),
        ),
      ),
    );
  }

  List<WorkGroup> _getGroupsForRole(String role) {
    final manageGroup = WorkGroup(
      title: 'Quản lý',
      icon: Icons.admin_panel_settings_outlined,
      items: [
        WorkItem(
          name: 'Nhân viên',
          icon: Icons.people_outline_rounded,
          builder: () => const FeaturePlaceholderView(title: 'Quản lý nhân viên'),
        ),
        WorkItem(
          name: 'Ca làm',
          icon: Icons.access_time_rounded,
          builder: () => const FeaturePlaceholderView(title: 'Quản lý ca làm'),
        ),
        WorkItem(
          name: 'Duyệt nghỉ',
          icon: Icons.event_busy_rounded,
          builder: () => const FeaturePlaceholderView(title: 'Duyệt nghỉ'),
        ),
      ],
    );

    final warehouseGroup = WorkGroup(
      title: 'Kho',
      icon: Icons.warehouse_outlined,
      items: [
        WorkItem(
          name: 'Điều chỉnh tồn kho',
          icon: Icons.fact_check_outlined,
          builder: () => const AdjustmentListView(),
        ),
        WorkItem(
          name: 'Lịch sử nhập/xuất kho',
          icon: Icons.receipt_long_outlined,
          builder: () => const StockMovementHistoryView(),
        ),
        WorkItem(
          name: 'Danh sách sản phẩm',
          icon: Icons.list_alt_rounded,
          builder: () => const FeaturePlaceholderView(title: 'Danh sách sản phẩm'),
        ),
        WorkItem(
          name: 'Xác nhận nhập',
          icon: Icons.input_rounded,
          builder: () => const FeaturePlaceholderView(title: 'Xác nhận nhập kho'),
        ),
        WorkItem(
          name: 'Xác nhận xuất',
          icon: Icons.output_rounded,
          builder: () => const FeaturePlaceholderView(title: 'Xác nhận xuất kho'),
        ),
        WorkItem(
          name: 'Điều chỉnh chi nhánh, kho',
          icon: Icons.settings_outlined,
          builder: () => const LocationSettingsView(),
        ),
      ],
    );

    final salesGroup = WorkGroup(
      title: 'Bán hàng',
      icon: Icons.point_of_sale_rounded,
      items: [
        WorkItem(
          name: 'Tạo đơn',
          icon: Icons.add_shopping_cart_rounded,
          builder: () => const FeaturePlaceholderView(title: 'Tạo đơn bán hàng'),
        ),
      ],
    );

    final ordersGroup = WorkGroup(
      title: 'Đơn hàng',
      icon: Icons.shopping_bag_outlined,
      items: [
        WorkItem(
          name: 'Tạo Order',
          icon: Icons.add_circle_outline_rounded,
          builder: () => const FeaturePlaceholderView(title: 'Tạo Order'),
        ),
        WorkItem(
          name: 'Hoá đơn',
          icon: Icons.receipt_rounded,
          builder: () => const FeaturePlaceholderView(title: 'Hóa đơn'),
        ),
      ],
    );

    final goodsGroup = WorkGroup(
      title: 'Hàng hóa',
      icon: Icons.category_outlined,
      items: [
        WorkItem(
          name: 'Danh sách hàng hóa',
          icon: Icons.list_rounded,
          builder: () => const FeaturePlaceholderView(title: 'Danh sách hàng hóa'),
        ),
      ],
    );

    final workGroup = WorkGroup(
      title: 'Làm việc',
      icon: Icons.work_outline_rounded,
      items: [
        WorkItem(
          name: 'Check-in',
          icon: Icons.location_on_outlined,
          builder: () => const FeaturePlaceholderView(title: 'Check-in chấm công'),
        ),
        WorkItem(
          name: 'Lịch làm',
          icon: Icons.calendar_month_outlined,
          builder: () => const ScheduleView(),
        ),
      ],
    );

    if (role == 'TENANT_OWNER') {
      return [
        manageGroup,
        warehouseGroup,
        salesGroup,
        ordersGroup,
        goodsGroup,
        workGroup,
      ];
    } else if (role == 'BRANCH_MANAGER') {
      return [
        manageGroup,
        warehouseGroup,
        salesGroup,
      ];
    } else if (role == 'WAREHOUSE_MANAGER') {
      return [
        warehouseGroup,
      ];
    } else if (role == 'STAFF') {
      return [
        ordersGroup,
        goodsGroup,
        workGroup,
      ];
    } else {
      return [workGroup];
    }
  }
}

class WorkGroup {
  final String title;
  final IconData icon;
  final List<WorkItem> items;

  const WorkGroup({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class WorkItem {
  final String name;
  final IconData icon;
  final Widget Function() builder;

  const WorkItem({
    required this.name,
    required this.icon,
    required this.builder,
  });
}
