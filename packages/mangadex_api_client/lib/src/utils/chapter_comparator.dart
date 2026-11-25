/// Natural and decimal chapter number comparator for MangaDex chapter keys.
///
/// Correctly orders numeric, fractional, alphanumeric, and special chapters:
/// `"0"` < `"1"` < `"2"` < `"10"` < `"10a"` < `"10b"` < `"10.1"` <
/// `"10.5"` < `"11"` < `"extra"` < `"none"`.
abstract final class ChapterComparator {
  static final RegExp _prefixRegex = RegExp(r'^(\d+(?:\.\d+)?)(.*)$');

  /// Compares two chapter strings using natural numeric prefix ordering.
  ///
  /// Pushes unnumbered chapters (`"none"`) to the end.
  static int compare(String a, String b) {
    if (a == b) return 0;

    final normA = a.trim();
    final normB = b.trim();
    final lowerA = normA.toLowerCase();
    final lowerB = normB.toLowerCase();

    // Pin "none" (unnumbered chapters / oneshots) to the end.
    if (lowerA == 'none' && lowerB == 'none') return 0;
    if (lowerA == 'none') return 1;
    if (lowerB == 'none') return -1;

    final matchA = _prefixRegex.firstMatch(lowerA);
    final matchB = _prefixRegex.firstMatch(lowerB);

    // Both start with a numeric value (e.g. "10", "10.5", "10a", "11").
    if (matchA != null && matchB != null) {
      final numA = double.parse(matchA.group(1)!);
      final numB = double.parse(matchB.group(1)!);
      final numDiff = numA.compareTo(numB);
      if (numDiff != 0) return numDiff;

      final suffixA = matchA.group(2)!.trim();
      final suffixB = matchB.group(2)!.trim();
      if (suffixA.isEmpty && suffixB.isNotEmpty) return -1;
      if (suffixA.isNotEmpty && suffixB.isEmpty) return 1;
      return suffixA.compareTo(suffixB);
    }

    // Chapters with a leading number sort before purely non-numeric
    // labels ("extra", "omake").
    if (matchA != null && matchB == null) return -1;
    if (matchA == null && matchB != null) return 1;

    return lowerA.compareTo(lowerB);
  }
}
