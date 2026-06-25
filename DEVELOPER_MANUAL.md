# Hướng dẫn Phát triển iKiotMS Mobile (Beginner-Friendly Manual)

Chào mừng bạn đến với dự án iKiotMS Mobile! Tài liệu này được viết theo cách dễ hiểu nhất để giúp người mới bắt đầu (beginner) có thể đọc hiểu code và tham gia phát triển dự án dễ dàng.

---

## 1. Kiến trúc dự án: MVVM (Model - View - ViewModel)

Dự án này sử dụng kiến trúc **MVVM** kết hợp với **Riverpod** để quản lý trạng thái. Kiến trúc này chia code thành các lớp (layers) rõ ràng để dễ quản lý:

### Data chảy như thế nào?
**View** ➔ **ViewModel** ➔ **Repository** ➔ **API Service** ➔ **Backend**

1. **View (Giao diện):** Nơi hiển thị UI (các file `.dart` trong thư mục `presentation/.../views`). View chỉ hiển thị dữ liệu và nhận tương tác của người dùng (bấm nút, nhập text), hoàn toàn KHÔNG chứa logic xử lý data.
2. **ViewModel (Quản lý trạng thái):** Đứng giữa View và Repository. Nhận lệnh từ View, gọi Repository để lấy dữ liệu, sau đó cập nhật trạng thái (`state`). Khi trạng thái thay đổi, View sẽ tự động cập nhật lại.
3. **Repository (Xử lý Data Logic):** Nơi chứa logic lấy dữ liệu (từ API hoặc database local). Nếu dữ liệu lỗi, Repository sẽ báo lỗi lên ViewModel.
4. **API Service:** Lớp chuyên làm nhiệm vụ gọi HTTP Request (GET, POST) lên server. 
5. **Model:** Các class định nghĩa cấu trúc dữ liệu (ví dụ: `UserModel`, `ShiftModel`).

---

## 2. Cấu trúc Thư mục

```text
lib/
├── app.dart                   # File cấu hình gốc của ứng dụng (MaterialApp, Theme, Router)
├── main.dart                  # Điểm khởi chạy ứng dụng (hàm main)
├── core/                      # Chứa các file dùng chung toàn app
│   ├── auth/                  # Quản lý token đăng nhập (Lưu trữ và đọc Token)
│   ├── constants/             # Các hằng số (Đường dẫn API, màu sắc, ...)
│   ├── network/               # Cấu hình gọi API (Dio Client, Exception)
│   └── utils/                 # Các hàm tiện ích dùng chung (Format ngày tháng, ...)
├── data/                      # Tầng Data (Models, Repositories, Services)
│   ├── models/                # Các class chứa dữ liệu (UserModel, ShiftModel)
│   ├── repositories/          # Nơi xử lý logic data (lưu, lấy data từ API)
│   └── services/              # Các class chỉ làm 1 việc: Gọi API
└── presentation/              # Tầng Giao diện (Màn hình và Logic màn hình)
    ├── auth/                  # Màn hình Đăng nhập
    │   ├── viewmodels/        # LoginViewModel
    │   └── views/             # LoginView
    ├── schedule/              # Màn hình Lịch làm việc
    └── shell/                 # Khung của app (Thanh điều hướng dưới cùng - BottomNavigationBar)
```

---

## 3. Hiểu về Riverpod (Quản lý trạng thái)

Dự án dùng **Riverpod** (cụ thể là `riverpod_generator`) để truyền dữ liệu và quản lý trạng thái.

### Các khái niệm cơ bản:
- **Provider:** Nơi cung cấp dữ liệu. Bất cứ khi nào bạn cần dùng chung 1 class (như `AuthRepository`, `Dio`), bạn tạo 1 Provider cho nó.
- **Notifier (ViewModel):** Một loại Provider đặc biệt có thể thay đổi được `state`. Khi `state` thay đổi, giao diện sẽ tự động vẽ lại (rebuild).
- **ref:** Công cụ giúp bạn đọc dữ liệu từ các Provider khác. Ở giao diện dùng `WidgetRef`, ở trong provider dùng `Ref`.
- **ConsumerWidget:** Thay vì dùng `StatelessWidget`, chúng ta dùng `ConsumerWidget` để giao diện có quyền truy cập vào `ref`.

### Code Generation (`build_runner`)
Vì chúng ta dùng thư viện `riverpod_annotation`, mỗi khi bạn viết 1 Provider mới có dòng `@riverpod` hoặc thay đổi code của Provider, bạn **BẮT BUỘC** phải chạy lệnh sau để sinh ra code tự động (các file `.g.dart`):

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 4. Cách flow hoạt động (Ví dụ chức năng Đăng Nhập)

1. **Người dùng bấm "Đăng nhập" trên `LoginView`:**
   Code ở View sẽ gọi hàm: `ref.read(loginViewModelProvider.notifier).login(phone, pass);`

