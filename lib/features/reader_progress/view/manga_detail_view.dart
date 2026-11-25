import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koma/features/library/models/library_helpers.dart';
import 'package:koma/features/reader_progress/bloc/manga_detail_bloc.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';
import 'package:url_launcher/url_launcher.dart';

Color _getStatusColor(KomaColors colors, ReadingStatus status) {
  switch (status) {
    case ReadingStatus.reading:
      return colors.reading;
    case ReadingStatus.planToRead:
      return colors.planToRead;
    case ReadingStatus.completed:
      return colors.completed;
    case ReadingStatus.onHold:
      return colors.onHold;
    case ReadingStatus.dropped:
      return colors.dropped;
  }
}

/// Presentation component for Manga details, volume/chapter accordion,
/// and reading progress.
class MangaDetailView extends StatelessWidget {
  /// Creates a [MangaDetailView].
  const new({
    this.highlightChapter,
    this.urlLauncher,
    this.onBackFallback,
    super.key,
  });

  /// Optional chapter number to automatically expand and highlight.
  final String? highlightChapter;

  /// Optional launcher function for testing URL dispatch.
  final Future<bool> Function(Uri uri)? urlLauncher;

  /// Optional fallback callback when navigating back on a cold deep link.
  final VoidCallback? onBackFallback;

