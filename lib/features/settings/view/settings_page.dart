import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koma/features/settings/bloc/settings_cubit.dart';
import 'package:koma/features/settings/bloc/settings_state.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:library_repository/library_repository.dart';
import 'package:notifications_repository/notifications_repository.dart';

/// Page displaying application settings, preferences, and account management.
class SettingsPage extends StatelessWidget {
  /// Creates a [SettingsPage].
  const new({
    required this.uid,
    this.userEmail,
    this.displayName,
    this.photoUrl,
    this.isEmulatorMode = false,
    this.deviceId = 'device-1',
    this.platform,
    super.key,
  });

  /// The user ID whose preferences are displayed and edited.
  final String uid;

  /// Optional email address for user identification fallback.
  final String? userEmail;

  /// Optional display name.
  final String? displayName;

  /// Optional photo URL.
  final String? photoUrl;

  /// Whether running in Firebase emulator mode.
  final bool isEmulatorMode;

  /// Client device identifier for push notification tokens.
  final String deviceId;

  /// Client platform identifier (`'android'` or `'ios'`).
  final String? platform;

  @override
  Widget build(BuildContext context) {
    final effectivePlatform =
        platform ??
        (Theme.of(context).platform == TargetPlatform.iOS ? 'ios' : 'android');

    return BlocProvider(
      create: (context) => SettingsCubit(
        libraryRepository: context.read<LibraryRepository>(),
        authRepository: context.read<AuthRepository>(),
        notificationsRepository: context.read<NotificationsRepository>(),
        uid: uid,
        email: userEmail,
        displayName: displayName,
        photoUrl: photoUrl,
        isEmulatorMode: isEmulatorMode,
        deviceId: deviceId,
        platform: effectivePlatform,
      ),
      child: const SettingsView(),
    );
  }
}

/// View rendering settings categories for account, reading preferences,
/// notifications, and sign-out.
class SettingsView extends StatelessWidget {
  /// Creates a [SettingsView].
  const new({super.key});

