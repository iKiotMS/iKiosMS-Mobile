import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/repositories/auth/auth_repository_provider.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

part 'profile_view_model.g.dart';

class ProfileState {
  final bool isSaving;
  final String? errorMessage;

  const ProfileState({this.isSaving = false, this.errorMessage});

  ProfileState copyWith({
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@riverpod
class ProfileViewModel extends _$ProfileViewModel {
  @override
  ProfileState build() => const ProfileState();

  /// Sets the user's email (the key for Google sign-in), then refreshes the
  /// cached profile. Returns true on success.
  Future<bool> updateEmail(String email) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).updateEmail(email.trim());
      // Re-fetch the profile so the UI shows the new email.
      ref.invalidate(userProfileProvider);
      state = state.copyWith(isSaving: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}
