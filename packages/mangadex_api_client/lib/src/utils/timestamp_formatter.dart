/// Formats a [DateTime] into MangaDex's strict ISO-8601 UTC timestamp format:
/// `YYYY-MM-DDTHH:mm:ss` (without milliseconds and without trailing 'Z').
///
/// MangaDex rejects timestamps containing `.000Z` or `Z` with HTTP 400
/// `validation_exception` matching regex
/// `^\d{4}-[0-1]\d-([0-2]\d|3[0-1])T([0-1]\d|2[0-3]):[0-5]\d:[0-5]\d$`.
String formatMangaDexTimestamp(DateTime dateTime) {
  final d = dateTime.toUtc();
  String pad(int n) => n.toString().padLeft(2, '0');
  final year = d.year;
  final month = pad(d.month);
  final day = pad(d.day);
  final hour = pad(d.hour);
  final minute = pad(d.minute);
  final second = pad(d.second);
  return '$year-$month-${day}T$hour:$minute:$second';
}

/// Utility class for formatting MangaDex timestamps.
abstract final class MangaDexTimestampFormatter {
  /// Formats [dateTime] into `YYYY-MM-DDTHH:mm:ss` UTC.
  static String format(DateTime dateTime) => formatMangaDexTimestamp(dateTime);
}
