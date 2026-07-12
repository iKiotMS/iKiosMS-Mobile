import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/shift_api_service.dart';
import 'shift_repository.dart';
import 'shift_repository_impl.dart';

part 'shift_repository_provider.g.dart';

/// Riverpod-generated provider that exposes [ShiftRepository].
///
/// ViewModels use `ref.watch(shiftRepositoryProvider)` to get the repository.
/// To swap the implementation (e.g., a mock for testing), only change here.
@riverpod
ShiftRepository shiftRepository(Ref ref) {
  final apiService = ref.watch(shiftApiServiceProvider);
  return ShiftRepositoryImpl(apiService);
}
