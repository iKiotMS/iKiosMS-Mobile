import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/auth_token_provider.dart';
import '../services/auth_api_service.dart';
import 'auth_repository.dart';
import 'auth_repository_impl.dart';

part 'auth_repository_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  final apiService = ref.read(authApiServiceProvider);
  final authTokenNotifier = ref.read(authTokenProvider.notifier);
  
  return AuthRepositoryImpl(apiService, authTokenNotifier);
}
