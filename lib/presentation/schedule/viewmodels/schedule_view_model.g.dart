// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scheduleViewModelHash() => r'e3d5ac64042998ed440fd47f94d1ce79163e44bd';

/// Riverpod-generated notifier for the schedule screen.
///
/// Holds the selected week and the list of shifts.
/// The view reads [state] and calls methods on this notifier.
///
/// Copied from [ScheduleViewModel].
@ProviderFor(ScheduleViewModel)
final scheduleViewModelProvider =
    AutoDisposeNotifierProvider<ScheduleViewModel, ScheduleState>.internal(
      ScheduleViewModel.new,
      name: r'scheduleViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$scheduleViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ScheduleViewModel = AutoDisposeNotifier<ScheduleState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
