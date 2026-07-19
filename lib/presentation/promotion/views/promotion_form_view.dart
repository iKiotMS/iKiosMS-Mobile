import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/promotion_model.dart';
import '../../../data/repositories/category_option/category_option_repository_provider.dart';
import '../../../data/repositories/location_option/location_option_repository_provider.dart';
import '../../../data/repositories/product_item_option/product_item_option_repository_provider.dart';
import '../viewmodels/promotion_form_view_model.dart';
import '../widgets/multi_select_picker_sheet.dart';

/// Create/edit form for a promotion — `initial == null` means create,
/// otherwise edit (pre-filled). Mirrors the web's `promotions-mutate-dialog.tsx`
/// field set and validation, using native Flutter `Form` + controllers
/// (this app has no form library) since there are many cross-validated
/// fields (percent-only max discount, date range, conditional pickers).
class PromotionFormView extends ConsumerStatefulWidget {
  final PromotionModel? initial;

  const PromotionFormView({super.key, this.initial});

  @override
  ConsumerState<PromotionFormView> createState() => _PromotionFormViewState();
}

class _PromotionFormViewState extends ConsumerState<PromotionFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _promoNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _maxDiscountController;
  late final TextEditingController _minOrderValueController;
  late final TextEditingController _priorityController;
  late final TextEditingController _usageLimitController;
  late final TextEditingController _usageLimitPerCustomerController;

  late String _discountType;
  late bool _isBranchWide;
  late Set<String> _selectedBranchIds;
  late String _applicableRuleType;
  late Set<String> _selectedCategoryIds;
  late Set<String> _selectedProductItemIds;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _stackable;
  late String _status;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _promoNameController = TextEditingController(text: p?.promoName ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _discountValueController = TextEditingController(text: p != null ? _trimNum(p.discountValue) : '');
    _maxDiscountController = TextEditingController(text: p?.maxDiscountAmount != null ? _trimNum(p!.maxDiscountAmount!) : '');
    _minOrderValueController = TextEditingController(text: _trimNum(p?.minOrderValue ?? 0));
    _priorityController = TextEditingController(text: '${p?.priority ?? 0}');
    _usageLimitController = TextEditingController(text: p?.usageLimit != null ? '${p!.usageLimit}' : '');
    _usageLimitPerCustomerController = TextEditingController(text: p?.usageLimitPerCustomer != null ? '${p!.usageLimitPerCustomer}' : '');

    _discountType = p?.discountType ?? 'PERCENT';
    _isBranchWide = p?.isBranchWide ?? true;
    _selectedBranchIds = {...(p?.branchIds ?? const [])};
    _applicableRuleType = (p?.applicableRule.type == 'product') ? 'product' : 'category';
    _selectedCategoryIds = {...(p?.applicableRule.categoryIds ?? const [])};
    _selectedProductItemIds = {...(p?.applicableRule.productItemIds ?? const [])};
    _startDate = p?.startDate ?? DateTime.now();
    _endDate = p?.endDate ?? DateTime.now().add(const Duration(days: 7));
    _stackable = p?.stackable ?? false;
    _status = p?.status ?? 'ACTIVE';
  }

  String _trimNum(num value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  @override
  void dispose() {
    _promoNameController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _maxDiscountController.dispose();
    _minOrderValueController.dispose();
    _priorityController.dispose();
    _usageLimitController.dispose();
    _usageLimitPerCustomerController.dispose();
    super.dispose();
  }

  Future<void> _pickBranches() async {
    try {
      final options = await ref.read(locationOptionRepositoryProvider).getBranchOptions();
      if (!mounted) return;
      final result = await MultiSelectPickerSheet.show(
        context: context,
        title: 'Chọn chi nhánh áp dụng',
        options: options.map((o) => PickerOption(id: o.id, label: o.name)).toList(),
        initialSelectedIds: _selectedBranchIds,
      );
      if (result != null && mounted) setState(() => _selectedBranchIds = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tải được danh sách chi nhánh')));
      }
    }
  }

  Future<void> _pickCategories() async {
    try {
      final options = await ref.read(categoryOptionRepositoryProvider).getCategoryOptions();
      if (!mounted) return;
      final result = await MultiSelectPickerSheet.show(
        context: context,
        title: 'Chọn danh mục áp dụng',
        options: options.map((o) => PickerOption(id: o.id, label: o.name)).toList(),
        initialSelectedIds: _selectedCategoryIds,
      );
      if (result != null && mounted) setState(() => _selectedCategoryIds = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tải được danh sách danh mục')));
      }
    }
  }

  Future<void> _pickProductItems() async {
    try {
      final options = await ref.read(productItemOptionRepositoryProvider).getProductItemOptions();
      if (!mounted) return;
      final result = await MultiSelectPickerSheet.show(
        context: context,
        title: 'Chọn sản phẩm áp dụng',
        options: options.map((o) => PickerOption(id: o.id, label: '${o.productName} (${o.sku})')).toList(),
        initialSelectedIds: _selectedProductItemIds,
      );
      if (result != null && mounted) setState(() => _selectedProductItemIds = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tải được danh sách sản phẩm')));
      }
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Ngày bắt đầu' : 'Ngày kết thúc',
      cancelText: 'Huỷ',
      confirmText: 'Chọn',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_endDate.isAfter(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu')));
      return;
    }
    if (!_isBranchWide && _selectedBranchIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất 1 chi nhánh')));
      return;
    }
    if (_applicableRuleType == 'category' && _selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất 1 danh mục')));
      return;
    }
    if (_applicableRuleType == 'product' && _selectedProductItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất 1 sản phẩm')));
      return;
    }

    final payload = PromotionFormPayload(
      branchIds: _isBranchWide ? const [] : _selectedBranchIds.toList(),
      promoName: _promoNameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      discountType: _discountType,
      discountValue: num.parse(_discountValueController.text.trim()),
      maxDiscountAmount: _maxDiscountController.text.trim().isEmpty ? null : num.parse(_maxDiscountController.text.trim()),
      minOrderValue: _minOrderValueController.text.trim().isEmpty ? 0 : num.parse(_minOrderValueController.text.trim()),
      applicableRule: ApplicableRule(
        type: _applicableRuleType,
        categoryIds: _applicableRuleType == 'category' ? _selectedCategoryIds.toList() : const [],
        productItemIds: _applicableRuleType == 'product' ? _selectedProductItemIds.toList() : const [],
      ),
      startDate: _startDate,
      endDate: _endDate,
      priority: int.tryParse(_priorityController.text.trim()) ?? 0,
      stackable: _stackable,
      usageLimit: _usageLimitController.text.trim().isEmpty ? null : int.parse(_usageLimitController.text.trim()),
      usageLimitPerCustomer: _usageLimitPerCustomerController.text.trim().isEmpty ? null : int.parse(_usageLimitPerCustomerController.text.trim()),
      status: _isEdit ? _status : null,
    );

    final notifier = ref.read(promotionFormViewModelProvider.notifier);
    final success = _isEdit
        ? await notifier.update(widget.initial!.id, payload)
        : await notifier.create(payload);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEdit ? 'Cập nhật khuyến mãi thành công' : 'Tạo khuyến mãi thành công')));
      Navigator.of(context).pop(true);
    } else {
      final error = ref.read(promotionFormViewModelProvider).errorMessage ?? 'Thao tác thất bại';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final state = ref.watch(promotionFormViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa khuyến mãi' : 'Thêm khuyến mãi'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _promoNameController,
              decoration: const InputDecoration(labelText: 'Tên khuyến mãi *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text('Chi nhánh áp dụng', style: theme.textTheme.labelLarge),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Toàn hệ thống'),
              value: _isBranchWide,
              onChanged: (v) => setState(() => _isBranchWide = v),
            ),
            if (!_isBranchWide) ...[
              OutlinedButton.icon(
                onPressed: _pickBranches,
                icon: const Icon(Icons.store_outlined),
                label: Text(_selectedBranchIds.isEmpty ? 'Chọn chi nhánh' : 'Đã chọn ${_selectedBranchIds.length} chi nhánh'),
              ),
            ],
            const Divider(height: 32),
            Text('Giảm giá', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _discountType,
              decoration: const InputDecoration(labelText: 'Loại giảm giá', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'PERCENT', child: Text('Giảm theo %')),
                DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Giảm số tiền cố định')),
              ],
              onChanged: (v) => setState(() => _discountType = v ?? 'PERCENT'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _discountValueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: _discountType == 'PERCENT' ? 'Mức giảm (%) *' : 'Mức giảm (VND) *', border: const OutlineInputBorder()),
              validator: (v) {
                final value = num.tryParse(v?.trim() ?? '');
                if (value == null || value <= 0) return 'Phải lớn hơn 0';
                if (_discountType == 'PERCENT' && value > 100) return 'Tối đa 100%';
                return null;
              },
            ),
            if (_discountType == 'PERCENT') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxDiscountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Giảm tối đa (VND, để trống nếu không giới hạn)', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final value = num.tryParse(v.trim());
                  if (value == null || value <= 0) return 'Phải lớn hơn 0';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _minOrderValueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Đơn tối thiểu (VND)', border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final value = num.tryParse(v.trim());
                if (value == null || value < 0) return 'Không hợp lệ';
                return null;
              },
            ),
            const Divider(height: 32),
            Text('Áp dụng cho', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _applicableRuleType,
              decoration: const InputDecoration(labelText: 'Phạm vi áp dụng', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'category', child: Text('Theo danh mục')),
                DropdownMenuItem(value: 'product', child: Text('Theo sản phẩm')),
              ],
              onChanged: (v) => setState(() => _applicableRuleType = v ?? 'category'),
            ),
            const SizedBox(height: 12),
            if (_applicableRuleType == 'category')
              OutlinedButton.icon(
                onPressed: _pickCategories,
                icon: const Icon(Icons.category_outlined),
                label: Text(_selectedCategoryIds.isEmpty ? 'Chọn danh mục' : 'Đã chọn ${_selectedCategoryIds.length} danh mục'),
              )
            else
              OutlinedButton.icon(
                onPressed: _pickProductItems,
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(_selectedProductItemIds.isEmpty ? 'Chọn sản phẩm' : 'Đã chọn ${_selectedProductItemIds.length} sản phẩm'),
              ),
            const Divider(height: 32),
            Text('Thời gian & giới hạn', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _DateField(label: 'Bắt đầu', date: _startDate, format: dateFormat, onTap: () => _pickDate(isStart: true))),
                const SizedBox(width: 12),
                Expanded(child: _DateField(label: 'Kết thúc', date: _endDate, format: dateFormat, onTap: () => _pickDate(isStart: false))),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priorityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Độ ưu tiên', border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final value = int.tryParse(v.trim());
                if (value == null || value < 0) return 'Không hợp lệ';
                return null;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cho phép cộng dồn'),
              value: _stackable,
              onChanged: (v) => setState(() => _stackable = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _usageLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giới hạn lượt dùng (để trống = không giới hạn)', border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final value = int.tryParse(v.trim());
                if (value == null || value < 1) return 'Phải ≥ 1';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usageLimitPerCustomerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giới hạn / khách hàng (để trống = không giới hạn)', border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final value = int.tryParse(v.trim());
                if (value == null || value < 1) return 'Phải ≥ 1';
                return null;
              },
            ),
            if (_isEdit) ...[
              const Divider(height: 32),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Đang chạy')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Đã tắt')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'ACTIVE'),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: state.isSubmitting ? null : _submit,
                child: state.isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Lưu thay đổi' : 'Tạo khuyến mãi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateFormat format;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.date, required this.format, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
        child: Text(format.format(date)),
      ),
    );
  }
}
