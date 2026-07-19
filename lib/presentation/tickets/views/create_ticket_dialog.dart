import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/tickets_view_model.dart';

class CreateTicketDialog extends ConsumerStatefulWidget {
  const CreateTicketDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const CreateTicketDialog(),
    );
  }

  @override
  ConsumerState<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends ConsumerState<CreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedPriority = 'MEDIUM';
  bool _isSubmitting = false;

  final Map<String, String> _priorityOptions = const {
    'LOW': 'Thấp — Vấn đề không nghiêm trọng',
    'MEDIUM': 'Trung bình — Cần hỗ trợ sớm',
    'HIGH': 'Cao — Ảnh hưởng kinh doanh',
    'URGENT': 'Khẩn cấp — Hệ thống gián đoạn',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(ticketsViewModelProvider.notifier).createTicket(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            priority: _selectedPriority,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi phản ánh thành công! Đội ngũ hỗ trợ sẽ phản hồi sớm.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi phản ánh thất bại: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.confirmation_number_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Tạo phản ánh mới',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // Title
                TextFormField(
                  controller: _titleController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề vấn đề *',
                    hintText: 'Ví dụ: Không thể đồng bộ sản phẩm...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 5) {
                      return 'Tiêu đề phải có ít nhất 5 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Priority Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Mức độ ưu tiên *',
                    border: OutlineInputBorder(),
                  ),
                  items: _priorityOptions.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedPriority = val);
                          }
                        },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isSubmitting,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả chi tiết *',
                    hintText: 'Mô tả rõ vấn đề bạn gặp phải, các bước tái hiện lỗi...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 10) {
                      return 'Mô tả phải có ít nhất 10 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSubmitting ? 'Đang gửi...' : 'Gửi phản ánh'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
