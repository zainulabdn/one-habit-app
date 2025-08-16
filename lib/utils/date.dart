import 'package:intl/intl.dart';

final _fmt = DateFormat('yyyy-MM-dd');

String ymd(DateTime d) => _fmt.format(DateTime(d.year, d.month, d.day));

DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime yesterday() {
  final now = DateTime.now().subtract(const Duration(days: 1));
  return DateTime(now.year, now.month, now.day);
}

DateTime dayBeforeYesterday() {
  final now = DateTime.now().subtract(const Duration(days: 3));
  return DateTime(now.year, now.month, now.day);
}

Iterable<DateTime> lastNDays(int n, {DateTime? from}) sync* {
  var start = (from ?? today());
  for (int i = 0; i < n; i++) {
    yield start.subtract(Duration(days: i));
  }
}