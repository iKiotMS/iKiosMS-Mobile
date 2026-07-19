import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ikiotms_mobile/data/models/shift_model.dart';
import 'package:ikiotms_mobile/data/payroll_data.dart';
import 'package:ikiotms_mobile/presentation/auth/views/login_view.dart';

void main() {
  testWidgets('App smoke test — login visible', (WidgetTester tester) async {
    // Wrap in ProviderScope just like main.dart does.
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginView())),
    );

    expect(find.text('iKiotMS Mobile'), findsOneWidget);
    expect(find.text('Số điện thoại'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });

  test('Shift parses attendance inside userId', () {
    final shift = ShiftModel.fromJson({
      '_id': 'schedule-1',
      'workDate': '2026-07-20T00:00:00.000Z',
      'status': 'SCHEDULED',
      'shiftTemplateId': {'startTime': '08:00', 'endTime': '17:00'},
      'userId': {
        'role': 'STAFF',
        'attendance': {
          '_id': 'attendance-1',
          'status': 'CHECKED_IN',
          'actualCheckinAt': '2026-07-20T01:00:00.000Z',
        },
      },
    });

    expect(shift.attendanceId, 'attendance-1');
    expect(shift.attendanceStatus, 'CHECKED_IN');
    expect(shift.isAlreadyCheckedIn, isTrue);
  });

  test('Payslip parses nested payroll period', () {
    final payslip = PayslipModel.fromJson({
      '_id': 'payslip-1',
      'status': 'PAID',
      'netSalary': 10000000,
      'payrollPeriodId': {
        'periodStart': '2026-06-26T00:00:00.000Z',
        'periodEnd': '2026-07-25T00:00:00.000Z',
      },
    });

    expect(payslip.netSalary, 10000000);
    expect(payslip.periodStart, isNotNull);
    expect(payslip.periodEnd, isNotNull);
  });
}