  void _showSignOutDialog(BuildContext context) {
    final l10n = context.l10n;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: Text(l10n.settingsSignOutConfirmTitle),
          content: Text(l10n.settingsSignOutConfirmBody),
          actions: [
            TextButton(
              key: const Key('settings_sign_out_cancel_button'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              key: const Key('settings_sign_out_confirm_button'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                unawaited(context.read<SettingsCubit>().signOut());
              },
              child: Text(l10n.confirmAction),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colorScheme;
    final spacing = context.komaSpacing;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          } else if (state.infoMessage != null) {
            final String message;
            if (state.infoMessage == 'settingsTokenSyncedMessage') {
              message = l10n.settingsTokenSyncedMessage;
            } else {
              message = l10n.settingsSavedMessage;
            }

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(message),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            context.read<SettingsCubit>().clearInfoMessage();
          }
        },
        builder: (context, state) {
          if (state.status == SettingsStatus.loading && state.profile == null) {
            return Center(
              child: CircularProgressIndicator.adaptive(
                semanticsLabel: l10n.loadingLabel,
              ),
            );
          }

          if (state.status == SettingsStatus.failure && state.profile == null) {
            return Center(
              child: KomaEmptyState(
                title: l10n.genericErrorTitle,
                description: state.errorMessage ?? '',
                fallbackIcon: Icons.error_outline_rounded,
              ),
            );
          }

          final profile = state.profile;
          final candidateEmail =
              profile?.email ??
              context.read<AuthRepository>().currentUser.email;
          final currentEmail =
              (candidateEmail != null && candidateEmail.isNotEmpty)
              ? candidateEmail
              : 'test@mangatracker.local';

          return ListView(
            padding: EdgeInsetsDirectional.only(
              start: spacing.md,
              end: spacing.md,
              top: spacing.sm,
              bottom: spacing.xlg,
            ),
            children: [
              // ===============================================================
              // Account Section
              // ===============================================================
              Semantics(
                header: true,
                child: Text(
                  l10n.settingsAccountSection,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: spacing.xs),
              Card(
                margin: EdgeInsetsDirectional.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusDirectional.circular(12)
                      .resolve(Directionality.of(context)),
                  side: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.all(spacing.md),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: colors.primaryContainer,
                          child: Icon(
                            Icons.person_rounded,
                            color: colors.onPrimaryContainer,
                            size: 28,
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (profile?.displayName != null &&
                                profile!.displayName!.isNotEmpty) ...[
                              Text(
                                profile.displayName!,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: spacing.xxs),
                            ],
                            Text(
                              l10n.settingsSignedInAs(currentEmail),
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: spacing.lg),

              // ===============================================================
              // Reading Preferences Section
              // ===============================================================
              Semantics(
                header: true,
                child: Text(
                  l10n.settingsReadingSection,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: spacing.xs),
              Card(
                margin: EdgeInsetsDirectional.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusDirectional.circular(12)
                      .resolve(Directionality.of(context)),
                  side: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.all(spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preferred Scanlation Languages
                      Text(
                        l10n.settingsScanlationLanguages,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spacing.xs),
                      Wrap(
                        spacing: spacing.xs,
                        runSpacing: spacing.xs,
                        children: [
                          _LanguageFilterChip(
                            label: l10n.settingsLanguageEnglish,
                            languageCode: 'en',
                            isSelected:
                                profile?.preferredLanguages.contains('en') ??
                                true,
                            onSelected: () => unawaited(
                              context
                                  .read<SettingsCubit>()
                                  .togglePreferredLanguage('en'),
                            ),
                          ),
                          _LanguageFilterChip(
                            label: l10n.settingsLanguageItalian,
                            languageCode: 'it',
                            isSelected:
                                profile?.preferredLanguages.contains('it') ??
                                true,
                            onSelected: () => unawaited(
                              context
                                  .read<SettingsCubit>()
                                  .togglePreferredLanguage('it'),
                            ),
                          ),
                          _LanguageFilterChip(
                            label: '日本語 (ja)',
                            semanticsLabel: 'Japanese, ja',
                            languageCode: 'ja',
                            isSelected:
                                profile?.preferredLanguages.contains('ja') ??
                                false,
                            onSelected: () => unawaited(
                              context
                                  .read<SettingsCubit>()
                                  .togglePreferredLanguage('ja'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.md),
                      const Divider(),
                      SizedBox(height: spacing.sm),

                      // Content Ratings
                      Text(
                        l10n.settingsContentRatings,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spacing.xs),
                      Wrap(
                        spacing: spacing.xs,
                        runSpacing: spacing.xs,
                        children: [
                          _RatingFilterChip(
                            label: l10n.settingsRatingSafe,
                            ratingCode: 'safe',
                            isSelected:
                                profile?.contentRatings.contains('safe') ??
                                true,
                            onSelected: () => unawaited(
                              context.read<SettingsCubit>().toggleContentRating(
                                'safe',
                              ),
                            ),
                          ),
                          _RatingFilterChip(
                            label: l10n.settingsRatingSuggestive,
                            ratingCode: 'suggestive',
                            isSelected:
                                profile?.contentRatings.contains(
                                  'suggestive',
                                ) ??
                                true,
                            onSelected: () => unawaited(
                              context.read<SettingsCubit>().toggleContentRating(
                                'suggestive',
                              ),
                            ),
                          ),
                          _RatingFilterChip(
                            label: l10n.settingsRatingErotica,
                            ratingCode: 'erotica',
                            isSelected:
                                profile?.contentRatings.contains('erotica') ??
                                false,
                            onSelected: () => unawaited(
                              context.read<SettingsCubit>().toggleContentRating(
                                'erotica',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: spacing.lg),

              // ===============================================================
              // Notifications Section
              // ===============================================================
              Semantics(
                header: true,
                child: Text(
                  l10n.settingsNotificationsSection,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: spacing.xs),
              Card(
                margin: EdgeInsetsDirectional.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusDirectional.circular(12)
                      .resolve(Directionality.of(context)),
                  side: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.all(spacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsetsDirectional.symmetric(
                          horizontal: spacing.sm,
                        ),
                        title: Text(l10n.settingsNotificationsToggle),
                        subtitle: Text(l10n.settingsNotificationsSubtitle),
                        value: profile?.notificationsEnabled ?? true,
                        onChanged: (enabled) {
                          unawaited(
                            context
                                .read<SettingsCubit>()
                                .setNotificationsEnabled(enabled),
                          );
                        },
                      ),
                      SizedBox(height: spacing.xs),
                      Padding(
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: spacing.sm,
                        ),
                        child: OutlinedButton.icon(
                          key: const Key('settings_sync_token_button'),
                          onPressed: state.isSyncingToken
                              ? null
                              : () => unawaited(
                                  context
                                      .read<SettingsCubit>()
                                      .syncPushTokenNow(),
                                ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              kKomaMinTouchTarget,
                            ),
                          ),
                          icon: state.isSyncingToken
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                    semanticsLabel: l10n.loadingLabel,
                                  ),
                                )
                              : const Icon(Icons.sync_rounded),
                          label: Text(l10n.settingsSyncTokenButton),
                        ),
                      ),
                      SizedBox(height: spacing.xs),
                    ],
                  ),
                ),
              ),
              SizedBox(height: spacing.xlg),

              // ===============================================================
              // Sign Out Section
              // ===============================================================
              FilledButton.tonalIcon(
                key: const Key('settings_sign_out_button'),
                onPressed: state.isSigningOut
                    ? null
                    : () => _showSignOutDialog(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(kKomaMinTouchTarget),
                  backgroundColor: colors.errorContainer,
                  foregroundColor: colors.onErrorContainer,
                ),
                icon: state.isSigningOut
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          semanticsLabel: l10n.loadingLabel,
                        ),
                      )
                    : const Icon(Icons.logout_rounded),
                label: Text(l10n.settingsSignOutButton),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageFilterChip extends StatelessWidget {
  const new({
    required this.label,
    required this.languageCode,
    required this.isSelected,
    required this.onSelected,
    this.semanticsLabel,
  });

  final String label;
  final String languageCode;
  final bool isSelected;
  final VoidCallback onSelected;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(label);
    final labelWidget = semanticsLabel != null
        ? Semantics(
            label: semanticsLabel,
            excludeSemantics: true,
            child: textWidget,
          )
        : textWidget;

    return FilterChip(
      key: Key('settings_lang_chip_$languageCode'),
      label: labelWidget,
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _RatingFilterChip extends StatelessWidget {
  const new({
    required this.label,
    required this.ratingCode,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final String ratingCode;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      key: Key('settings_rating_chip_$ratingCode'),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}
