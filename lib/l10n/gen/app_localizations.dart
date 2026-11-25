import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Koma'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your offline-first manga progress tracker'**
  String get appTagline;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Koma'**
  String get loginTitle;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Koma account'**
  String get signUpTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name (optional)'**
  String get displayNameLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpButton;

  /// No description provided for @switchToSignUp.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get switchToSignUp;

  /// No description provided for @switchToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get switchToSignIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @devQuickLoginButton.
  ///
  /// In en, this message translates to:
  /// **'QA Test Account Sign-In'**
  String get devQuickLoginButton;

  /// No description provided for @authInvalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get authInvalidCredentialsError;

  /// No description provided for @authEmailAlreadyInUseError.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get authEmailAlreadyInUseError;

  /// No description provided for @authWeakPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authWeakPasswordError;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get authNetworkError;

  /// No description provided for @authGoogleCancelledError.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get authGoogleCancelledError;

  /// No description provided for @authUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authUnknownError;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @statusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statusAll;

  /// No description provided for @statusReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get statusReading;

  /// No description provided for @statusPlanToRead.
  ///
  /// In en, this message translates to:
  /// **'Plan to Read'**
  String get statusPlanToRead;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get statusOnHold;

  /// No description provided for @statusDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get statusDropped;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @homeSectionToRead.
  ///
  /// In en, this message translates to:
  /// **'To Read'**
  String get homeSectionToRead;

  /// No description provided for @homeSectionCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'Caught Up'**
  String get homeSectionCaughtUp;

  /// No description provided for @homeSectionFinished.
  ///
  /// In en, this message translates to:
  /// **'On Hold / Finished'**
  String get homeSectionFinished;

  /// No description provided for @homeUpToDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Wow!'**
  String get homeUpToDateTitle;

  /// No description provided for @homeUpToDateDescription.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date with everything'**
  String get homeUpToDateDescription;

  /// No description provided for @homeUpToDateAction.
  ///
  /// In en, this message translates to:
  /// **'Discover new Manga'**
  String get homeUpToDateAction;

  /// No description provided for @markAllCaughtUpAction.
  ///
  /// In en, this message translates to:
  /// **'Mark all released chapters as read'**
  String get markAllCaughtUpAction;

  /// No description provided for @sectionCollapseSemantics.
  ///
  /// In en, this message translates to:
  /// **'Toggle {section} section'**
  String sectionCollapseSemantics(String section);

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter library...'**
  String get librarySearchHint;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Search MangaDex to track chapters, volumes, and reading progress.'**
  String get libraryEmptyDescription;

  /// No description provided for @libraryEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Discover Manga'**
  String get libraryEmptyAction;

  /// No description provided for @libraryFilterEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No titles match this filter'**
  String get libraryFilterEmptyTitle;

  /// No description provided for @libraryFilterEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Try clearing your search or selecting another reading status.'**
  String get libraryFilterEmptyDescription;

  /// No description provided for @libraryClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get libraryClearFilters;

  /// No description provided for @libraryUnreadChapters.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String libraryUnreadChapters(int count);

  /// No description provided for @chaptersReadProgress.
  ///
  /// In en, this message translates to:
  /// **'Ch. {chapter}'**
  String chaptersReadProgress(String chapter);

  /// No description provided for @removeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get removeFromLibrary;

  /// No description provided for @removeFromLibraryConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from library?'**
  String get removeFromLibraryConfirmTitle;

  /// No description provided for @removeFromLibraryConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the manga and its progress markers from your library. Reading history events remain intact.'**
  String get removeFromLibraryConfirmBody;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @discoverSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search manga titles on MangaDex...'**
  String get discoverSearchHint;

  /// No description provided for @discoverPopularHeader.
  ///
  /// In en, this message translates to:
  /// **'Popular on MangaDex'**
  String get discoverPopularHeader;

  /// No description provided for @discoverResultsHeader.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get discoverResultsHeader;

  /// No description provided for @discoverEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No manga found'**
  String get discoverEmptyTitle;

  /// No description provided for @discoverEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'No matching titles were found on MangaDex for your query.'**
  String get discoverEmptyDescription;

  /// No description provided for @discoverRateLimitError.
  ///
  /// In en, this message translates to:
  /// **'MangaDex rate limit reached. Please wait a moment and retry.'**
  String get discoverRateLimitError;

  /// No description provided for @discoverOfflineNotice.
  ///
  /// In en, this message translates to:
  /// **'Offline mode: showing cached results where available.'**
  String get discoverOfflineNotice;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @mangaDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Manga Details'**
  String get mangaDetailTitle;

  /// No description provided for @addToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
  String get addToLibrary;

  /// No description provided for @inLibrary.
  ///
  /// In en, this message translates to:
  /// **'In Library'**
  String get inLibrary;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get changeStatus;

  /// No description provided for @synopsisTitle.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get synopsisTitle;

  /// No description provided for @noSynopsis.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noSynopsis;

  /// No description provided for @chaptersProgressFraction.
  ///
  /// In en, this message translates to:
  /// **'Ch. {read} / {total}'**
  String chaptersProgressFraction(int read, int total);

  /// No description provided for @continueChapterLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue Ch. {chapter}'**
  String continueChapterLabel(String chapter);

  /// No description provided for @volumesAndChaptersTitle.
  ///
  /// In en, this message translates to:
  /// **'Volumes & Chapters'**
  String get volumesAndChaptersTitle;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume {number}'**
  String volumeLabel(String number);

  /// No description provided for @unassignedChaptersLabel.
  ///
  /// In en, this message translates to:
  /// **'Unassigned Chapters'**
  String get unassignedChaptersLabel;

  /// No description provided for @volumeProgressSummary.
  ///
  /// In en, this message translates to:
  /// **'{read}/{total} read'**
  String volumeProgressSummary(int read, int total);

  /// No description provided for @markVolumeReadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark volume as read'**
  String get markVolumeReadTooltip;

  /// No description provided for @markVolumeUnreadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Volume already read'**
  String get markVolumeUnreadTooltip;

  /// No description provided for @chapterLabel.
  ///
  /// In en, this message translates to:
  /// **'Ch. {number}'**
  String chapterLabel(String number);

  /// No description provided for @markPreviousReadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark previous as read'**
  String get markPreviousReadTooltip;

  /// No description provided for @openMangaDexTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open chapter on MangaDex'**
  String get openMangaDexTooltip;

  /// No description provided for @externalMangaDexHost.
  ///
  /// In en, this message translates to:
  /// **'MangaDex'**
  String get externalMangaDexHost;

  /// No description provided for @bulkReadSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark previous chapters as read?'**
  String get bulkReadSheetTitle;

  /// No description provided for @bulkReadSheetMessage.
  ///
  /// In en, this message translates to:
  /// **'Mark Ch. {chapter} and all {count} unread previous chapters as read in your library?'**
  String bulkReadSheetMessage(String chapter, int count);

  /// No description provided for @bulkReadSheetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark {count} Chapters'**
  String bulkReadSheetConfirm(int count);

  /// No description provided for @bulkReadAllAlreadyRead.
  ///
  /// In en, this message translates to:
  /// **'All previous chapters up to Ch. {chapter} are already read.'**
  String bulkReadAllAlreadyRead(String chapter);

  /// No description provided for @externalLinkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open MangaDex in external browser.'**
  String get externalLinkError;

  /// No description provided for @chapterUnavailableNotice.
  ///
  /// In en, this message translates to:
  /// **'This chapter is currently unavailable on MangaDex.'**
  String get chapterUnavailableNotice;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading History'**
  String get historyTitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reading history yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Mark a chapter or volume as read to build your reading timeline.'**
  String get historyEmptyDescription;

  /// No description provided for @historyActionChapterRead.
  ///
  /// In en, this message translates to:
  /// **'Read Chapter {chapter}'**
  String historyActionChapterRead(String chapter);

  /// No description provided for @historyActionVolumeRead.
  ///
  /// In en, this message translates to:
  /// **'Completed Volume {volume} ({count} ch.)'**
  String historyActionVolumeRead(String volume, int count);

  /// No description provided for @historyActionBulkRead.
  ///
  /// In en, this message translates to:
  /// **'Marked {count} chapters read'**
  String historyActionBulkRead(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountSection;

  /// No description provided for @settingsSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String settingsSignedInAs(String email);

  /// No description provided for @settingsReadingSection.
  ///
  /// In en, this message translates to:
  /// **'Reading Preferences'**
  String get settingsReadingSection;

  /// No description provided for @settingsUiLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsUiLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get settingsLanguageItalian;

  /// No description provided for @settingsScanlationLanguages.
  ///
  /// In en, this message translates to:
  /// **'Preferred MangaDex Languages'**
  String get settingsScanlationLanguages;

  /// No description provided for @settingsContentRatings.
  ///
  /// In en, this message translates to:
  /// **'Content Rating Filters'**
  String get settingsContentRatings;

  /// No description provided for @settingsRatingSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get settingsRatingSafe;

  /// No description provided for @settingsRatingSuggestive.
  ///
  /// In en, this message translates to:
  /// **'Suggestive'**
  String get settingsRatingSuggestive;

  /// No description provided for @settingsRatingErotica.
  ///
  /// In en, this message translates to:
  /// **'Erotica'**
  String get settingsRatingErotica;

  /// No description provided for @settingsNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsSection;

  /// No description provided for @settingsNotificationsToggle.
  ///
  /// In en, this message translates to:
  /// **'Daily New Chapter Alerts'**
  String get settingsNotificationsToggle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive push alerts when tracked series release chapters.'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsSyncTokenButton.
  ///
  /// In en, this message translates to:
  /// **'Sync Push Token Now'**
  String get settingsSyncTokenButton;

  /// No description provided for @settingsTokenSyncedMessage.
  ///
  /// In en, this message translates to:
  /// **'Device push token synced.'**
  String get settingsTokenSyncedMessage;

  /// No description provided for @settingsSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved.'**
  String get settingsSavedMessage;

  /// No description provided for @settingsSignOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOutButton;

  /// No description provided for @settingsSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Koma?'**
  String get settingsSignOutConfirmTitle;

  /// No description provided for @settingsSignOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in anytime to restore your synced library.'**
  String get settingsSignOutConfirmBody;

  /// No description provided for @genericErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get genericErrorTitle;

  /// No description provided for @discoverClearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get discoverClearSearchTooltip;

  /// No description provided for @libraryClearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search query'**
  String get libraryClearSearchTooltip;

  /// No description provided for @showPasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPasswordTooltip;

  /// No description provided for @hidePasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePasswordTooltip;

  /// No description provided for @authEmailRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get authEmailRequiredError;

  /// No description provided for @authPasswordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get authPasswordRequiredError;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// No description provided for @mangaCardSemanticsWithAuthor.
  ///
  /// In en, this message translates to:
  /// **'{title}, by {author}'**
  String mangaCardSemanticsWithAuthor(String title, String author);

  /// No description provided for @mangaCardUnreadSemantics.
  ///
  /// In en, this message translates to:
  /// **'{count} unread chapters'**
  String mangaCardUnreadSemantics(int count);

  /// No description provided for @mangaCardProgressSemantics.
  ///
  /// In en, this message translates to:
  /// **'{percent}% completed'**
  String mangaCardProgressSemantics(int percent);

  /// No description provided for @statusChipSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label} filter status'**
  String statusChipSemantics(String label);

  /// No description provided for @chapterRowMarkReadSemantics.
  ///
  /// In en, this message translates to:
  /// **'Mark Chapter {number} as read'**
  String chapterRowMarkReadSemantics(String number);

  /// No description provided for @chapterRowMarkUnreadSemantics.
  ///
  /// In en, this message translates to:
  /// **'Mark Chapter {number} as unread'**
  String chapterRowMarkUnreadSemantics(String number);

  /// No description provided for @chapterRowOpenMangaDexSemantics.
  ///
  /// In en, this message translates to:
  /// **'Open Chapter {number} on MangaDex'**
  String chapterRowOpenMangaDexSemantics(String number);

  /// No description provided for @chapterRowMarkPreviousSemantics.
  ///
  /// In en, this message translates to:
  /// **'Mark previous chapters as read up to Chapter {number}'**
  String chapterRowMarkPreviousSemantics(String number);

  /// No description provided for @chapterRowTapHint.
  ///
  /// In en, this message translates to:
  /// **'Toggle chapter read state'**
  String get chapterRowTapHint;

  /// No description provided for @chapterRowLongPressHint.
  ///
  /// In en, this message translates to:
  /// **'Mark previous chapters as read'**
  String get chapterRowLongPressHint;

  /// No description provided for @volumeTileMarkSemantics.
  ///
  /// In en, this message translates to:
  /// **'{action}: {volumeTitle}'**
  String volumeTileMarkSemantics(String action, String volumeTitle);

  /// No description provided for @progressHeaderSummary.
  ///
  /// In en, this message translates to:
  /// **'{read} of {total} chapters'**
  String progressHeaderSummary(int read, int total);

  /// No description provided for @progressHeaderSemantics.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete, {read} of {total} chapters read'**
  String progressHeaderSemantics(int percent, int read, int total);

  /// No description provided for @progressHeaderCoverSemantics.
  ///
  /// In en, this message translates to:
  /// **'Cover art for {title}'**
  String progressHeaderCoverSemantics(String title);

  /// No description provided for @homeQuickMarkReadLabel.
  ///
  /// In en, this message translates to:
  /// **'Read Ch. {chapter}'**
  String homeQuickMarkReadLabel(String chapter);

  /// No description provided for @homeQuickMarkReadSemantics.
  ///
  /// In en, this message translates to:
  /// **'Read Ch. {chapter}, mark {title} chapter {chapter} as read'**
  String homeQuickMarkReadSemantics(String title, String chapter);

  /// No description provided for @homeQuickMarkReadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Marked {title} Ch. {chapter} as read'**
  String homeQuickMarkReadSuccess(String title, String chapter);

  /// No description provided for @detailQuickMarkLatestLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark Ch. {chapter} as read'**
  String detailQuickMarkLatestLabel(String chapter);

  /// No description provided for @detailQuickMarkLatestSemantics.
  ///
  /// In en, this message translates to:
  /// **'Mark Ch. {chapter} as read, latest unread chapter of {title}'**
  String detailQuickMarkLatestSemantics(String chapter, String title);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
