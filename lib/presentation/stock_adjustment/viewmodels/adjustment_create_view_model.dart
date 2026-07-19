import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/inventory_item_model.dart';
import '../../../data/models/location_option_model.dart';
import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/location_option/location_option_repository.dart';
import '../../../data/repositories/location_option/location_option_repository_provider.dart';
import '../../../data/repositories/stock_movement/stock_movement_repository.dart';
import '../../../data/repositories/stock_movement/stock_movement_repository_provider.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

part 'adjustment_create_view_model.g.dart';

// ── Draft line state ─────────────────────────────────────────────────────

/// One product row being drafted in the create form — not the same as
/// [StockMovementLine] (the API's read model): this only exists client-side
/// until submit, and tracks the editable "counted quantity" plus the system
/// stock snapshot it's compared against.
class AdjustmentDraftLine {
  final String productItemId;
  final String productName;
  final String? sku;
  final num systemStock;
  final num countedQuantity;
  final String? note;

  const AdjustmentDraftLine({
    required this.productItemId,
    required this.productName,
    this.sku,
    required this.systemStock,
    required this.countedQuantity,
    this.note,
  });

  num get diff => countedQuantity - systemStock;

  AdjustmentDraftLine copyWith({num? countedQuantity, String? note, bool clearNote = false}) {
    return AdjustmentDraftLine(
      productItemId: productItemId,
      productName: productName,
      sku: sku,
      systemStock: systemStock,
      countedQuantity: countedQuantity ?? this.countedQuantity,
      note: clearNote ? null : (note ?? this.note),
    );
  }
}

// ── State ─────────────────────────────────────────────────────────────────

/// Holds all UI state for the "Tạo điều chỉnh tồn kho" form.
class AdjustmentCreateState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  final String? locationId;
  final String? locationType; // 'branch' | 'warehouse'
  final String? locationLabel;

  /// True only for TENANT_OWNER, who has no single owned branch/warehouse
  /// and must pick one — mirrors `LocationSettingsState.notApplicable`'s
  /// role branching, inverted (BRANCH_MANAGER/WAREHOUSE_MANAGER never see
  /// a picker here since their own location is used automatically).
  final bool requiresLocationPicker;
  final List<LocationOption> locationOptions;

  final List<AdjustmentDraftLine> lines;
  final String note;

  const AdjustmentCreateState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.locationId,
    this.locationType,
    this.locationLabel,
    this.requiresLocationPicker = false,
    this.locationOptions = const [],
    this.lines = const [],
    this.note = '',
  });

  bool get hasLocation => locationId != null && locationType != null;

  bool get hasRealChange => lines.any((l) => l.diff != 0);

  bool get canSubmit => hasLocation && lines.isNotEmpty && hasRealChange && !isSubmitting;

  AdjustmentCreateState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? locationId,
    String? locationType,
    String? locationLabel,
    bool? requiresLocationPicker,
    List<LocationOption>? locationOptions,
    List<AdjustmentDraftLine>? lines,
    String? note,
  }) {
    return AdjustmentCreateState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      locationId: locationId ?? this.locationId,
      locationType: locationType ?? this.locationType,
      locationLabel: locationLabel ?? this.locationLabel,
      requiresLocationPicker: requiresLocationPicker ?? this.requiresLocationPicker,
      locationOptions: locationOptions ?? this.locationOptions,
      lines: lines ?? this.lines,
      note: note ?? this.note,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────

@riverpod
class AdjustmentCreateViewModel extends _$AdjustmentCreateViewModel {
  @override
  AdjustmentCreateState build() {
    Future.microtask(_init);
    return const AdjustmentCreateState(isLoading: true);
  }

  StockMovementRepository get _stockMovementRepository => ref.read(stockMovementRepositoryProvider);
  LocationOptionRepository get _locationOptionRepository => ref.read(locationOptionRepositoryProvider);

  Future<void> _init() async {
    final profile = await ref.read(userProfileProvider.future);
    if (profile == null) {
      state = state.copyWith(isLoading: false, errorMessage: 'Không tìm thấy thông tin người dùng.');
      return;
    }

    if (profile.role == 'BRANCH_MANAGER' && profile.branchId != null) {
      state = state.copyWith(
        isLoading: false,
        locationId: profile.branchId,
        locationType: 'branch',
        locationLabel: 'Chi nhánh của tôi',
      );
      return;
    }
    if (profile.role == 'WAREHOUSE_MANAGER' && profile.warehouseId != null) {
      state = state.copyWith(
        isLoading: false,
        locationId: profile.warehouseId,
        locationType: 'warehouse',
        locationLabel: 'Kho của tôi',
      );
      return;
    }
    if (profile.role == 'TENANT_OWNER') {
      state = state.copyWith(requiresLocationPicker: true);
      try {
        final options = await _locationOptionRepository.getLocationOptions();
        state = state.copyWith(isLoading: false, locationOptions: options);
      } catch (e) {
        state = state.copyWith(isLoading: false, errorMessage: 'Tải danh sách chi nhánh/kho thất bại');
      }
      return;
    }

    state = state.copyWith(isLoading: false, errorMessage: 'Tài khoản của bạn không có quyền tạo điều chỉnh tồn kho.');
  }

  /// TENANT_OWNER only. Switching location clears any drafted lines, since
  /// they were picked against the previous location's stock.
  void selectLocation(LocationOption option) {
    state = state.copyWith(locationId: option.id, locationType: option.type, locationLabel: option.name, lines: []);
  }

  /// Adds a product, or replaces it in place if already drafted (dedupes by
  /// `productItemId` — no separate "duplicate product" check needed).
  void addOrUpdateProduct(InventoryItem item) {
    final index = state.lines.indexWhere((l) => l.productItemId == item.productItemId);
    final line = AdjustmentDraftLine(
      productItemId: item.productItemId,
      productName: item.productName,
      sku: item.sku,
      systemStock: item.stock,
      countedQuantity: item.stock,
    );
    final lines = [...state.lines];
    if (index >= 0) {
      lines[index] = line;
    } else {
      lines.add(line);
    }
    state = state.copyWith(lines: lines);
  }

  void updateCountedQuantity(String productItemId, num countedQuantity) {
    state = state.copyWith(
      lines: [
        for (final l in state.lines)
          if (l.productItemId == productItemId) l.copyWith(countedQuantity: countedQuantity) else l,
      ],
    );
  }

  void updateLineNote(String productItemId, String note) {
    state = state.copyWith(
      lines: [
        for (final l in state.lines)
          if (l.productItemId == productItemId) l.copyWith(note: note, clearNote: note.isEmpty) else l,
      ],
    );
  }

  void removeLine(String productItemId) {
    state = state.copyWith(lines: state.lines.where((l) => l.productItemId != productItemId).toList());
  }

  void setNote(String value) {
    state = state.copyWith(note: value);
  }

  /// Returns the created request's id on success, or null on failure
  /// (check [AdjustmentCreateState.errorMessage] for the message).
  Future<String?> submit() async {
    if (!state.canSubmit) return null;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final created = await _stockMovementRepository.createAdjustment(
        locationId: state.locationId!,
        locationType: state.locationType!,
        note: state.note.isEmpty ? null : state.note,
        details: [
          for (final l in state.lines)
            AdjustmentDetailInput(productItemId: l.productItemId, receivedQuantity: l.countedQuantity, note: l.note),
        ],
      );
      state = state.copyWith(isSubmitting: false);
      return created.id;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'Tạo phiếu điều chỉnh thất bại');
      return null;
    }
  }
}
