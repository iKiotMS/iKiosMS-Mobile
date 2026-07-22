import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/shift_model.dart';
import '../viewmodels/schedule_view_model.dart';
import '../widgets/schedule_empty_state.dart';
import '../widgets/shift_card.dart';
import '../widgets/week_selector_bar.dart';
import 'shift_detail_view.dart';

/// The main schedule screen — shows the employee's shifts for the selected week.
///
/// Uses [ScheduleViewModel] to load and manage shift data.
class ScheduleView extends ConsumerWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleViewModelProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          // Pull-to-refresh reloads shifts for the currently selected week.
          onRefresh: () =>
              ref.read(scheduleViewModelProvider.notifier).loadShifts(),
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    Navigator.of(context).canPop() ? 8 : 20,
                    16,
                    0,
                  ),
                  child: _GreetingHeader(now: now),
                ),
              ),

              // ── Week Selector ────────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: WeekSelectorBar(),
                ),
              ),

              // ── Current / Next Shift Summary ─────────────────────────────
              if (!state.isLoading && state.errorMessage == null)
                SliverToBoxAdapter(child: _ShiftSummarySection(state: state)),

              // ── Loading ──────────────────────────────────────────────────
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Đang tải lịch làm...'),
                      ],
                    ),
                  ),
                ),

              // ── Error ────────────────────────────────────────────────────
              if (!state.isLoading && state.errorMessage != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => ref
                                .read(scheduleViewModelProvider.notifier)
                                .loadShifts(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Empty state ──────────────────────────────────────────────
              if (!state.isLoading &&
                  state.errorMessage == null &&
                  state.shifts.isEmpty)
                const SliverFillRemaining(child: ScheduleEmptyState()),

              // ── Shift list ───────────────────────────────────────────────
              if (!state.isLoading &&
                  state.errorMessage == null &&
                  state.shifts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'Ca làm trong tuần',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final shift = state.shifts[index];
                    return ShiftCard(
                      shift: shift,
                      onTap: () => _openDetail(context, ref, shift),
                    );
                  }, childCount: state.shifts.length),
                ),
                // Bottom padding so last card isn't hidden by nav bar
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    ShiftModel shift,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShiftDetailView(shiftId: shift.id)),
    );
    if (!context.mounted) return;
    await ref.read(scheduleViewModelProvider.notifier).loadShifts();
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// Greeting header with employee's name placeholder and today's date.
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final weekday = DateTimeUtils.viWeekdayShort(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xin chào! 👋',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '$weekday, $d/$m/${now.year}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Shows the current and/or next shift as a small summary card row.
class _ShiftSummarySection extends StatelessWidget {
  const _ShiftSummarySection({required this.state});

  final ScheduleState state;

  @override
  Widget build(BuildContext context) {
    final current = state.currentShift;
    final next = state.nextShift;

    if (current == null && next == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          if (current != null)
            Expanded(
              child: _SummaryCard(
                label: 'Ca hiện tại',
                shift: current,
                highlight: true,
              ),
            ),
          if (current != null && next != null) const SizedBox(width: 10),
          if (next != null)
            Expanded(
              child: _SummaryCard(label: 'Ca tiếp theo', shift: next),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.shift,
    this.highlight = false,
  });

  final String label;
  final ShiftModel shift;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: highlight
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: highlight
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateTimeUtils.formatTimeRange(shift.startTime, shift.endTime),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateTimeUtils.formatShortDate(shift.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: highlight
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              shift.role,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: highlight
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                    : colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
