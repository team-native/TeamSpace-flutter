import 'package:intl/intl.dart';

class Formatters {
  /// 천단위 콤마 포맷터 (예: 420000 -> 420,000원)
  static String currency(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)}원';
  }

  /// 날짜 포맷터 (예: DateTime -> 2026.10.27)
  static String dateDot(DateTime date) {
    return DateFormat('yyyy.MM.dd').format(date);
  }

  /// 시간 포함 날짜 포맷터 (예: DateTime -> 2026.10.27 14:00)
  static String dateTime(DateTime date) {
    return DateFormat('yyyy.MM.dd HH:mm').format(date);
  }
}