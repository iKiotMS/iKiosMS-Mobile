# iKiotMS Mobile — Architecture Manual

A beginner-friendly guide explaining how all major components of this app work together.

---

## 1. App Overview

The iKiotMS Mobile app is the employee-facing side of a shift management system. Right now the app can:

- **Show employee shifts** for any Monday–Sunday week.
- **Let the employee pick a week** using a date picker.
- **Show shift details** (time, role, location, status).
- **Let the employee check in** to an active shift.

The other two tabs (Chấm công, Cá nhân) are placeholder screens that can be filled in later.

---

## 2. Folder Structure

```
lib/
├── main.dart                   ← App entry point
├── app.dart                    ← MaterialApp + Theme setup
│
├── core/                       ← Shared tools used across the whole app
│   ├── constants/
│   │   └── api_constants.dart  ← Backend URL and endpoint paths
│   ├── network/
│   │   ├── api_client.dart     ← Dio HTTP client (configured once)
│   │   └── api_exception.dart  ← Custom error class for API failures
│   └── utils/
│       └── date_time_utils.dart ← Date formatting helpers (week labels, etc.)
│
├── data/                       ← Everything about data (models, services, repos)
│   ├── models/
│   │   └── shift_model.dart    ← Shift data class + JSON parsing
│   ├── services/
│   │   └── shift_api_service.dart ← Raw HTTP calls to the backend
│   └── repositories/
│       ├── shift_repository.dart         ← Interface (contract)
│       ├── shift_repository_impl.dart    ← Real implementation
│       └── shift_repository_provider.dart ← Riverpod provider for the repo
│
└── presentation/               ← Everything visible on screen
    ├── shell/
    │   └── app_shell.dart      ← Bottom navigation bar + tab switching
    ├── schedule/
    │   ├── viewmodels/
    │   │   ├── schedule_view_model.dart      ← State + logic for schedule screen
    │   │   └── shift_detail_view_model.dart  ← State + logic for detail screen
    │   ├── views/
    │   │   ├── schedule_view.dart     ← The main schedule screen
    │   │   └── shift_detail_view.dart ← The shift detail screen
    │   └── widgets/
    │       ├── shift_card.dart         ← One shift row in the list
    │       ├── shift_status_badge.dart ← Colored status pill
    │       ├── schedule_empty_state.dart ← "No shifts" message
    │       ├── week_selector_bar.dart  ← Week range selector bar
    │       └── pressable_scale.dart    ← Tap-feedback wrapper widget
    ├── attendance/
    │   └── attendance_placeholder_view.dart ← Placeholder for Chấm công tab
    └── profile/
        └── profile_placeholder_view.dart    ← Placeholder for Cá nhân tab
```

**In plain language:**
- `core/` — utilities that help everything else work. Not specific to any screen.
- `data/` — all backend data: how it is fetched, parsed, and exposed.
- `presentation/` — what the user actually sees and interacts with.
- `models/` — the Dart class that represents a shift (fields, JSON parsing).
- `services/` — the layer that physically makes HTTP calls. Nothing else, no logic.
- `repositories/` — sits between the service and the ViewModel. Converts raw JSON errors into clean `ApiException`s and returns typed `ShiftModel` objects.
- `viewmodels/` — brain of each screen. Holds the loading/error/data state and decides what happens when the user takes an action.
- `views/` — the actual Flutter screens. They only read state from the ViewModel and call ViewModel methods.
- `widgets/` — small reusable UI pieces used by views.

---

## 3. Data Flow

### Going to the backend (request)

```
View → ViewModel → Repository → API Service → Backend
```

1. **View** — the user taps a button or the screen opens.
2. **ViewModel** — the View calls a method on the ViewModel (e.g., `loadShifts()`).
3. **Repository** — the ViewModel calls `repository.getShifts(...)`.
4. **API Service** — the Repository calls `apiService.getShifts(...)` which calls `dio.get(...)`.
5. **Backend** — the real HTTP request goes out.

### Coming back from the backend (response)

```
Backend → API Service → Repository → ViewModel → View
```

1. **Backend** — returns a JSON response.
2. **API Service** — gives the raw JSON map back to the Repository.
3. **Repository** — parses JSON into `ShiftModel` objects. If there's an error, wraps it as `ApiException`.
4. **ViewModel** — receives the list of `ShiftModel`s, updates `state.shifts`, sets `isLoading = false`.
5. **View** — Riverpod automatically rebuilds the UI because it was watching the ViewModel's state.

