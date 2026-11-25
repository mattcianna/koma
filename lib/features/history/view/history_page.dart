import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:koma/features/history/bloc/history_cubit.dart';
import 'package:koma/features/history/bloc/history_state.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:library_repository/library_repository.dart';

/// Page displaying a chronological feed of user reading history events.
class HistoryPage extends StatelessWidget {
  /// Creates a [HistoryPage].
  const new({required this.uid, this.onMangaTap, super.key});

  /// The user ID whose reading history is displayed.
  final String uid;

  /// Callback executed when a manga item is tapped in the history feed.
  final ValueChanged<String>? onMangaTap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HistoryCubit(
        libraryRepository: context.read<LibraryRepository>(),
        uid: uid,
      ),
      child: HistoryView(onMangaTap: onMangaTap),
    );
  }
}

/// View rendering the reading history list, empty state, or loading indicator.
class HistoryView extends StatelessWidget {
  /// Creates a [HistoryView].
  const new({this.onMangaTap, super.key});

  /// Optional callback executed when a manga item is tapped.
  final ValueChanged<String>? onMangaTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.komaSpacing;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          switch (state.status) {
            case HistoryStatus.initial:
            case HistoryStatus.loading:
              return Center(
                child: CircularProgressIndicator.adaptive(
                  semanticsLabel: l10n.loadingLabel,
                ),
              );
            case HistoryStatus.failure:
              return Center(
                child: KomaEmptyState(
                  title: l10n.genericErrorTitle,
                  description: state.errorMessage ?? '',
                  fallbackIcon: Icons.error_outline_rounded,
                  actionLabel: l10n.retryAction,
                  onActionPressed: () => context.read<HistoryCubit>().refresh(),
                ),
              );
            case HistoryStatus.loaded:
              if (state.events.isEmpty) {
                return Center(
                  child: KomaEmptyState(
                    title: l10n.historyEmptyTitle,
                    description: l10n.historyEmptyDescription,
                    fallbackIcon: Icons.history_rounded,
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsetsDirectional.only(
                  start: spacing.md,
                  end: spacing.md,
                  top: spacing.sm,
                  bottom: spacing.xlg,
                ),
                itemCount: state.events.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: spacing.sm),
                itemBuilder: (context, index) {
                  final event = state.events[index];
                  return _HistoryEventCard(
                    event: event,
                    onTap: () {
                      if (onMangaTap != null) {
                        onMangaTap!(event.mangaId);
                      } else {
                        unawaited(context.push('/manga/${event.mangaId}'));
                      }
                    },
                  );
                },
              );
          }
        },
      ),
    );
  }
}

class _HistoryEventCard extends StatelessWidget {
  const new({required this.event, required this.onTap});

  final ReadingHistoryEvent event;
  final VoidCallback onTap;

  String _formatActionDescription(BuildContext context) {
    final l10n = context.l10n;
    switch (event.actionType) {
      case ReadingHistoryActionType.chapterRead:
        final chapter = event.chapterNumbers.isNotEmpty
            ? event.chapterNumbers.first
            : '';
        return l10n.historyActionChapterRead(chapter);
      case ReadingHistoryActionType.volumeRead:
        final volume = event.volumeNumber ?? '';
        return l10n.historyActionVolumeRead(volume, event.chaptersCount);
      case ReadingHistoryActionType.bulkPreviousRead:
        return l10n.historyActionBulkRead(event.chaptersCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final spacing = context.komaSpacing;
    final actionDescription = _formatActionDescription(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final formattedDate = DateFormat.yMMMd(localeTag)
        .add_jm()
        .format(event.timestamp.toLocal());
    final semanticsLabel =
        '${event.mangaTitle}, $actionDescription, $formattedDate';

    final coverFileName = event.coverFileName;
    final coverUrl = (coverFileName != null && coverFileName.isNotEmpty)
        ? 'https://uploads.mangadex.org/covers/${event.mangaId}/$coverFileName.256.jpg'
        : null;

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsetsDirectional.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.circular(12)
              .resolve(Directionality.of(context)),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kKomaMinTouchTarget),
            child: Padding(
              padding: EdgeInsetsDirectional.all(spacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HistoryCoverThumbnail(coverUrl: coverUrl),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.mangaTitle,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: spacing.xxs),
                        Text(
                          actionDescription,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                        SizedBox(height: spacing.xxs),
                        Text(
                          formattedDate,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCoverThumbnail extends StatelessWidget {
  const new({required this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final l10n = context.l10n;

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadiusDirectional.circular(8)
            .resolve(Directionality.of(context)),
        child: SizedBox(
          width: 52,
          height: 72,
          child: coverUrl != null
              ? Image.network(
                  coverUrl!,
                  headers: kKomaUserAgentHeaders,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return ColoredBox(
                      color: colors.surfaceContainer,
                      child: Center(
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          semanticsLabel: l10n.loadingLabel,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: colors.surfaceContainerHigh,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: colors.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                )
              : ColoredBox(
                  color: colors.surfaceContainer,
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: colors.onSurfaceVariant,
                    size: 24,
                  ),
                ),
        ),
      ),
    );
  }
}
