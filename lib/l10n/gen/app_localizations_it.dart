// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Koma';

  @override
  String get appTagline => 'Il tuo tracker offline-first per i manga';

  @override
  String get loginTitle => 'Accedi a Koma';

  @override
  String get signUpTitle => 'Crea account Koma';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get displayNameLabel => 'Nome visualizzato (opzionale)';

  @override
  String get signInButton => 'Accedi';

  @override
  String get signUpButton => 'Registrati';

  @override
  String get switchToSignUp => 'Nuovo su Koma? Crea un account';

  @override
  String get switchToSignIn => 'Hai già un account? Accedi';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get devQuickLoginButton => 'Accesso Account Test QA';

  @override
  String get authInvalidCredentialsError => 'Email o password non validi.';

  @override
  String get authEmailAlreadyInUseError =>
      'Esiste già un account con questa email.';

  @override
  String get authWeakPasswordError =>
      'La password deve contenere almeno 6 caratteri.';

  @override
  String get authNetworkError =>
      'Errore di rete. Controlla la connessione e riprova.';

  @override
  String get authGoogleCancelledError => 'Accesso con Google annullato.';

  @override
  String get authUnknownError => 'Autenticazione non riuscita. Riprova.';

  @override
  String get navLibrary => 'Libreria';

  @override
  String get navDiscover => 'Scopri';

  @override
  String get navHistory => 'Cronologia';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get statusAll => 'Tutti';

  @override
  String get statusReading => 'In lettura';

  @override
  String get statusPlanToRead => 'Da leggere';

  @override
  String get statusCompleted => 'Completato';

  @override
  String get statusOnHold => 'In pausa';

  @override
  String get statusDropped => 'Abbandonato';

  @override
  String get libraryTitle => 'Libreria';

  @override
  String get homeSectionToRead => 'Da leggere';

  @override
  String get homeSectionCaughtUp => 'In pari';

  @override
  String get homeSectionFinished => 'In pausa / Completati';

  @override
  String get homeUpToDateTitle => 'Tutto in pari!';

  @override
  String get homeUpToDateDescription => 'Hai letto tutti i capitoli usciti';

  @override
  String get homeUpToDateAction => 'Scopri nuovi Manga';

  @override
  String get markAllCaughtUpAction =>
      'Segna tutti i capitoli usciti come letti';

  @override
  String sectionCollapseSemantics(String section) {
    return 'Espandi o comprimi sezione $section';
  }

  @override
  String get librarySearchHint => 'Filtra libreria...';

  @override
  String get libraryEmptyTitle => 'La tua libreria è vuota';

  @override
  String get libraryEmptyDescription =>
      'Cerca su MangaDex per tracciare capitoli, volumi e progressi di lettura.';

  @override
  String get libraryEmptyAction => 'Scopri Manga';

  @override
  String get libraryFilterEmptyTitle => 'Nessun titolo corrisponde al filtro';

  @override
  String get libraryFilterEmptyDescription =>
      'Prova a rimuovere la ricerca o a scegliere un altro stato.';

  @override
  String get libraryClearFilters => 'Ripristina filtri';

  @override
  String libraryUnreadChapters(int count) {
    return '$count non letti';
  }

  @override
  String chaptersReadProgress(String chapter) {
    return 'Cap. $chapter';
  }

  @override
  String get removeFromLibrary => 'Rimuovi dalla libreria';

  @override
  String get removeFromLibraryConfirmTitle => 'Rimuovere dalla libreria?';

  @override
  String get removeFromLibraryConfirmBody =>
      'Il manga e i relativi progressi verranno rimossi dalla libreria. La cronologia resterà invariata.';

  @override
  String get cancelAction => 'Annulla';

  @override
  String get confirmAction => 'Conferma';

  @override
  String get removeAction => 'Rimuovi';

  @override
  String get discoverTitle => 'Scopri';

  @override
  String get discoverSearchHint => 'Cerca titoli manga su MangaDex...';

  @override
  String get discoverPopularHeader => 'Popolari su MangaDex';

  @override
  String get discoverResultsHeader => 'Risultati di ricerca';

  @override
  String get discoverEmptyTitle => 'Nessun manga trovato';

  @override
  String get discoverEmptyDescription =>
      'Nessun titolo trovato su MangaDex per la tua ricerca.';

  @override
  String get discoverRateLimitError =>
      'Limite richieste MangaDex raggiunto. Attendi un istante e riprova.';

  @override
  String get discoverOfflineNotice =>
      'Modalità offline: risultati salvati nella cache locale.';

  @override
  String get retryAction => 'Riprova';

  @override
  String get refreshTooltip => 'Aggiorna';

  @override
  String get mangaDetailTitle => 'Dettagli Manga';

  @override
  String get addToLibrary => 'Aggiungi alla libreria';

  @override
  String get inLibrary => 'In libreria';

  @override
  String get changeStatus => 'Cambia stato';

  @override
  String get synopsisTitle => 'Sinossi';

  @override
  String get noSynopsis => 'Nessuna descrizione disponibile.';

  @override
  String chaptersProgressFraction(int read, int total) {
    return 'Cap. $read / $total';
  }

  @override
  String continueChapterLabel(String chapter) {
    return 'Continua Cap. $chapter';
  }

  @override
  String get volumesAndChaptersTitle => 'Volumi e Capitoli';

  @override
  String volumeLabel(String number) {
    return 'Volume $number';
  }

  @override
  String get unassignedChaptersLabel => 'Capitoli non assegnati';

  @override
  String volumeProgressSummary(int read, int total) {
    return '$read/$total letti';
  }

  @override
  String get markVolumeReadTooltip => 'Segna volume come letto';

  @override
  String get markVolumeUnreadTooltip => 'Volume già letto';

  @override
  String chapterLabel(String number) {
    return 'Cap. $number';
  }

  @override
  String get markPreviousReadTooltip => 'Segna precedenti come letti';

  @override
  String get openMangaDexTooltip => 'Apri capitolo su MangaDex';

  @override
  String get externalMangaDexHost => 'MangaDex';

  @override
  String get bulkReadSheetTitle => 'Segnare i capitoli precedenti come letti?';

  @override
  String bulkReadSheetMessage(String chapter, int count) {
    return 'Vuoi segnare il Cap. $chapter e tutti i $count capitoli precedenti non letti come letti?';
  }

  @override
  String bulkReadSheetConfirm(int count) {
    return 'Segna $count Capitoli';
  }

  @override
  String bulkReadAllAlreadyRead(String chapter) {
    return 'Tutti i capitoli precedenti fino al Cap. $chapter sono già stati letti.';
  }

  @override
  String get externalLinkError =>
      'Impossibile aprire MangaDex nel browser esterno.';

  @override
  String get chapterUnavailableNotice =>
      'Questo capitolo non è al momento disponibile su MangaDex.';

  @override
  String get historyTitle => 'Cronologia';

  @override
  String get historyEmptyTitle => 'Nessuna attività recente';

  @override
  String get historyEmptyDescription =>
      'Segna un capitolo o un volume come letto per creare la cronologia.';

  @override
  String historyActionChapterRead(String chapter) {
    return 'Letto Capitolo $chapter';
  }

  @override
  String historyActionVolumeRead(String volume, int count) {
    return 'Completato Volume $volume ($count cap.)';
  }

  @override
  String historyActionBulkRead(int count) {
    return 'Segnati $count capitoli come letti';
  }

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String settingsSignedInAs(String email) {
    return 'Connesso come $email';
  }

  @override
  String get settingsReadingSection => 'Preferenze di lettura';

  @override
  String get settingsUiLanguage => 'Lingua app';

  @override
  String get settingsLanguageEnglish => 'Inglese';

  @override
  String get settingsLanguageItalian => 'Italiano';

  @override
  String get settingsScanlationLanguages => 'Lingue traduzione preferite';

  @override
  String get settingsContentRatings => 'Filtri classificazione contenuti';

  @override
  String get settingsRatingSafe => 'Sicuro';

  @override
  String get settingsRatingSuggestive => 'Suggestivo';

  @override
  String get settingsRatingErotica => 'Erotico';

  @override
  String get settingsNotificationsSection => 'Notifiche';

  @override
  String get settingsNotificationsToggle => 'Avvisi giornalieri nuovi capitoli';

  @override
  String get settingsNotificationsSubtitle =>
      'Ricevi notifiche push quando escono nuovi capitoli.';

  @override
  String get settingsSyncTokenButton => 'Sincronizza token notifiche';

  @override
  String get settingsTokenSyncedMessage =>
      'Token notifiche dispositivo sincronizzato.';

  @override
  String get settingsSavedMessage => 'Preferenze salvate.';

  @override
  String get settingsSignOutButton => 'Disconnetti';

  @override
  String get settingsSignOutConfirmTitle => 'Disconnettersi da Koma?';

  @override
  String get settingsSignOutConfirmBody =>
      'Potrai accedere nuovamente in qualsiasi momento per ripristinare la tua libreria.';

  @override
  String get genericErrorTitle => 'Si è verificato un errore';

  @override
  String get discoverClearSearchTooltip => 'Cancella ricerca';

  @override
  String get libraryClearSearchTooltip => 'Cancella testo di ricerca';

  @override
  String get showPasswordTooltip => 'Mostra password';

  @override
  String get hidePasswordTooltip => 'Nascondi password';

  @override
  String get authEmailRequiredError => 'Inserisci il tuo indirizzo email.';

  @override
  String get authPasswordRequiredError => 'Inserisci la password.';

  @override
  String get loadingLabel => 'Caricamento...';

  @override
  String mangaCardSemanticsWithAuthor(String title, String author) {
    return '$title, di $author';
  }

  @override
  String mangaCardUnreadSemantics(int count) {
    return '$count capitoli non letti';
  }

  @override
  String mangaCardProgressSemantics(int percent) {
    return '$percent% completato';
  }

  @override
  String statusChipSemantics(String label) {
    return 'Filtro stato $label';
  }

  @override
  String chapterRowMarkReadSemantics(String number) {
    return 'Segna Capitolo $number come letto';
  }

  @override
  String chapterRowMarkUnreadSemantics(String number) {
    return 'Segna Capitolo $number come non letto';
  }

  @override
  String chapterRowOpenMangaDexSemantics(String number) {
    return 'Apri Capitolo $number su MangaDex';
  }

  @override
  String chapterRowMarkPreviousSemantics(String number) {
    return 'Segna i capitoli precedenti fino al Capitolo $number come letti';
  }

  @override
  String get chapterRowTapHint => 'Attiva o disattiva stato letto del capitolo';

  @override
  String get chapterRowLongPressHint =>
      'Segna i capitoli precedenti come letti';

  @override
  String volumeTileMarkSemantics(String action, String volumeTitle) {
    return '$action: $volumeTitle';
  }

  @override
  String progressHeaderSummary(int read, int total) {
    return '$read di $total capitoli';
  }

  @override
  String progressHeaderSemantics(int percent, int read, int total) {
    return '$percent% completato, $read di $total capitoli letti';
  }

  @override
  String progressHeaderCoverSemantics(String title) {
    return 'Copertina di $title';
  }

  @override
  String homeQuickMarkReadLabel(String chapter) {
    return 'Letto Cap. $chapter';
  }

  @override
  String homeQuickMarkReadSemantics(String title, String chapter) {
    return 'Letto Cap. $chapter, segna capitolo $chapter di $title come letto';
  }

  @override
  String homeQuickMarkReadSuccess(String title, String chapter) {
    return 'Segnato $title Cap. $chapter come letto';
  }

  @override
  String detailQuickMarkLatestLabel(String chapter) {
    return 'Segna Cap. $chapter come letto';
  }

  @override
  String detailQuickMarkLatestSemantics(String chapter, String title) {
    return 'Segna Cap. $chapter come letto, ultimo capitolo non letto di $title';
  }
}