**Example — Schedule Screen:**

When `ScheduleView` opens, Riverpod creates `ScheduleViewModel`. The `build()` method immediately calls `_loadShifts(weekStart, weekEnd)`. The ViewModel sets `isLoading = true` → ScheduleView shows a spinner. When data arrives, `isLoading = false` and `shifts` is populated → ScheduleView shows the shift cards.

---

## 4. Riverpod Providers

### What is `ProviderScope`?

`ProviderScope` in `main.dart` is the root container for all Riverpod providers. Without it, no provider will work. Think of it as the "power switch" for state management.

```dart
void main() {
  runApp(
    const ProviderScope(  // ← required
      child: MyApp(),
    ),
  );
}
```

### What are generated providers?

When you write `@riverpod` above a function or class, the `build_runner` tool generates a provider automatically. For example:

```dart
// You write in api_client.dart:
@riverpod
Dio apiClient(Ref ref) { ... }

// build_runner generates in api_client.g.dart:
final apiClientProvider = AutoDisposeProvider<Dio>.internal(...);
```

You use `apiClientProvider` in your code — never touch the `.g.dart` file directly.

### Why do `.g.dart` files exist?

They are **machine-generated code**. Writing Riverpod provider boilerplate by hand is repetitive and error-prone. `riverpod_generator` does it for you. The `.g.dart` files:
- Are auto-created when you run `dart run build_runner build`.
- Are committed to version control so the project compiles without running build_runner every time.
- Should **never be edited manually** — your changes will be overwritten next time you run build_runner.

### How does ScheduleView read ScheduleViewModel?

```dart
// In schedule_view.dart:
class ScheduleView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch() reads the current state AND rebuilds when state changes.
    final state = ref.watch(scheduleViewModelProvider);
    ...
  }
}
```

`scheduleViewModelProvider` was generated from `ScheduleViewModel` by build_runner.

### How does the ViewModel get the Repository?

```dart
// In schedule_view_model.dart:
ShiftRepository get _repository => ref.read(shiftRepositoryProvider);
```

`ref.read()` gets the current value of the provider without subscribing to changes. This is correct for use inside ViewModel methods.

---

## 5. Schedule Screen Flow

| Event | What happens |
|---|---|
| App opens | `ScheduleViewModel.build()` runs → calculates current Mon-Sun week → calls `_loadShifts()` |
| Loading | `isLoading = true` → spinner shown |
| Data returns | `shifts` list populated → shift cards displayed |
| User taps week selector | `showDatePicker` opens |
| User picks a date | `ViewModel.selectDate(date)` called → calculates new Mon-Sun week → calls `_loadShifts()` again |
| App reloads | Loading spinner → new shifts for selected week appear |
| Pull to refresh | `RefreshIndicator` calls `ViewModel.loadShifts()` → same reload cycle |

---

## 6. Check-in Flow

| Step | What happens |
|---|---|
| User opens shift detail | `ShiftDetailViewModel.build(shiftId)` → calls `_loadShift(shiftId)` |
| Shift loads | `state.shift` populated → detail screen renders with status and check-in button |
| User taps "Chấm công vào ca" | `_CheckInSection` calls `onCheckIn()` |
| ViewModel.checkIn() | Sets `isCheckingIn = true` → button shows spinner and is disabled |
| Repository.checkIn() | Calls `ApiService.checkIn()` → POST request to backend |
| API succeeds | Updated `ShiftModel` returned → `state.shift` updated → `isCheckingIn = false` |
| View shows success | `checkIn()` returns `true` → view shows green SnackBar "Chấm công thành công" → `ScheduleViewModel.loadShifts()` also called to refresh the list |
| API fails | `isCheckingIn = false` → `checkIn()` returns `false` → view shows error SnackBar |

---

## 7. Where To Change Backend Details

### Base API URL
**File:** `lib/core/constants/api_constants.dart`
```dart
const String kBaseUrl = 'TODO_REPLACE_WITH_BACKEND_URL';
// Change this to: 'https://your-real-domain.com'
```

