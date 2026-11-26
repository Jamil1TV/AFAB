import 'package:intl/intl.dart';

/// Formats ISO dates and timestamps using the active business date format
/// while keeping Western digits (`0-9`) for financial readability.
abstract final class AfabDateFormatter {
  static String formatIsoDate(
    String? rawDate, {
    String dateFormat = 'YYYY-MM-DD',
    String locale = 'en',
  }) {
    if (rawDate == null || rawDate.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(rawDate.trim());
    if (parsed == null) return rawDate;
    return formatDateTime(parsed, dateFormat: dateFormat, locale: locale);
  }

  static String formatDateTime(
    DateTime date, {
    String dateFormat = 'YYYY-MM-DD',
    String locale = 'en',
  }) {
    final local = date.toLocal();
    final pattern = switch (dateFormat) {
      'MM/DD/YYYY' => 'MM/dd/yyyy',
      'DD/MM/YYYY' => 'dd/MM/yyyy',
      'DD-MM-YYYY' => 'dd-MM-yyyy',
      'MMM DD, YYYY' => 'MMM dd, yyyy',
      'DD MMM YYYY' => 'dd MMM yyyy',
      'YYYY/MM/DD' => 'yyyy/MM/dd',
      _ => 'yyyy-MM-dd',
    };
    return DateFormat(pattern, locale == 'ar' ? 'ar' : 'en_US').format(local);
  }

  static String formatYearMonthShort(String yyyyMm, String locale) {
    final parts = yyyyMm.split('-');
    if (parts.length != 2) return yyyyMm;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return yyyyMm;
    }
    final dt = DateTime(year, month, 1);
    return DateFormat.MMM(locale == 'ar' ? 'ar' : 'en_US').format(dt);
  }

  static String formatRelativeTimestamp(DateTime? dt, String locale) {
    if (dt == null) return '';
    final local = dt.toLocal();
    return DateFormat('MMM d, HH:mm', locale == 'ar' ? 'ar' : 'en_US')
        .format(local);
  }
}
