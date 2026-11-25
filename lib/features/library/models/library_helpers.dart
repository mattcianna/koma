import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:library_repository/library_repository.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';

/// Pure Dart helper function to resolve MangaDex CDN cover URLs
/// for a library entry.
String? resolveLibraryCoverUrl(
  String mangaId,
  String? coverFileName, {
  int size = 256,
}) {
  if (coverFileName == null || coverFileName.trim().isEmpty) return null;
  final suffix = size == 512 ? '.512.jpg' : '.256.jpg';
  return 'https://uploads.mangadex.org/covers/$mangaId/$coverFileName$suffix';
}

/// Calculates the unread count hint for a [LibraryEntry].
int calculateUnreadHint(LibraryEntry entry) {
  if (entry.status == ReadingStatus.completed ||
      entry.status == ReadingStatus.dropped ||
      entry.status == ReadingStatus.onHold) {
    return 0;
  }

  final latest = entry.latestKnownChapterNumber;
  if (latest == null || latest.isEmpty || latest == 'none') return 0;
  if (entry.readChapters.contains(latest)) return 0;
  final last = entry.lastReadChapter;
  if (last != null && ChapterComparator.compare(last, latest) >= 0) {
    return 0;
  }

  if (last != null) {
    final latestNum = double.tryParse(latest);
    final lastNum = double.tryParse(last);
    if (latestNum != null && lastNum != null) {
      final diff = (latestNum - lastNum).round();
      if (diff > 0) return diff;
    }
  } else {
    final latestNum = double.tryParse(latest);
    if (latestNum != null) {
      final unread = latestNum.round() - entry.readChapters.length;
      if (unread > 0) return unread;
    }
  }
  return 1;
}

/// Extension on [ReadingStatus] to map to [KomaStatusType].
extension ReadingStatusToKomaStatusType on ReadingStatus {
  /// Converts [ReadingStatus] to [KomaStatusType].
  KomaStatusType toKomaStatusType() {
    switch (this) {
      case ReadingStatus.reading:
        return KomaStatusType.reading;
      case ReadingStatus.planToRead:
        return KomaStatusType.planToRead;
      case ReadingStatus.completed:
        return KomaStatusType.completed;
      case ReadingStatus.onHold:
        return KomaStatusType.onHold;
      case ReadingStatus.dropped:
        return KomaStatusType.dropped;
    }
  }
}

/// Resolves the localized display label for a [ReadingStatus].
String localizedReadingStatus(AppLocalizations l10n, ReadingStatus status) {
  switch (status) {
    case ReadingStatus.reading:
      return l10n.statusReading;
    case ReadingStatus.planToRead:
      return l10n.statusPlanToRead;
    case ReadingStatus.completed:
      return l10n.statusCompleted;
    case ReadingStatus.onHold:
      return l10n.statusOnHold;
    case ReadingStatus.dropped:
      return l10n.statusDropped;
  }
}