2. **`LoginViewModel` xử lý:**
   Nó cập nhật trạng thái thành "Đang tải" (Hiện loading icon).
   Sau đó gọi `_repository.login(phone, pass)`.

3. **`AuthRepository` làm việc:**
   Gọi `AuthApiService` để bắn API lên backend.
   Nhận `accessToken` về, lưu token vào bộ nhớ an toàn (Secure Storage).
   Trả kết quả về cho ViewModel.

4. **ViewModel báo cáo lại:**
   Cập nhật trạng thái thành "Hoàn thành". `LoginView` ẩn loading icon.
   Cùng lúc đó, `app.dart` đang lắng nghe `AuthTokenProvider`, nhận thấy đã có token -> Tự động chuyển màn hình vào app chính (`AppShell`).

---

## 5. Các Lệnh Thường Dùng (Cheatsheet)

- **Chạy app (Nhanh, dùng khi Dev):** 
  ```bash
  flutter run
  ```
- **Chạy app (Bản nhẹ, sửa lỗi thiếu RAM):**
  ```bash
  flutter run --release
  ```
- **Sinh code tự động (Cho Riverpod):**
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- **Kiểm tra lỗi code:**
  ```bash
  flutter analyze
  ```

---

## 6. Hướng dẫn từng bước (Step-by-Step): Thêm màn hình hoặc API mới

Khi bạn muốn làm một chức năng mới (ví dụ: màn hình Lương - `Salary`), hãy làm theo trình tự từ dưới lên trên (từ Backend lên UI) theo các bước chuẩn sau:

### Bước 1: Khai báo đường dẫn API
Mở file `lib/core/constants/api_constants.dart` và thêm endpoint mới. Việc gom chung endpoint vào đây giúp dễ quản lý.
```dart
class ApiEndpoints {
  // ...
  static const String getSalary = '/salary/my-salary';
}
```

### Bước 2: Tạo API Service (Chỉ chuyên gọi HTTP)
Tạo file `lib/data/services/salary_api_service.dart`. File này chỉ làm nhiệm vụ lấy JSON thô từ backend, KHÔNG xử lý logic.
```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

part 'salary_api_service.g.dart';

@riverpod
SalaryApiService salaryApiService(Ref ref) {
  return SalaryApiService(ref.read(apiClientProvider));
}

class SalaryApiService {
  final Dio _dio;
  SalaryApiService(this._dio);

  Future<Map<String, dynamic>> getSalaryData() async {
    final response = await _dio.get(ApiEndpoints.getSalary);
    return response.data; // Trả về JSON map
  }
}
```

### Bước 3: Tạo Data Model
Tạo file `lib/data/models/salary_model.dart` để chuyển (parse) JSON thành Object của Dart. Bạn tự viết hàm `fromJson` hoặc dùng thư viện.

### Bước 4: Tạo Repository (Xử lý lỗi và Logic Dữ liệu)
Tạo file `lib/data/repositories/salary_repository_impl.dart`. Ở đây bạn sẽ gọi API Service, chuyển đổi JSON thành `SalaryModel`, và ném ra các ngoại lệ (`ApiException`) nếu gặp lỗi mạng.
Đừng quên tạo file `salary_repository_provider.dart` để chia sẻ Repository này qua Riverpod!

### Bước 5: Tạo ViewModel (Quản lý Trạng thái UI)
Tạo file `lib/presentation/salary/viewmodels/salary_view_model.dart`. ViewModel chịu trách nhiệm gọi Repository và chứa trạng thái màn hình (`loading`, `data`, `error`).
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/repositories/salary_repository_provider.dart';
import '../../../data/models/salary_model.dart';

part 'salary_view_model.g.dart';

// Tự động quản lý AsyncValue (Loading, Error, Data)
@riverpod
class SalaryViewModel extends _$SalaryViewModel {
  @override
  Future<SalaryModel> build() async {
    final repo = ref.read(salaryRepositoryProvider);
    return await repo.getSalaryData();
  }
}
```

### Bước 6: Tạo Màn hình (View)
Tạo file `lib/presentation/salary/views/salary_view.dart`. Màn hình sẽ dùng `ConsumerWidget` để lắng nghe ViewModel và tự động vẽ UI.
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/salary_view_model.dart';

class SalaryView extends ConsumerWidget {
  const SalaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch sẽ tự động lắng nghe sự thay đổi
    final state = ref.watch(salaryViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lương của tôi')),
      body: state.when(
        data: (salary) => Center(child: Text('Lương: ${salary.amount}')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}
```

### Bước 7: Sinh code tự động (BẮT BUỘC)
Bất cứ khi nào bạn tạo file có chữ `part '...g.dart';` và `@riverpod`, bạn bắt buộc phải chạy lệnh này ở terminal để Flutter tạo code liên kết:
```bash
dart run build_runner build --delete-conflicting-outputs
```

> **Mẹo nhỏ:** Luôn tuân thủ luồng **View -> ViewModel -> Repository -> API Service**. Không bao giờ gọi thẳng API Service hoặc Dio từ UI!