### Endpoint paths
**File:** `lib/core/constants/api_constants.dart`
```dart
class ApiEndpoints {
  static const String shifts = '/api/employee/shifts';
  static String shiftDetail(String id) => '/api/employee/shifts/$id';
  static String checkIn(String id) => '/api/employee/shifts/$id/check-in';
}
```
Change the path strings if your backend uses different routes.

### Auth token / Bearer header
**File:** `lib/core/network/api_client.dart`

Find the commented-out `InterceptorsWrapper` block and uncomment it. Fill in your token source:
```dart
dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.read(authTokenProvider); // your token provider
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ),
);
```

### ShiftModel JSON parsing
**File:** `lib/data/models/shift_model.dart` — `ShiftModel.fromJson()`

If your backend uses different field names (e.g. `start_time` instead of `startTime`), change the keys here:
```dart
startTime: json['start_time']?.toString() ?? '',
```

---

## 8. Where To Change UI Text

### Vietnamese tab names, button labels, snackbar messages
These are written directly in the view and widget files. Search for the Vietnamese text:

| Text | File |
|---|---|
| "Lịch làm", "Chấm công", "Cá nhân" | `lib/presentation/shell/app_shell.dart` |
| "Xin chào! 👋" | `lib/presentation/schedule/views/schedule_view.dart` |
| "Đang tải lịch làm..." | `lib/presentation/schedule/views/schedule_view.dart` |
| "Chưa có ca làm trong tuần này" | `lib/presentation/schedule/widgets/schedule_empty_state.dart` |
| "Chấm công vào ca" | `lib/presentation/schedule/views/shift_detail_view.dart` |
| "Chấm công thành công / thất bại" | `lib/presentation/schedule/views/shift_detail_view.dart` |

### Vietnamese status labels (Đã xếp lịch, Sắp tới, etc.)
**File:** `lib/data/models/shift_model.dart` — `statusLabel` getter

```dart
String get statusLabel {
  const labels = {
    'scheduled': 'Đã xếp lịch',
    'upcoming': 'Sắp tới',
    'active': 'Đang diễn ra',
    'completed': 'Hoàn thành',
    'missed': 'Đã bỏ lỡ',
  };
  return labels[status] ?? status;
}
```

### Vietnamese weekday abbreviations
**File:** `lib/core/utils/date_time_utils.dart` — `_viWeekdayShort` map.

---

## 9. How To Add A New Screen

Here is a simple example: adding an **Attendance History** screen.

### Step 1 — Create the View
Create `lib/presentation/attendance/attendance_history_view.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceHistoryView extends ConsumerWidget {
  const AttendanceHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử chấm công')),
      body: const Center(child: Text('Lịch sử chấm công sẽ hiển thị ở đây')),
    );
  }
}
```

### Step 2 — Create the ViewModel (if backend data is needed)
Create `lib/presentation/attendance/viewmodels/attendance_view_model.dart`:
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'attendance_view_model.g.dart';

class AttendanceState {
  final bool isLoading;
  const AttendanceState({this.isLoading = false});
}

@riverpod
class AttendanceViewModel extends _$AttendanceViewModel {
  @override
  AttendanceState build() {
    return const AttendanceState();
  }
}
```

Then run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 3 — Add Repository method (if new API endpoint needed)
In `lib/data/repositories/shift_repository.dart`, add a method signature.
In `lib/data/repositories/shift_repository_impl.dart`, add the implementation.
In `lib/data/services/shift_api_service.dart`, add the raw HTTP call.

### Step 4 — Add the bottom navigation item
In `lib/presentation/shell/app_shell.dart`:

1. Add the view to `_screens`:
```dart
static const List<Widget> _screens = [
  ScheduleView(),
  AttendanceHistoryView(), // ← replace placeholder
  ProfilePlaceholderView(),
];
```

2. The `NavigationDestination` for that tab is already there — just update the label if needed.

---

## 10. Common Commands

Run these from inside the `ikiotms_mobile/` folder:

```bash
# Install or update packages after changing pubspec.yaml
flutter pub get

# Regenerate .g.dart files after adding/changing @riverpod providers
dart run build_runner build --delete-conflicting-outputs

# Check for code issues (run this before committing)
flutter analyze

# Run the app on a connected device or emulator
flutter run
```

> **Tip:** After adding any new `@riverpod` annotation, always run `build_runner build` before `flutter analyze`. The analyzer needs the `.g.dart` files to exist first.
