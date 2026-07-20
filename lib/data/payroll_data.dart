import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class PayslipModel {
  final String id;
  final String status;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final double totalWorkedDays;
  final double totalWorkedHours;
  final double basePay;
  final double overtimePay;
  final double paidLeaveDays;
  final double unpaidLeaveDays;
  final double paidLeavePay;
  final double unpaidLeaveDeduction;
  final double bonus;
  final double allowance;
  final double deduction;
  final double grossSalary;
  final double netSalary;
  final String? note;

  const PayslipModel({
    required this.id,
    required this.status,
    this.periodStart,
    this.periodEnd,
    required this.totalWorkedDays,
    required this.totalWorkedHours,
    required this.basePay,
    required this.overtimePay,
    required this.paidLeaveDays,
    required this.unpaidLeaveDays,
    required this.paidLeavePay,
    required this.unpaidLeaveDeduction,
    required this.bonus,
    required this.allowance,
    required this.deduction,
    required this.grossSalary,
    required this.netSalary,
    this.note,
  });

  factory PayslipModel.fromJson(Map<String, dynamic> json) {
    final periodValue = json['payrollPeriodId'];
    final period = periodValue is Map
        ? Map<String, dynamic>.from(periodValue)
        : <String, dynamic>{};

    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    DateTime? date(String key) {
      final value = json[key] ?? period[key];
      return value == null ? null : DateTime.tryParse(value.toString());
    }

    return PayslipModel(
      id: json['_id']?.toString() ?? '',
      status: json['status']?.toString() ?? period['status']?.toString() ?? '',
      periodStart: date('periodStart'),
      periodEnd: date('periodEnd'),
      totalWorkedDays: number('totalWorkedDays'),
      totalWorkedHours: number('totalWorkedHours'),
      basePay: number('basePay'),
      overtimePay: number('overtimePay'),
      paidLeaveDays: number('paidLeaveDays'),
      unpaidLeaveDays: number('unpaidLeaveDays'),
      paidLeavePay: number('paidLeavePay'),
      unpaidLeaveDeduction: number('unpaidLeaveDeduction'),
      bonus: number('bonus'),
      allowance: number('allowance'),
      deduction: number('deduction'),
      grossSalary: number('grossSalary'),
      netSalary: number('netSalary'),
      note: json['note']?.toString(),
    );
  }
}

class PayrollApi {
  final Dio dio;

  PayrollApi(this.dio);

  Future<List<PayslipModel>> getMyPayslips() async {
    final response = await dio.get(
      ApiEndpoints.myPayslips,
      queryParameters: {'page': 1, 'limit': 100},
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    final list = body['data'] as List? ?? const [];
    return list
        .map(
          (item) =>
              PayslipModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<PayslipModel> getPayslip(String id) async {
    final response = await dio.get(ApiEndpoints.myPayslipDetail(id));
    final body = Map<String, dynamic>.from(response.data as Map);
    final value = body['data'] is Map ? body['data'] : body;
    return PayslipModel.fromJson(Map<String, dynamic>.from(value as Map));
  }
}

final payrollApiProvider = Provider<PayrollApi>((ref) {
  return PayrollApi(ref.watch(apiClientProvider));
});

class PayrollState {
  final bool loading;
  final List<PayslipModel> payslips;
  final String? error;

  const PayrollState({
    this.loading = false,
    this.payslips = const [],
    this.error,
  });
}

class PayrollNotifier extends StateNotifier<PayrollState> {
  final PayrollApi api;

  PayrollNotifier(this.api) : super(const PayrollState(loading: true)) {
    load();
  }

  Future<void> load() async {
    state = PayrollState(loading: true, payslips: state.payslips);
    try {
      final data = await api.getMyPayslips();
      state = PayrollState(payslips: data);
    } catch (error) {
      state = PayrollState(
        payslips: state.payslips,
        error: readableApiError(error),
      );
    }
  }
}

final payrollProvider = StateNotifierProvider<PayrollNotifier, PayrollState>((
  ref,
) {
  return PayrollNotifier(ref.watch(payrollApiProvider));
});
