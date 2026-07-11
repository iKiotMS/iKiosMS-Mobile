import '../../models/user_model.dart';

abstract class AuthRepository {
  /// Authenticates the user with phone number and password.
  /// On success, it persists the tokens and returns the [UserModel].
  Future<UserModel> login({
    required String phoneNumber,
    required String password,
  });

  /// Logs out the user by clearing the persisted tokens.
  Future<void> logout();

  /// Gets the currently authenticated user's profile.
  Future<UserModel> getProfile();
}
