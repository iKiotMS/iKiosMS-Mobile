import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/auth_token_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth/auth_repository_provider.dart';

part 'user_profile_provider.g.dart';

@riverpod
Future<UserModel?> userProfile(Ref ref) async {
  final tokenState = ref.watch(authTokenProvider);
  if (tokenState.value == null) {
    return null;
  }

  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.getProfile();
}
