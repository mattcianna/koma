// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Koma';

  @override
  String get appTagline => 'Your offline-first manga progress tracker';

  @override
  String get loginTitle => 'Sign in to Koma';

  @override
  String get signUpTitle => 'Create Koma account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get displayNameLabel => 'Display name (optional)';

  @override
  String get signInButton => 'Sign In';

  @override
  String get signUpButton => 'Create Account';

  @override
  String get switchToSignUp => 'New here? Create an account';

  @override
  String get switchToSignIn => 'Already have an account? Sign in';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get devQuickLoginButton => 'QA Test Account Sign-In';

  @override
  String get authInvalidCredentialsError => 'Invalid email or password.';

  @override
  String get authEmailAlreadyInUseError =>
      'An account with this email already exists.';

  @override
  String get authWeakPasswordError => 'Password must be at least 6 characters.';

  @override
  String get authNetworkError =>
      'Network error. Check your connection and try again.';

  @override
  String get authGoogleCancelledError => 'Google sign-in was cancelled.';

  @override
  String get authUnknownError => 'Authentication failed. Please try again.';

  @override
  String get navLibrary => 'Library';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get statusAll => 'All';

  @override
  String get statusReading => 'Reading';

  @override
  String get statusPlanToRead => 'Plan to Read';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusOnHold => 'On Hold';

  @override
  String get statusDropped => 'Dropped';

  @override
  String get libraryTitle => 'Library';

  @override
  String get homeSectionToRead => 'To Read';

  @override
  String get homeSectionCaughtUp => 'Caught Up';

  @override
  String get homeSectionFinished => 'On Hold / Finished';

  @override
  String get homeUpToDateTitle => 'Wow!';

  @override
  String get homeUpToDateDescription => 'You\'re up to date with everything';

  @override
  String get homeUpToDateAction => 'Discover new Manga';

  @override
  String get markAllCaughtUpAction => 'Mark all released chapters as read';

  @override
  String sectionCollapseSemantics(String section) {
    return 'Toggle $section section';
  }

  @override
  String get librarySearchHint => 'Filter library...';

  @override
  String get libraryEmptyTitle => 'Your library is empty';

  @override
  String get libraryEmptyDescription =>
      'Search MangaDex to track chapters, volumes, and reading progress.';

  @override
  String get libraryEmptyAction => 'Discover Manga';

  @override
  String get libraryFilterEmptyTitle => 'No titles match this filter';

  @override
  String get libraryFilterEmptyDescription =>
      'Try clearing your search or selecting another reading status.';

  @override
  String get libraryClearFilters => 'Clear filters';

  @override
  String libraryUnreadChapters(int count) {
    return '$count unread';
  }

  @override
  String chaptersReadProgress(String chapter) {
    return 'Ch. $chapter';
  }

  @override
  String get removeFromLibrary => 'Remove from library';

  @override
  String get removeFromLibraryConfirmTitle => 'Remove from library?';

  @override
  String get removeFromLibraryConfirmBody =>
      'This removes the manga and its progress markers from your library. Reading history events remain intact.';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get confirmAction => 'Confirm';

  @override
  String get removeAction => 'Remove';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get discoverSearchHint => 'Search manga titles on MangaDex...';

  @override
  String get discoverPopularHeader => 'Popular on MangaDex';

  @override
  String get discoverResultsHeader => 'Search results';

  @override
  String get discoverEmptyTitle => 'No manga found';

  @override
  String get discoverEmptyDescription =>
      'No matching titles were found on MangaDex for your query.';

  @override
  String get discoverRateLimitError =>
      'MangaDex rate limit reached. Please wait a moment and retry.';

  @override
  String get discoverOfflineNotice =>
      'Offline mode: showing cached results where available.';

  @override
  String get retryAction => 'Retry';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get mangaDetailTitle => 'Manga Details';

  @override
  String get addToLibrary => 'Add to Library';

  @override
  String get inLibrary => 'In Library';

  @override
  String get changeStatus => 'Change status';

  @override
  String get synopsisTitle => 'Synopsis';

  @override
  String get noSynopsis => 'No description available.';

  @override
  String chaptersProgressFraction(int read, int total) {
    return 'Ch. $read / $total';
  }

  @override
  String continueChapterLabel(String chapter) {
    return 'Continue Ch. $chapter';
  }

  @override
  String get volumesAndChaptersTitle => 'Volumes & Chapters';

  @override
  String volumeLabel(String number) {
    return 'Volume $number';
  }

  @override
  String get unassignedChaptersLabel => 'Unassigned Chapters';

  @override
  String volumeProgressSummary(int read, int total) {
    return '$read/$total read';
  }

  @override
  String get markVolumeReadTooltip => 'Mark volume as read';

  @override
  String get markVolumeUnreadTooltip => 'Volume already read';

  @override
  String chapterLabel(String number) {
    return 'Ch. $number';
  }

  @override
  String get markPreviousReadTooltip => 'Mark previous as read';

  @override
  String get openMangaDexTooltip => 'Open chapter on MangaDex';

  @override
  String get externalMangaDexHost => 'MangaDex';

  @override
  String get bulkReadSheetTitle => 'Mark previous chapters as read?';

  @override
  String bulkReadSheetMessage(String chapter, int count) {
    return 'Mark Ch. $chapter and all $count unread previous chapters as read in your library?';
  }

  @override
  String bulkReadSheetConfirm(int count) {
    return 'Mark $count Chapters';
  }

  @override
  String bulkReadAllAlreadyRead(String chapter) {
    return 'All previous chapters up to Ch. $chapter are already read.';
  }

  @override
  String get externalLinkError =>
      'Unable to open MangaDex in external browser.';

  @override
  String get chapterUnavailableNotice =>
      'This chapter is currently unavailable on MangaDex.';

  @override
  String get historyTitle => 'Reading History';

  @override
  String get historyEmptyTitle => 'No reading history yet';

  @override
  String get historyEmptyDescription =>
      'Mark a chapter or volume as read to build your reading timeline.';

  @override
  String historyActionChapterRead(String chapter) {
    return 'Read Chapter $chapter';
  }

  @override
  String historyActionVolumeRead(String volume, int count) {
    return 'Completed Volume $volume ($count ch.)';
  }

  @override
  String historyActionBulkRead(int count) {
    return 'Marked $count chapters read';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String settingsSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get settingsReadingSection => 'Reading Preferences';

  @override
  String get settingsUiLanguage => 'App Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageItalian => 'Italiano';

  @override
  String get settingsScanlationLanguages => 'Preferred MangaDex Languages';

  @override
  String get settingsContentRatings => 'Content Rating Filters';

  @override
  String get settingsRatingSafe => 'Safe';

  @override
  String get settingsRatingSuggestive => 'Suggestive';

  @override
  String get settingsRatingErotica => 'Erotica';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String get settingsNotificationsToggle => 'Daily New Chapter Alerts';

  @override
  String get settingsNotificationsSubtitle =>
      'Receive push alerts when tracked series release chapters.';

  @override
  String get settingsSyncTokenButton => 'Sync Push Token Now';

  @override
  String get settingsTokenSyncedMessage => 'Device push token synced.';

  @override
  String get settingsSavedMessage => 'Preferences saved.';

  @override
  String get settingsSignOutButton => 'Sign Out';

  @override
  String get settingsSignOutConfirmTitle => 'Sign out of Koma?';

  @override
  String get settingsSignOutConfirmBody =>
      'You can sign back in anytime to restore your synced library.';

  @override
  String get genericErrorTitle => 'Something went wrong';

  @override
  String get discoverClearSearchTooltip => 'Clear search';

  @override
  String get libraryClearSearchTooltip => 'Clear search query';

  @override
  String get showPasswordTooltip => 'Show password';

  @override
  String get hidePasswordTooltip => 'Hide password';

  @override
  String get authEmailRequiredError => 'Enter your email address.';

  @override
  String get authPasswordRequiredError => 'Enter your password.';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String mangaCardSemanticsWithAuthor(String title, String author) {
    return '$title, by $author';
  }

  @override
  String mangaCardUnreadSemantics(int count) {
    return '$count unread chapters';
  }

  @override
  String mangaCardProgressSemantics(int percent) {
    return '$percent% completed';
  }

  @override
  String statusChipSemantics(String label) {
    return '$label filter status';
  }

  @override
  String chapterRowMarkReadSemantics(String number) {
    return 'Mark Chapter $number as read';
  }

  @override
  String chapterRowMarkUnreadSemantics(String number) {
    return 'Mark Chapter $number as unread';
  }

  @override
  String chapterRowOpenMangaDexSemantics(String number) {
    return 'Open Chapter $number on MangaDex';
  }

  @override
  String chapterRowMarkPreviousSemantics(String number) {
    return 'Mark previous chapters as read up to Chapter $number';
  }

  @override
  String get chapterRowTapHint => 'Toggle chapter read state';

  @override
  String get chapterRowLongPressHint => 'Mark previous chapters as read';

  @override
  String volumeTileMarkSemantics(String action, String volumeTitle) {
    return '$action: $volumeTitle';
  }

  @override
  String progressHeaderSummary(int read, int total) {
    return '$read of $total chapters';
  }

  @override
  String progressHeaderSemantics(int percent, int read, int total) {
    return '$percent% complete, $read of $total chapters read';
  }

  @override
  String progressHeaderCoverSemantics(String title) {
    return 'Cover art for $title';
  }

  @override
  String homeQuickMarkReadLabel(String chapter) {
    return 'Read Ch. $chapter';
  }

  @override
  String homeQuickMarkReadSemantics(String title, String chapter) {
    return 'Read Ch. $chapter, mark $title chapter $chapter as read';
  }

  @override
  String homeQuickMarkReadSuccess(String title, String chapter) {
    return 'Marked $title Ch. $chapter as read';
  }

  @override
  String detailQuickMarkLatestLabel(String chapter) {
    return 'Mark Ch. $chapter as read';
  }

  @override
  String detailQuickMarkLatestSemantics(String chapter, String title) {
    return 'Mark Ch. $chapter as read, latest unread chapter of $title';
  }
}
