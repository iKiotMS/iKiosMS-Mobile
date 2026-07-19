import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/staff_api_service.dart';
import 'staff_repository.dart';
import 'staff_repository_impl.dart';

part 'staff_repository_provider.g.dart';

@riverpod
StaffRepository staffRepository(Ref ref) {
  return StaffRepositoryImpl(ref.watch(staffApiServiceProvider));
}
