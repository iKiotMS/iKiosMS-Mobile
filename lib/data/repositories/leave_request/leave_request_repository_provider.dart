import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/leave_request_api_service.dart';
import 'leave_request_repository.dart';
import 'leave_request_repository_impl.dart';

part 'leave_request_repository_provider.g.dart';

@riverpod
LeaveRequestRepository leaveRequestRepository(Ref ref) {
  return LeaveRequestRepositoryImpl(ref.watch(leaveRequestApiServiceProvider));
}
