# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iKiotMS Mobile (`ikiotms_mobile`) is a Flutter employee-facing shift-management app. Current features: view weekly shift schedule (Mon–Sun), view shift detail, check in to an active shift (GPS-verified). Two bottom-nav tabs ("Chấm công" attendance history, "Cá nhân" profile) are placeholders. UI strings are Vietnamese.

## Common Commands

Run from the repo root:

```bash
flutter pub get                                          # install/update packages after pubspec.yaml changes
dart run build_runner build --delete-conflicting-outputs # regenerate *.g.dart after touching any @riverpod code
flutter analyze                                           # lint/static analysis — run before committing
flutter test                                              # run tests (single file: flutter test test/widget_test.dart)
flutter run                                                # run on a connected device/emulator
flutter build apk --release                                # release APK (what CI produces)
flutter build appbundle --release                          # release AAB (what CI produces)
```

**Always run `build_runner build` before `flutter analyze`** after adding/editing an `@riverpod` provider — the analyzer needs the generated `.g.dart` file to exist.

A `.env` file (gitignored) must exist at the repo root with `BACKEND_URL=...`; it's loaded by `flutter_dotenv` in `main.dart` before anything else runs. Without it, `kBaseUrl` resolves to `''`.

## Architecture

MVVM with Riverpod (code-generated via `riverpod_generator`/`build_runner`). Strict one-directional data flow — **never call an API service or Dio directly from a View**:

```
View → ViewModel → Repository → API Service → Backend
```

- `lib/core/` — cross-cutting: `auth/auth_token_provider.dart` (secure-storage-backed access/refresh token state, `@Riverpod(keepAlive: true)`), `network/api_client.dart` (single shared `Dio` instance + interceptors), `network/api_exception.dart`, `constants/api_constants.dart` (base URL + `ApiEndpoints`), `utils/date_time_utils.dart`.
- `lib/data/models/` — plain Dart classes with `fromJson` factories (e.g. `ShiftModel`, `UserModel`). This is also where Vietnamese status-label maps live (e.g. `ShiftModel.statusLabel`).
- `lib/data/services/` — thin classes that only issue HTTP calls via the shared `Dio` client and return raw JSON. No business logic.
- `lib/data/repositories/` — interface (`*_repository.dart`) + impl (`*_repository_impl.dart`) + Riverpod provider (`*_repository_provider.dart`, generated `.g.dart`). Converts `DioException`/raw errors into `ApiException`, parses JSON into models.
- `lib/presentation/<feature>/viewmodels/` — `@riverpod` `Notifier`/`AsyncNotifier` classes holding screen state (loading/data/error) and orchestrating repository calls. `build()` typically kicks off the initial load.
- `lib/presentation/<feature>/views/` — `ConsumerWidget`s that `ref.watch` the viewmodel's generated provider and render state; call viewmodel methods on user interaction, never touch repositories/services directly.
- `lib/presentation/<feature>/widgets/` — small reusable UI pieces scoped to that feature.
- `lib/presentation/shell/app_shell.dart` — bottom navigation bar wiring the three top-level tabs.
- `lib/app.dart` — `MaterialApp` + theme; watches `authTokenProvider` to decide between `LoginView` and `AppShell`.

**Adding a new feature/screen** follows this order: add endpoint to `ApiEndpoints` → create `*_api_service.dart` (raw HTTP) → create model with `fromJson` → create repository interface + impl + provider (wraps errors as `ApiException`) → create `@riverpod` viewmodel → create `ConsumerWidget` view → run `build_runner build`. See `DEVELOPER_MANUAL.md` and `docs/architecture_manual.md` for a fully worked example (adding a "Salary"/"Attendance History" screen).

### Auth & token refresh

`api_client.dart`'s Dio instance has an interceptor that attaches `Authorization: Bearer <token>` from `authTokenProvider` on every request, and on a `401` response automatically calls `/auth/refresh` with the stored refresh token, persists the new tokens via `AuthToken.setTokens`, and retries the original request. If refresh fails or no refresh token exists, it calls `AuthToken.clearTokens()`, which flips `authTokenProvider` state to `null` and (via `app.dart`) routes the user back to `LoginView`.

### Riverpod conventions

- Files with `@riverpod` annotations declare `part '<filename>.g.dart';` and must not be edited by hand in the generated file — regenerate instead.
- Use `ref.watch(...)` in views to subscribe/rebuild; use `ref.read(...)` inside viewmodel/repository methods for one-off reads.
- `AuthToken` is `@Riverpod(keepAlive: true)` since it must survive across the whole app lifetime; most other providers use the default `autoDispose` behavior.

## Android Build (native shell)

Flutter's Android embedding lives under `android/`. Java 17 / Kotlin `jvmTarget = "17"`. `applicationId` is `com.ikiotms.ikiotms_mobile_app`. Release signing config reads from either env vars (`ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` — used by CI) or a local `android/key.properties` file (not committed) if those env vars are absent.

## CI

`.github/workflows/android-release.yml` runs on push to `main`/tags and manual dispatch: decodes the keystore from secrets, runs `flutter build apk --release` and `flutter build appbundle --release`, then publishes/updates a moving `latest-android` GitHub Release with the built APK/AAB.
