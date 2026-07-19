import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/location_settings_model.dart';
import '../viewmodels/location_settings_view_model.dart';

/// "Setting chi nhánh, kho" — view/edit the caller's own branch
/// (BRANCH_MANAGER) or warehouse (WAREHOUSE_MANAGER) settings.
///
/// Fields mirror exactly what the web app's `/settings` edit form exposes
/// for each location type: branch = name/phone/address, warehouse =
/// name/address only (no phone field exists on the Warehouse model).
class LocationSettingsView extends ConsumerWidget {
  const LocationSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationSettingsViewModelProvider);
    final notifier = ref.read(locationSettingsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.settings?.locationType == 'warehouse' ? 'Cài đặt kho' : 'Cài đặt chi nhánh'),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.settings == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.notApplicable) {
            return _MessageState(
              icon: Icons.info_outline_rounded,
              message: 'Tài khoản của bạn không quản lý riêng một chi nhánh hoặc kho cụ thể.',
            );
          }
          if (state.errorMessage != null && state.settings == null) {
            return _MessageState(
              icon: Icons.error_outline_rounded,
              message: state.errorMessage!,
              onRetry: notifier.refetch,
            );
          }
          if (state.settings == null) return const SizedBox.shrink();

          return _SettingsForm(settings: state.settings!, isSaving: state.isSaving);
        },
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _MessageState({required this.icon, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  final LocationSettingsModel settings;
  final bool isSaving;

  const _SettingsForm({required this.settings, required this.isSaving});

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.settings.name);
    _phoneController = TextEditingController(text: widget.settings.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.settings.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(locationSettingsViewModelProvider.notifier);
    final error = await notifier.save(
      name: _nameController.text.trim(),
      phoneNumber: widget.settings.locationType == 'branch' && _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Đã lưu thay đổi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBranch = widget.settings.locationType == 'branch';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: widget.settings.status == 'ACTIVE' ? Colors.green : Colors.grey),
                const SizedBox(width: 6),
                Text(
                  locationStatusLabels[widget.settings.status] ?? widget.settings.status,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: isBranch ? 'Tên chi nhánh' : 'Tên kho',
              border: const OutlineInputBorder(),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? (isBranch ? 'Tên chi nhánh không được để trống' : 'Tên kho không được để trống')
                : null,
          ),
          if (isBranch) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: widget.isSaving ? null : _onSave,
            child: widget.isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }
}
