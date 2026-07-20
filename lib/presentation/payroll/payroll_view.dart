import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../data/payroll_data.dart';

final _money = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

class PayrollView extends ConsumerWidget {
  const PayrollView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(payrollProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lương của tôi')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(payrollProvider.notifier).load(),
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.payslips.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 180),
                  Center(child: Text(state.error!)),
                ],
              )
            : state.payslips.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Chưa có phiếu lương để hiển thị.')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.payslips.length,
                itemBuilder: (context, index) {
                  final payslip = state.payslips[index];
                  return _payslipCard(context, payslip);
                },
              ),
      ),
    );
  }

  Widget _payslipCard(BuildContext context, PayslipModel payslip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
        title: Text(
          _period(payslip),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${_status(payslip.status)} · ${payslip.totalWorkedHours.toStringAsFixed(1)} giờ công',
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _money.format(payslip.netSalary),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PayslipDetailView(payslipId: payslip.id),
          ),
        ),
      ),
    );
  }
}

class PayslipDetailView extends ConsumerStatefulWidget {
  final String payslipId;

  const PayslipDetailView({super.key, required this.payslipId});

  @override
  ConsumerState<PayslipDetailView> createState() => _PayslipDetailViewState();
}

class _PayslipDetailViewState extends ConsumerState<PayslipDetailView> {
  PayslipModel? payslip;
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final data = await ref
          .read(payrollApiProvider)
          .getPayslip(widget.payslipId);
      if (mounted) setState(() => payslip = data);
    } catch (value) {
      if (mounted) setState(() => error = readableApiError(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết phiếu lương')),
      body: payslip == null
          ? Center(
              child: error == null
                  ? const CircularProgressIndicator()
                  : Text(error!),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          _period(payslip!),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Thực nhận'),
                        Text(
                          _money.format(payslip!.netSalary),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(_status(payslip!.status)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _section('Ngày công', [
                  _row(
                    'Số ngày làm',
                    payslip!.totalWorkedDays.toStringAsFixed(1),
                  ),
                  _row(
                    'Số giờ làm',
                    payslip!.totalWorkedHours.toStringAsFixed(1),
                  ),
                  _row('Nghỉ có lương', '${payslip!.paidLeaveDays} ngày'),
                  _row('Nghỉ không lương', '${payslip!.unpaidLeaveDays} ngày'),
                ]),
                _section('Thu nhập', [
                  _row('Lương cơ bản', _money.format(payslip!.basePay)),
                  _row('Tiền tăng ca', _money.format(payslip!.overtimePay)),
                  _row(
                    'Tiền nghỉ có lương',
                    _money.format(payslip!.paidLeavePay),
                  ),
                  _row('Phụ cấp', _money.format(payslip!.allowance)),
                  _row('Thưởng', _money.format(payslip!.bonus)),
                  _row(
                    'Tổng thu nhập',
                    _money.format(payslip!.grossSalary),
                    bold: true,
                  ),
                ]),
                _section('Khấu trừ', [
                  _row(
                    'Nghỉ không lương',
                    _money.format(payslip!.unpaidLeaveDeduction),
                  ),
                  _row('Khấu trừ khác', _money.format(payslip!.deduction)),
                ]),
                if (payslip!.note?.isNotEmpty == true)
                  _section('Ghi chú', [Text(payslip!.note!)]),
              ],
            ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        ],
      ),
    );
  }
}

String _period(PayslipModel payslip) {
  final formatter = DateFormat('dd/MM/yyyy');
  if (payslip.periodStart == null || payslip.periodEnd == null) {
    return 'Kỳ lương';
  }
  return '${formatter.format(payslip.periodStart!.toLocal())} - ${formatter.format(payslip.periodEnd!.toLocal())}';
}

String _status(String status) => switch (status) {
  'REVIEW' => 'Chờ xác nhận',
  'APPROVED' => 'Đã duyệt',
  'PAID' => 'Đã thanh toán',
  _ => status,
};
