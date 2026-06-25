import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/auth_repository_provider.dart';

part 'login_view_model.g.dart';

class LoginState {
  final bool isLoading;
  final String? errorMessage;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@riverpod
class LoginViewModel extends _$LoginViewModel {
  @override
  LoginState build() {
    return const LoginState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Attempts to log the user in.
  /// Returns true on success, false on failure.
  Future<bool> login(String phoneNumber, String password) async {
    if (phoneNumber.isEmpty || password.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập đầy đủ thông tin');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.login(phoneNumber: phoneNumber, password: password);
      // The auth_token_provider will be updated by the repository,
      // which will automatically trigger the root app router to show the main shell.
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      // The repository throws an ApiException which has a friendly message.
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}