  void _showStatusSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          message,
          Directionality.of(context),
        ),
      );
    }
  }

  Future<void> _openChapter(BuildContext context, MangaChapter chapter) async {
    final l10n = context.l10n;
    final external = chapter.externalUrl;
    final hasExternal = external != null && external.isNotEmpty;
    if (!hasExternal && (chapter.isUnavailable || chapter.id.isEmpty)) {
      _showStatusSnackBar(context, l10n.chapterUnavailableNotice);
      return;
    }

    final uri = Uri.parse(
      hasExternal ? external : 'https://mangadex.org/chapter/${chapter.id}',
    );
    try {
      final launched =
          await (urlLauncher?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!launched && context.mounted) {
        _showStatusSnackBar(context, l10n.externalLinkError);
      }
    } on Object catch (_) {
      if (context.mounted) {
        _showStatusSnackBar(context, l10n.externalLinkError);
      }
    }
  }

  void _showStatusPicker(BuildContext context, MangaDetailState state) {
    final l10n = context.l10n;
    final colors = context.colorScheme;
    final bloc = context.read<MangaDetailBloc>();

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.vertical(
            top: Radius.circular(24),
          ),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(
                        state.isInLibrary
                            ? l10n.changeStatus
                            : l10n.addToLibrary,
                        style: sheetContext.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  for (final status in ReadingStatus.values) ...[
                    Builder(
                      builder: (tileContext) {
                        final isSelected = state.libraryEntry?.status == status;
                        final statusColor = _getStatusColor(
                          tileContext.komaColors,
                          status,
                        );
                        final statusLabel = localizedReadingStatus(
                          l10n,
                          status,
                        );

                        return ListTile(
                          selected: isSelected,
                          leading: ExcludeSemantics(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          title: Text(statusLabel),
                          trailing: isSelected
                              ? ExcludeSemantics(
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: colors.primary,
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            bloc.add(MangaDetailStatusChanged(status));
                          },
                        );
                      },
                    ),
                  ],
                  if (state.aggregate != null &&
                      state.unreadChaptersCount > 0) ...[
                    const Divider(),
                    ListTile(
                      key: const Key('manga_detail_catch_up_tile'),
                      leading: Icon(
                        Icons.done_all_rounded,
                        color: colors.primary,
                      ),
                      title: Text(l10n.markAllCaughtUpAction),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        bloc.add(const MangaDetailCatchUpRequested());
                      },
                    ),
                  ],
                  if (state.isInLibrary) ...[
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: colors.error,
                      ),
                      title: Text(
                        l10n.removeFromLibrary,
                        style: TextStyle(color: colors.error),
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _showRemoveConfirmation(context, bloc);
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context, MangaDetailBloc bloc) {
    final l10n = context.l10n;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            scrollable: true,
            title: Text(l10n.removeFromLibraryConfirmTitle),
            content: Text(l10n.removeFromLibraryConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancelAction),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  bloc.add(const MangaDetailRemovedFromLibrary());
                },
                child: Text(l10n.removeAction),
              ),
            ],
          );
        },
      ),
    );
  }

  int _resolveDefaultExpandedVolumeIndex(
    List<MangaVolume> volumes,
    LibraryEntry? libraryEntry,
  ) {
    if (volumes.isEmpty) return -1;
    if (libraryEntry != null) {
      for (var i = 0; i < volumes.length; i++) {
        final hasUnread = volumes[i].chapters.any(
          (c) => !libraryEntry.isChapterRead(c.chapterNumber),
        );
        if (hasUnread) return i;
      }
    }
    return 0;
  }

  MangaChapter? _findLatestUnreadChapter(
    ChapterAggregate aggregate,
    LibraryEntry libraryEntry,
  ) {
    final chapters = aggregate.orderedChapters;
    for (var i = chapters.length - 1; i >= 0; i--) {
      final chapter = chapters[i];
      if (chapter.chapterNumber != 'none' &&
          !libraryEntry.isChapterRead(chapter.chapterNumber)) {
        return chapter;
      }
    }
    for (var i = chapters.length - 1; i >= 0; i--) {
      final chapter = chapters[i];
      if (!libraryEntry.isChapterRead(chapter.chapterNumber)) {
        return chapter;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiBlocListener(
      listeners: [
        BlocListener<MangaDetailBloc, MangaDetailState>(
          listenWhen: (previous, current) =>
              previous.status == MangaDetailStatus.success &&
              previous.readChaptersCount != current.readChaptersCount,
          listener: (context, state) {
            final read = state.readChaptersCount;
            final total = state.totalChaptersCount;
            final percent = total > 0
                ? ((read / total) * 100).clamp(0, 100).toInt()
                : (state.libraryEntry?.status == ReadingStatus.completed
                      ? 100
                      : 0);
            final message = l10n.progressHeaderSemantics(percent, read, total);
            unawaited(
              SemanticsService.sendAnnouncement(
                View.of(context),
                message,
                Directionality.of(context),
              ),
            );
          },
        ),
        BlocListener<MangaDetailBloc, MangaDetailState>(
          listenWhen: (previous, current) =>
              previous.pendingBulkChapter != current.pendingBulkChapter &&
              current.pendingBulkChapter != null,
          listener: (context, state) {
            final target = state.pendingBulkChapter;
            if (target == null) return;

            if (state.pendingBulkUnreadChapters.isEmpty) {
              _showStatusSnackBar(
                context,
                l10n.bulkReadAllAlreadyRead(target.chapterNumber),
              );
              context.read<MangaDetailBloc>().add(
                const MangaDetailBulkPreviousDismissed(),
              );
              return;
            }

            final count = state.pendingBulkUnreadChapters.length;
            unawaited(
              KomaBulkReadSheet.show(
                context,
                targetChapterNumber: target.chapterNumber,
                affectedCount: count,
                isLoading: state.isBulkActionLoading,
                loadingSemanticsLabel: l10n.loadingLabel,
                titleText: l10n.bulkReadSheetTitle,
                messageText: l10n.bulkReadSheetMessage(
                  target.chapterNumber,
                  count,
                ),
                confirmButtonText: l10n.bulkReadSheetConfirm(count),
                cancelButtonText: l10n.cancelAction,
                onConfirm: () {
                  Navigator.of(context).pop();
                  context.read<MangaDetailBloc>().add(
                    const MangaDetailBulkPreviousConfirmed(),
                  );
                },
                onCancel: () {
                  Navigator.of(context).pop();
                  context.read<MangaDetailBloc>().add(
                    const MangaDetailBulkPreviousDismissed(),
                  );
                },
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<MangaDetailBloc, MangaDetailState>(
        builder: (context, state) {
          final leadingButton =
              !Navigator.of(context).canPop() && onBackFallback != null
              ? BackButton(onPressed: onBackFallback)
              : null;

          if (state.status == MangaDetailStatus.loading &&
              state.manga == null) {
            return Scaffold(
              appBar: AppBar(
                leading: leadingButton,
                title: Text(l10n.mangaDetailTitle),
              ),
              body: Center(
                child: CircularProgressIndicator.adaptive(
                  semanticsLabel: l10n.loadingLabel,
                ),
              ),
            );
          }

          if (state.status == MangaDetailStatus.failure &&
              state.manga == null) {
            return Scaffold(
              appBar: AppBar(
                leading: leadingButton,
                title: Text(l10n.mangaDetailTitle),
              ),
              body: KomaEmptyState(
                title: l10n.genericErrorTitle,
                description: state.errorMessage ?? '',
                actionLabel: l10n.retryAction,
                onActionPressed: () {
                  context.read<MangaDetailBloc>().add(
                    MangaDetailStarted(
                      mangaId: state.mangaId,
                      uid: state.uid,
                      preferredLocales: state.preferredLocales,
                      translatedLanguages: state.translatedLanguages,
                    ),
                  );
                },
              ),
            );
          }

          final manga = state.manga;
          final aggregate = state.aggregate;
          final libraryEntry = state.libraryEntry;

          final continueChapterNum =
              libraryEntry?.lastReadChapter ??
              aggregate?.orderedChapters.firstOrNull?.chapterNumber;

          return Scaffold(
            appBar: AppBar(
              leading: leadingButton,
              title: Text(manga?.title ?? l10n.mangaDetailTitle),
              actions: [
                IconButton(
                  key: const Key('manga_detail_refresh_button'),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: l10n.refreshTooltip,
                  onPressed: () {
                    context.read<MangaDetailBloc>().add(
                      const MangaDetailRefreshed(),
                    );
                  },
                ),
              ],
            ),
            body: RefreshIndicator.adaptive(
              onRefresh: () async {
                context.read<MangaDetailBloc>().add(
                  const MangaDetailRefreshed(),
                );
              },
              child: ListView(
                padding: const EdgeInsetsDirectional.all(16),
                children: [
                  if (manga != null) ...[
                    Builder(
                      builder: (headerContext) {
                        final readCount = state.readChaptersCount;
                        final totalCount = state.totalChaptersCount;
                        final percent = totalCount > 0
                            ? ((readCount / totalCount) * 100)
                                  .clamp(0, 100)
                                  .toInt()
                            : (libraryEntry?.status == ReadingStatus.completed
                                  ? 100
                                  : 0);

                        return KomaProgressHeader(
                          readChapters: readCount,
                          totalChapters: totalCount,
                          title: manga.title,
                          author: manga.authorName,
                          coverImageUrl:
                              manga.coverUrl512 ??
                              resolveLibraryCoverUrl(
                                manga.id,
                                manga.coverFileName,
                                size: 512,
                              ),
                          statusChip: libraryEntry != null
                              ? Builder(
                                  builder: (chipContext) {
                                    final statusLabel = localizedReadingStatus(
                                      l10n,
                                      libraryEntry.status,
                                    );
                                    return KomaStatusChip(
                                      status: libraryEntry.status
                                          .toKomaStatusType(),
                                      label: statusLabel,
                                      semanticsLabel:
                                          '$statusLabel, ${l10n.changeStatus}',
                                      onTap: () =>
                                          _showStatusPicker(context, state),
                                    );
                                  },
                                )
                              : OutlinedButton.icon(
                                  onPressed: () =>
                                      _showStatusPicker(context, state),
                                  icon: const Icon(
                                    Icons.bookmark_add_outlined,
                                    size: 18,
                                  ),
                                  label: Text(l10n.addToLibrary),
                                ),
                          continueChapterLabel: continueChapterNum != null
                              ? l10n.continueChapterLabel(continueChapterNum)
                              : null,
                          onContinuePressed: continueChapterNum != null
                              ? () {
                                  final targetCh = aggregate?.orderedChapters
                                      .firstWhere(
                                        (c) =>
                                            c.chapterNumber ==
                                            continueChapterNum,
                                        orElse: () =>
                                            aggregate.orderedChapters.first,
                                      );
                                  if (targetCh != null) {
                                    unawaited(_openChapter(context, targetCh));
                                  }
                                }
                              : null,
                          progressFractionLabel: l10n.chaptersProgressFraction(
                            readCount,
                            totalCount,
                          ),
                          progressSummaryText: l10n.progressHeaderSummary(
                            readCount,
                            totalCount,
                          ),
                          progressSemanticsLabel: l10n.progressHeaderSemantics(
                            percent,
                            readCount,
                            totalCount,
                          ),
                          coverSemanticsLabel: l10n
                              .progressHeaderCoverSemantics(manga.title),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        borderRadius: BorderRadiusDirectional.circular(12)
                            .resolve(Directionality.of(context)),
                        border: Border.all(color: context.komaColors.inkBorder),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Semantics(
                          header: true,
                          child: Text(
                            l10n.synopsisTitle,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              16,
                              0,
                              16,
                              16,
                            ),
                            child: Text(
                              (manga.description != null &&
                                      manga.description!.trim().isNotEmpty)
                                  ? manga.description!.trim()
                                  : l10n.noSynopsis,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.volumesAndChaptersTitle,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (libraryEntry != null &&
                      aggregate != null &&
                      state.unreadChaptersCount > 0) ...[
                    Builder(
                      builder: (buttonContext) {
                        final latestUnread = _findLatestUnreadChapter(
                          aggregate,
                          libraryEntry,
                        );
                        if (latestUnread == null) {
                          return const SizedBox.shrink();
                        }
                        final colors = buttonContext.colorScheme;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(bottom: 12),
                          child: FilledButton.tonalIcon(
                            key: const Key(
                              'manga_detail_quick_mark_latest_button',
                            ),
                            onPressed: () {
                              buttonContext.read<MangaDetailBloc>().add(
                                MangaDetailChapterToggled(
                                  chapter: latestUnread,
                                  isRead: true,
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primaryContainer,
                              foregroundColor: colors.onPrimaryContainer,
                              minimumSize: const Size(
                                double.infinity,
                                kKomaMinTouchTarget,
                              ),
                              tapTargetSize: MaterialTapTargetSize.padded,
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadiusDirectional.circular(
                                  12,
                                ),
                              ),
                            ),
                            icon: const ExcludeSemantics(
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                size: 20,
                              ),
                            ),
                            label: Text(
                              l10n.detailQuickMarkLatestLabel(
                                latestUnread.chapterNumber,
                              ),
                              textAlign: TextAlign.center,
                              semanticsLabel: l10n
                                  .detailQuickMarkLatestSemantics(
                                    latestUnread.chapterNumber,
                                    manga?.title ?? libraryEntry.title,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  if (aggregate != null) ...[
                    Builder(
                      builder: (context) {
                        final defaultExpandedIndex =
                            _resolveDefaultExpandedVolumeIndex(
                              aggregate.volumes,
                              libraryEntry,
                            );
                        return Column(
                          children: [
                            for (var i = 0; i < aggregate.volumes.length; i++)
                              _buildVolumeTile(
                                context,
                                volume: aggregate.volumes[i],
                                libraryEntry: libraryEntry,
                                isDefaultExpanded: i == defaultExpandedIndex,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVolumeTile(
    BuildContext context, {
    required MangaVolume volume,
    required LibraryEntry? libraryEntry,
    required bool isDefaultExpanded,
  }) {
    final l10n = context.l10n;
    final volumeTitle = volume.volumeNumber == 'none'
        ? l10n.unassignedChaptersLabel
        : l10n.volumeLabel(volume.volumeNumber);

    final readInVolume = volume.chapters
        .where((c) => libraryEntry?.isChapterRead(c.chapterNumber) ?? false)
        .length;

    final isAllRead =
        volume.chapters.isNotEmpty && readInVolume == volume.chapters.length;

    final volumeContainsHighlight =
        highlightChapter != null &&
        volume.chapters.any((c) => c.chapterNumber == highlightChapter);

    final initiallyExpanded = isDefaultExpanded || volumeContainsHighlight;

    return KomaVolumeTile(
      key: ValueKey('volume_${volume.volumeNumber}_${libraryEntry != null}'),
      volumeTitle: volumeTitle,
      progressSummary: l10n.volumeProgressSummary(
        readInVolume,
        volume.chapters.length,
      ),
      isAllRead: isAllRead,
      initiallyExpanded: initiallyExpanded,
      markVolumeReadTooltip: l10n.markVolumeReadTooltip,
      markVolumeUnreadTooltip: l10n.markVolumeUnreadTooltip,
      markVolumeSemanticsLabel: l10n.volumeTileMarkSemantics(
        isAllRead ? l10n.markVolumeUnreadTooltip : l10n.markVolumeReadTooltip,
        volumeTitle,
      ),
      onMarkVolumeRead: () {
        context.read<MangaDetailBloc>().add(
          MangaDetailVolumeMarkedRead(volume),
        );
      },
      children: [
        for (final chapter in volume.chapters)
          _buildChapterRow(
            context,
            chapter: chapter,
            libraryEntry: libraryEntry,
          ),
      ],
    );
  }

  Widget _buildChapterRow(
    BuildContext context, {
    required MangaChapter chapter,
    required LibraryEntry? libraryEntry,
  }) {
    final l10n = context.l10n;
    final isRead = libraryEntry?.isChapterRead(chapter.chapterNumber) ?? false;

    return KomaChapterRow(
      key: ValueKey('chapter_${chapter.chapterNumber}_${chapter.id}'),
      chapterNumber: chapter.chapterNumber,
      isRead: isRead,
      hostIndicator: l10n.externalMangaDexHost,
      chapterTitleLabel: l10n.chapterLabel(chapter.chapterNumber),
      markReadTooltip: l10n.chapterRowMarkReadSemantics(chapter.chapterNumber),
      markUnreadTooltip: l10n.chapterRowMarkUnreadSemantics(
        chapter.chapterNumber,
      ),
      toggleSemanticsLabel: isRead
          ? l10n.chapterRowMarkUnreadSemantics(chapter.chapterNumber)
          : l10n.chapterRowMarkReadSemantics(chapter.chapterNumber),
      openMangaDexSemanticsLabel: l10n.chapterRowOpenMangaDexSemantics(
        chapter.chapterNumber,
      ),
      markPreviousReadSemanticsLabel: l10n.chapterRowMarkPreviousSemantics(
        chapter.chapterNumber,
      ),
      tapHint: l10n.chapterRowTapHint,
      longPressHint: l10n.chapterRowLongPressHint,
      markPreviousReadTooltip: l10n.markPreviousReadTooltip,
      openMangaDexTooltip: l10n.openMangaDexTooltip,
      onToggleRead: () {
        context.read<MangaDetailBloc>().add(
          MangaDetailChapterToggled(chapter: chapter, isRead: !isRead),
        );
      },
      onMarkPreviousRead: () {
        context.read<MangaDetailBloc>().add(
          MangaDetailBulkPreviousRequested(chapter),
        );
      },
      onOpenMangaDex: () => unawaited(_openChapter(context, chapter)),
    );
  }
}
