import '../../models/user_model.dart';

abstract class AuthRepository {
  /// Authenticates the user with phone number and password.
  /// On success, it persists the tokens and returns the [UserModel].
  Future<UserModel> login({
    required String phoneNumber,
    required String password,
  });

  /// Authenticates via Google (Firebase). Signs in with Google, exchanges the
  /// Firebase ID token at the backend, and persists the returned session
  /// tokens. Throws [ApiException] if the email isn't registered, the role
  /// isn't allowed on mobile, or the user cancels.
  Future<UserModel> loginWithGoogle();

  /// Logs out the user by clearing the persisted tokens.
  Future<void> logout();

  /// Gets the currently authenticated user's profile.
  Future<UserModel> getProfile();

  /// Sets the current user's email (the key used for Google sign-in).
  /// Returns the updated profile.
  Future<UserModel> updateEmail(String email);
}
