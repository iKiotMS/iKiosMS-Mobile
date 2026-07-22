// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/viewmodels/user_profile_provider.dart';
import '../../leave/leave_view.dart';
import '../../payroll/payroll_view.dart';
import '../../cashflow/views/cash_flow_view.dart';
import '../../imports/views/import_list_view.dart';
import '../../leave_approval/views/leave_approval_view.dart';
import '../../location_settings/views/location_settings_view.dart';
import '../../promotion/views/promotion_list_view.dart';
import '../../schedule/views/schedule_view.dart';
import '../../staff/views/staff_list_view.dart';
import '../../stock_adjustment/views/adjustment_list_view.dart';
import '../../transfers/views/transfers_list_view.dart';
import '../../product/views/product_list_view.dart';
import '../../product/views/category_list_view.dart';
import '../../product/views/brand_list_view.dart';
import '../../checkout/views/checkout_view.dart';
import '../../order/views/order_list_view.dart';
import 'feature_placeholder_view.dart';

class WorkView extends ConsumerWidget {
  const WorkView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Công việc'), centerTitle: true),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Không tìm thấy thông tin nhân viên.'),
            );
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
                    shape: const Border(),
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    initiallyExpanded: true,
                    children: group.items.map((item) {
                      if (item.subItems != null && item.subItems!.isNotEmpty) {
                        return ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                          ),
                          leading: Icon(
                            item.icon,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          title: Text(item.title),
                          shape: const Border(),
                          children: item.subItems!.map((subItem) {
                            return ListTile(
                              contentPadding: const EdgeInsets.only(
                                left: 48.0,
                                right: 24.0,
                              ),
                              title: Text(
                                subItem.title,
                                style: theme.textTheme.bodyMedium,
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => subItem.builder(),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        leading: Icon(
                          item.icon,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(item.title),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                        ),
                        onTap: () {
                          if (item.builder != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => item.builder!(),
                              ),
                            );
                          }
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
        error: (err, stack) =>
            Center(child: Text('Lỗi tải danh mục công việc: $err')),
      ),
    );
  }

  List<WorkGroup> _getGroupsForRole(String role) {
    // --- Reusable Sidebar Items matching sidebar-items.ts ---

    // Quản lý Items
    final tongQuanItem = WorkItem(
      title: 'Tổng quan',
      icon: Icons.dashboard_outlined,
      builder: () => const FeaturePlaceholderView(title: 'Tổng quan'),
    );

    final soThuChiItem = WorkItem(
      title: 'Sổ thu chi',
      icon: Icons.account_balance_wallet_outlined,
      builder: () => const CashFlowView(),
    );

    // HR mobile hiện chỉ scope chi nhánh (BRANCH_MANAGER).
    final nhanVienBranchItem = WorkItem(
      title: 'Nhân viên',
      icon: Icons.people_outline_rounded,
      subItems: [
        WorkSubItem(title: 'Danh sách', builder: () => const StaffListView()),
        WorkSubItem(title: 'Lịch làm', builder: () => const ScheduleView()),
        WorkSubItem(
          title: 'Nghỉ phép',
          builder: () => const LeaveApprovalView(),
        ),
      ],
    );

    final nhanVienItem = WorkItem(
      title: 'Nhân viên',
      icon: Icons.people_outline_rounded,
      subItems: [
        WorkSubItem(
          title: 'Danh sách',
          builder: () =>
              const FeaturePlaceholderView(title: 'Danh sách nhân viên'),
        ),
        WorkSubItem(title: 'Lịch làm', builder: () => const ScheduleView()),
        WorkSubItem(
          title: 'Duyệt nghỉ',
          builder: () => const FeaturePlaceholderView(title: 'Duyệt nghỉ'),
        ),
        WorkSubItem(title: 'Nghỉ phép', builder: () => const LeaveView()),
        WorkSubItem(
          title: 'Ngày lễ',
          builder: () => const FeaturePlaceholderView(title: 'Ngày lễ'),
        ),
      ],
    );

    final luongItem = WorkItem(
      title: 'Lương của tôi',
      icon: Icons.payments_outlined,
      builder: () => const PayrollView(),
    );

    final chamCongItem = WorkItem(
      title: 'Chấm công',
      icon: Icons.fingerprint_rounded,
      builder: () => const ScheduleView(),
    );

    // Quản lý bán hàng Items
    final hangHoaItem = WorkItem(
      title: 'Hàng hóa',
      icon: Icons.inventory_2_outlined,
      subItems: [
        WorkSubItem(
          title: 'Danh sách',
          builder: () => const ProductListView(),
        ),
        WorkSubItem(
          title: 'Danh mục',
          builder: () => const CategoryListView(),
        ),
        WorkSubItem(
          title: 'Thương hiệu',
          builder: () => const BrandListView(),
        ),
        WorkSubItem(
          title: 'Điều chỉnh chi nhánh, kho',
          builder: () => const LocationSettingsView(),
        ),
      ],
    );

    final giaoDichItem = WorkItem(
      title: 'Giao dịch',
      icon: Icons.swap_horiz_rounded,
      subItems: [
        WorkSubItem(
          title: 'Nhà cung cấp',
          builder: () => const FeaturePlaceholderView(title: 'Nhà cung cấp'),
        ),
        WorkSubItem(
          title: 'Nhập hàng',
          builder: () => const ImportListView(),
        ),
        WorkSubItem(
          title: 'Chuyển kho',
          builder: () => const TransfersListView(),
        ),
        WorkSubItem(
          title: 'Điều chỉnh tồn kho',
          builder: () => const AdjustmentListView(),
        ),
      ],
    );

    final giaoDichBranchItem = WorkItem(
      title: 'Giao dịch',
      icon: Icons.swap_horiz_rounded,
      subItems: [
        WorkSubItem(
          title: 'Nhà cung cấp',
          builder: () => const FeaturePlaceholderView(title: 'Nhà cung cấp'),
        ),
        WorkSubItem(
          title: 'Chuyển hàng',
          builder: () => const TransfersListView(),
        ),
        WorkSubItem(
          title: 'Điều chỉnh tồn kho',
          builder: () => const AdjustmentListView(),
        ),
      ],
    );

    final donHangItem = WorkItem(
      title: 'Đơn hàng',
      icon: Icons.shopping_cart_outlined,
      subItems: [
        WorkSubItem(
          title: 'Bán hàng',
          builder: () => const CheckoutView(),
        ),
        WorkSubItem(
          title: 'Hoá đơn',
          builder: () => const OrderListView(),
        ),
      ],
    );

    final ketTienItem = WorkItem(
      title: 'Két tiền',
      icon: Icons.savings_outlined,
      subItems: [
        WorkSubItem(
          title: 'Hôm nay',
          builder: () =>
              const FeaturePlaceholderView(title: 'Két tiền hôm nay'),
        ),
        WorkSubItem(
          title: 'Lịch sử',
          builder: () =>
              const FeaturePlaceholderView(title: 'Lịch sử két tiền'),
        ),
      ],
    );

    // CRM Items
    final khachHangItem = WorkItem(
      title: 'Khách hàng',
      icon: Icons.person_search_outlined,
      builder: () => const FeaturePlaceholderView(title: 'Khách hàng'),
    );

    final khuyenMaiItem = WorkItem(
      title: 'Khuyến mãi',
      icon: Icons.local_offer_outlined,
      builder: () => const PromotionListView(),
    );

    // SUPER_ADMIN Items
    final adminDashboardItem = WorkItem(
      title: 'Dashboard',
      icon: Icons.space_dashboard_outlined,
      builder: () => const FeaturePlaceholderView(title: 'Admin Dashboard'),
    );
    final adminSystemNotificationsItem = WorkItem(
      title: 'Thông báo',
      icon: Icons.notifications_outlined,
      builder: () => const FeaturePlaceholderView(title: 'Thông báo hệ thống'),
    );
    final adminUsersItem = WorkItem(
      title: 'Người dùng',
      icon: Icons.manage_accounts_outlined,
      builder: () => const FeaturePlaceholderView(title: 'Quản lý người dùng'),
    );
    final subscriptionsItem = WorkItem(
      title: 'Subscription',
      icon: Icons.card_membership_outlined,
      builder: () =>
          const FeaturePlaceholderView(title: 'Quản lý Subscription'),
    );
    final adminSepayItem = WorkItem(
      title: 'Liên kết SePay',
      icon: Icons.account_balance_outlined,
      builder: () => const FeaturePlaceholderView(title: 'Liên kết SePay'),
    );
    final adminGiaoDichItem = WorkItem(
      title: 'Giao dịch',
      icon: Icons.swap_horiz_rounded,
      builder: () => const FeaturePlaceholderView(title: 'Giao dịch hệ thống'),
    );
    final adminAuditLogItem = WorkItem(
      title: 'Nhật ký hệ thống',
      icon: Icons.security_outlined,
      builder: () => const FeaturePlaceholderView(title: 'Nhật ký hệ thống'),
    );
    final adminNotificationsItem = WorkItem(
      title: 'Gửi thông báo',
      icon: Icons.campaign_outlined,
      builder: () => const FeaturePlaceholderView(title: 'Gửi thông báo'),
    );
    final adminTicketsItem = WorkItem(
      title: 'Hỗ trợ kỹ thuật',
      icon: Icons.support_agent_outlined,
      builder: () => const FeaturePlaceholderView(title: 'Hỗ trợ kỹ thuật'),
    );
    final cauHinhHeThongItem = WorkItem(
      title: 'Cấu hình hệ thống',
      icon: Icons.settings_outlined,
      builder: () => const FeaturePlaceholderView(title: 'Cấu hình hệ thống'),
    );

    // --- Common Group Reusers matching sidebar-role.ts ---

    final crmGroup = WorkGroup(
      title: 'CRM',
      icon: Icons.groups_outlined,
      items: [khachHangItem, khuyenMaiItem],
    );

    final salaryGroup = WorkGroup(
      title: 'Lương',
      icon: Icons.payments_outlined,
      items: [luongItem],
    );

    final attendanceGroup = WorkGroup(
      title: 'Chấm công',
      icon: Icons.fingerprint_rounded,
      items: [chamCongItem],
    );

    final staffEmployeeGroup = WorkGroup(
      title: 'Nhân viên',
      icon: Icons.people_outline_rounded,
      items: [
        WorkItem(
          title: 'Lịch làm',
          icon: Icons.calendar_month_outlined,
          builder: () => const ScheduleView(),
        ),
        WorkItem(
          title: 'Nghỉ phép',
          icon: Icons.event_busy_outlined,
          builder: () => const LeaveView(),
        ),
      ],
    );

    // --- Role-based Config matching sidebarRoleConfig in sidebar-role.ts ---

    if (role == 'SUPER_ADMIN') {
      return [
        WorkGroup(
          title: 'Quản lý',
          icon: Icons.admin_panel_settings_outlined,
          items: [
            adminDashboardItem,
            adminSystemNotificationsItem,
            adminUsersItem,
            subscriptionsItem,
            adminSepayItem,
            adminGiaoDichItem,
            adminAuditLogItem,
            adminNotificationsItem,
            adminTicketsItem,
          ],
        ),
        WorkGroup(
          title: 'Cài đặt',
          icon: Icons.settings_outlined,
          items: [cauHinhHeThongItem],
        ),
      ];
    } else if (role == 'TENANT_OWNER') {
      return [
        WorkGroup(
          title: 'Quản lý',
          icon: Icons.admin_panel_settings_outlined,
          items: [tongQuanItem, soThuChiItem, nhanVienItem],
        ),
        WorkGroup(
          title: 'Quản lý bán hàng',
          icon: Icons.store_outlined,
          items: [hangHoaItem, giaoDichItem, donHangItem, ketTienItem],
        ),
        crmGroup,
      ];
    } else if (role == 'BRANCH_MANAGER') {
      return [
        attendanceGroup,
        WorkGroup(
          title: 'Quản lý',
          icon: Icons.admin_panel_settings_outlined,
          items: [tongQuanItem, soThuChiItem, nhanVienBranchItem],
        ),
        WorkGroup(
          title: 'Quản lý bán hàng',
          icon: Icons.store_outlined,
          items: [hangHoaItem, giaoDichBranchItem, donHangItem, ketTienItem],
        ),
        crmGroup,
        salaryGroup,
      ];
    } else if (role == 'WAREHOUSE_MANAGER') {
      return [
        attendanceGroup,
        WorkGroup(
          title: 'Quản lý',
          icon: Icons.admin_panel_settings_outlined,
          items: [nhanVienItem],
        ),
        WorkGroup(
          title: 'Quản lý bán hàng',
          icon: Icons.store_outlined,
          items: [hangHoaItem, giaoDichItem],
        ),
        salaryGroup,
      ];
    } else if (role == 'STAFF') {
      return [
        attendanceGroup,
        staffEmployeeGroup,
        WorkGroup(
          title: 'Quản lý bán hàng',
          icon: Icons.store_outlined,
          items: [hangHoaItem, donHangItem, ketTienItem],
        ),
        crmGroup,
        salaryGroup,
      ];
    } else {
      return [];
    }
  }
}

class WorkSubItem {
  final String title;
  final Widget Function() builder;

  const WorkSubItem({required this.title, required this.builder});
}

class WorkItem {
  final String title;
  final IconData icon;
  final Widget Function()? builder;
  final List<WorkSubItem>? subItems;

  const WorkItem({
    required this.title,
    required this.icon,
    this.builder,
    this.subItems,
  });
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
