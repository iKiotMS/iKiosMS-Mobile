import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/schedule_admin_api_service.dart';
import 'schedule_admin_repository.dart';
import 'schedule_admin_repository_impl.dart';

part 'schedule_admin_repository_provider.g.dart';

@riverpod
ScheduleAdminRepository scheduleAdminRepository(Ref ref) {
  return ScheduleAdminRepositoryImpl(ref.watch(scheduleAdminApiServiceProvider));
}
