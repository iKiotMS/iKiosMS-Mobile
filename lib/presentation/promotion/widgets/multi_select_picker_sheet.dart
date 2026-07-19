import 'package:flutter/material.dart';

/// One selectable entry in a [MultiSelectPickerSheet] — id + display label.
class PickerOption {
  final String id;
  final String label;

  const PickerOption({required this.id, required this.label});
}

/// Generic bottom sheet for picking multiple items from a flat option list
/// (branches, categories, or product items in the promotion form). Search
/// filters client-side since option lists here are small (≤~200 items).
class MultiSelectPickerSheet extends StatefulWidget {
  final String title;
  final List<PickerOption> options;
  final Set<String> initialSelectedIds;

  const MultiSelectPickerSheet({
    super.key,
    required this.title,
    required this.options,
    required this.initialSelectedIds,
  });

  static Future<Set<String>?> show({
    required BuildContext context,
    required String title,
    required List<PickerOption> options,
    required Set<String> initialSelectedIds,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiSelectPickerSheet(
        title: title,
        options: options,
        initialSelectedIds: initialSelectedIds,
      ),
    );
  }

  @override
  State<MultiSelectPickerSheet> createState() => _MultiSelectPickerSheetState();
}

class _MultiSelectPickerSheetState extends State<MultiSelectPickerSheet> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelectedIds};
  }

  List<PickerOption> get _filtered {
    if (_query.isEmpty) return widget.options;
    final query = _query.toLowerCase();
    return widget.options.where((o) => o.label.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: _selected.isEmpty ? null : () => setState(() => _selected.clear()),
                      child: const Text('Bỏ chọn hết'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm...',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text('Không có mục nào', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final option = _filtered[index];
                          final checked = _selected.contains(option.id);
                          return CheckboxListTile(
                            value: checked,
                            title: Text(option.label),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setState(() {
                                if (value ?? false) {
                                  _selected.add(option.id);
                                } else {
                                  _selected.remove(option.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      child: Text('Xong (${_selected.length} đã chọn)'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
