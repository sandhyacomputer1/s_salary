// lib/features/admin/reports/repositories/report_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client_provider.dart';
import '../models/report_models.dart';
import '../services/report_service.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(ref.watch(apiClientProvider));
});

class SelectedMonth {
  final int month;
  final int year;
  const SelectedMonth(this.month, this.year);

  @override
  bool operator ==(Object o) => o is SelectedMonth && o.month == month && o.year == year;
  @override
  int get hashCode => month * 10000 + year;
}

final selectedMonthProvider = StateProvider<SelectedMonth>((ref) {
  final now = DateTime.now();
  return SelectedMonth(now.month, now.year);
});

final monthlyMatrixProvider = FutureProvider.autoDispose<List<MonthlyMatrixRow>>((ref) async {
  final sel = ref.watch(selectedMonthProvider);
  return ref.watch(reportServiceProvider).fetchMonthlyMatrix(month: sel.month, year: sel.year);
});

class DailyReportsFilter {
  final DateTime? date;
  final String search;
  const DailyReportsFilter({this.date, this.search = ''});

  @override
  bool operator ==(Object o) => o is DailyReportsFilter && o.date == date && o.search == search;
  @override
  int get hashCode => Object.hash(date, search);
}

final dailyReportsFilterProvider = StateProvider<DailyReportsFilter>((ref) => const DailyReportsFilter());

final dailyReportsProvider = FutureProvider.autoDispose<List<DailyWorkReport>>((ref) async {
  final f = ref.watch(dailyReportsFilterProvider);
  return ref.watch(reportServiceProvider).fetchDailyReports(date: f.date, search: f.search);
});