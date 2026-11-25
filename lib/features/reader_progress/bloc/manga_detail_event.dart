part of 'manga_detail_bloc.dart';

/// Base class for all [MangaDetailEvent]s.
sealed class MangaDetailEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Dispatched to initialize and fetch manga details, aggregate,
/// and watch library entry.
final class MangaDetailStarted extends MangaDetailEvent {
  /// Creates a [MangaDetailStarted] event.
  const new({
    required this.mangaId,
    required this.uid,
    this.preferredLocales = const ['en', 'it'],
    this.translatedLanguages = const ['en', 'it'],
  });

  /// The manga UUID.
  final String mangaId;

  /// The current user ID.
  final String uid;

  /// Preferred locale codes for title and description.
  final List<String> preferredLocales;

  /// Translated languages for aggregate chapters.
  final List<String> translatedLanguages;

  @override
  List<Object?> get props => [
    mangaId,
    uid,
    preferredLocales,
    translatedLanguages,
  ];
}

/// Dispatched to force refresh manga details and aggregate from MangaDex.
final class MangaDetailRefreshed extends MangaDetailEvent {
  /// Creates a [MangaDetailRefreshed] event.
  const new();
}

/// Internal event fired when library entry stream emits a new value.
final class _MangaDetailLibraryEntryUpdated extends MangaDetailEvent {
  const new(this.entry);

  final LibraryEntry? entry;

  @override
  List<Object?> get props => [entry];
}

/// Dispatched to add the manga to the user's library with a [ReadingStatus].
final class MangaDetailAddedToLibrary extends MangaDetailEvent {
  /// Creates a [MangaDetailAddedToLibrary] event.
  const new([this.status = ReadingStatus.reading]);

  /// The initial reading status.
  final ReadingStatus status;

  @override
  List<Object?> get props => [status];
}

/// Dispatched to update the reading status of this manga.
final class MangaDetailStatusChanged extends MangaDetailEvent {
  /// Creates a [MangaDetailStatusChanged] event.
  const new(this.status);

  /// The new reading status.
  final ReadingStatus status;

  @override
  List<Object?> get props => [status];
}

/// Dispatched to remove the manga from the user's library.
final class MangaDetailRemovedFromLibrary extends MangaDetailEvent {
  /// Creates a [MangaDetailRemovedFromLibrary] event.
  const new();
}

/// Dispatched when the user toggles a single chapter's read state.
final class MangaDetailChapterToggled extends MangaDetailEvent {
  /// Creates a [MangaDetailChapterToggled] event.
  const new({required this.chapter, required this.isRead});

  /// The chapter being toggled.
  final MangaChapter chapter;

  /// The desired read state.
  final bool isRead;

  @override
  List<Object?> get props => [chapter, isRead];
}

/// Dispatched when the user marks an entire volume as read.
final class MangaDetailVolumeMarkedRead extends MangaDetailEvent {
  /// Creates a [MangaDetailVolumeMarkedRead] event.
  const new(this.volume);

  /// The volume being marked as read.
  final MangaVolume volume;

  @override
  List<Object?> get props => [volume];
}

/// Dispatched when the user requests marking all previous chapters as read
/// up to [targetChapter].
final class MangaDetailBulkPreviousRequested extends MangaDetailEvent {
  /// Creates a [MangaDetailBulkPreviousRequested] event.
  const new(this.targetChapter);

  /// The target chapter up to which all previous unread chapters
  /// should be marked.
  final MangaChapter targetChapter;

  @override
  List<Object?> get props => [targetChapter];
}

/// Dispatched when the user confirms marking all previous unread
/// chapters as read.
final class MangaDetailBulkPreviousConfirmed extends MangaDetailEvent {
  /// Creates a [MangaDetailBulkPreviousConfirmed] event.
  const new();
}

/// Dispatched when the user dismisses the bulk read sheet without confirming.
final class MangaDetailBulkPreviousDismissed extends MangaDetailEvent {
  /// Creates a [MangaDetailBulkPreviousDismissed] event.
  const new();
}

/// Dispatched when the user marks all released chapters up to the latest
/// known chapter as read (caught up).
final class MangaDetailCatchUpRequested extends MangaDetailEvent {
  /// Creates a [MangaDetailCatchUpRequested] event.
  const new();
}
