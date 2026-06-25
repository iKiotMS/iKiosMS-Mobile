// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_token_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authTokenHash() => r'594a7ca2e28fec959d9e1c5eff961259f2d0d263';

/// Manages the authentication state across the app.
///
/// Keeps the token in memory and persists it securely to the device.
/// Because reading from storage is async, this provider returns a [Future] of [String].
///
/// Copied from [AuthToken].
@ProviderFor(AuthToken)
final authTokenProvider = AsyncNotifierProvider<AuthToken, String?>.internal(
  AuthToken.new,
  name: r'authTokenProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authTokenHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthToken = AsyncNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
