import 'package:flutter/widgets.dart';
import 'package:koma/l10n/gen/app_localizations.dart';

export 'package:koma/l10n/gen/app_localizations.dart';

/// Localization extension helper on [BuildContext].
extension AppLocalizationsX on BuildContext {
  /// Returns the active [AppLocalizations] instance for this context.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
