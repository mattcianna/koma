import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:koma/features/library/bloc/library_bloc.dart';
import 'package:koma/features/library/models/library_helpers.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:library_repository/library_repository.dart';

/// Presentation component displaying the user's library and filters.
class LibraryView extends StatefulWidget {
  /// Creates a [LibraryView].
  const new({
    required this.uid,
    this.onMangaTap,
    this.onDiscoverTap,
    super.key,
  });

  /// The active user ID.
  final String uid;

  /// Callback executed when a manga card is tapped.
  final ValueChanged<String>? onMangaTap;

  /// Callback executed when the empty library discover button is tapped.
  final VoidCallback? onDiscoverTap;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryGridLayout {
  const new({
    required this.crossAxisCount,
    required this.spacing,
    required this.cellWidth,
    required this.mainAxisExtent,
  });

  final int crossAxisCount;
  final double spacing;
  final double cellWidth;
  final double mainAxisExtent;
}

class _LibraryViewState extends State<LibraryView> {
  late final TextEditingController _searchController;
  bool _isFinishedExpanded = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  _LibraryGridLayout _computeGridLayout(
    BuildContext context,
    double width, {
    bool hasQuickAction = false,
  }) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final effectiveScale = textScale < 1.0 ? 1.0 : textScale;
    final scaledWidth = width / effectiveScale;
    final crossAxisCount =
        (scaledWidth < 320) || (width < 420 && effectiveScale >= 1.3)
        ? 1
        : (scaledWidth >= 560 ? 3 : 2);
    const spacing = 16.0;
    final totalSpacing = spacing * (crossAxisCount + 1);
    final cellWidth = (width - totalSpacing) / crossAxisCount;
    final metadataHeight =
        36.0 + ((effectiveScale >= 1.3 ? 88.0 : 68.0) * effectiveScale);
    final quickActionHeight = hasQuickAction
        ? (16.0 + (52.0 * effectiveScale))
        : 0.0;
    final mainAxisExtent =
        (cellWidth * 1.5) + metadataHeight + quickActionHeight;

    return _LibraryGridLayout(
      crossAxisCount: crossAxisCount,
      spacing: spacing,
      cellWidth: cellWidth,
      mainAxisExtent: mainAxisExtent,
    );
  }

  bool _canQuickMarkLatestRead(LibraryEntry entry) {
    final latest = entry.latestKnownChapterNumber?.trim();
    return entry.status == ReadingStatus.reading &&
        latest != null &&
        latest.isNotEmpty &&
        latest != 'none' &&
        calculateUnreadHint(entry) > 0;
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final bloc = context.read<LibraryBloc>();
    if (bloc.mangaRepository == null) return;
    bloc.add(const LibraryRefreshRequested());
    await bloc.stream.firstWhere((state) => !state.isRefreshing);
  }

  void _openDiscover(BuildContext context) {
    if (widget.onDiscoverTap != null) {
      widget.onDiscoverTap!();
    } else {
      unawaited(context.push('/discover'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<LibraryBloc, LibraryState>(
      listenWhen: (previous, current) =>
          previous.quickMarkFeedback != current.quickMarkFeedback &&
          current.quickMarkFeedback != null,
      listener: (context, state) {
        final feedback = state.quickMarkFeedback;
        if (feedback == null) return;
        final message = feedback.isError
            ? l10n.genericErrorTitle
            : l10n.homeQuickMarkReadSuccess(
                feedback.mangaTitle,
                feedback.chapterNumber,
              );
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
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.libraryTitle),
          actions: [
            IconButton(
              key: const Key('library_refresh_button'),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.refreshTooltip,
              onPressed: () => unawaited(_handleRefresh(context)),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
              child: TextField(
                key: const Key('library_search_field'),
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: l10n.librarySearchHint,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  hintText: l10n.librarySearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        tooltip: l10n.libraryClearSearchTooltip,
                        onPressed: () {
                          _searchController.clear();
                          context.read<LibraryBloc>().add(
                            const LibrarySearchQueryChanged(''),
                          );
                        },
                      );
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadiusDirectional.circular(12)
                        .resolve(Directionality.of(context)),
                  ),
                ),
                onChanged: (value) {
                  context.read<LibraryBloc>().add(
                    LibrarySearchQueryChanged(value),
                  );
                },
              ),
            ),
            BlocBuilder<LibraryBloc, LibraryState>(
              buildWhen: (previous, current) =>
                  previous.selectedStatus != current.selectedStatus,
              builder: (context, state) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: kKomaMinTouchTarget,
                          minWidth: kKomaMinTouchTarget,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.center,
                          child: FilterChip(
                            key: const Key('library_filter_all'),
                            selected: state.selectedStatus == null,
                            label: Text(l10n.statusAll),
                            onSelected: (_) {
                              context.read<LibraryBloc>().add(
                                const LibraryStatusFilterChanged(null),
                              );
                            },
                          ),
                        ),
                      ),
                      for (final status in ReadingStatus.values) ...[
                        const SizedBox(width: 8),
                        KomaStatusChip(
                          key: Key('library_filter_${status.name}'),
                          status: status.toKomaStatusType(),
                          label: localizedReadingStatus(l10n, status),
                          semanticsLabel: l10n.statusChipSemantics(
                            localizedReadingStatus(l10n, status),
                          ),
                          isSelected: state.selectedStatus == status,
                          onTap: () {
                            final newStatus = state.selectedStatus == status
                                ? null
                                : status;
                            context.read<LibraryBloc>().add(
                              LibraryStatusFilterChanged(newStatus),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<LibraryBloc, LibraryState>(
                builder: (context, state) {
                  if (state.status == LibraryStatus.loading &&
                      state.allEntries.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator.adaptive(
                        semanticsLabel: l10n.loadingLabel,
                      ),
                    );
                  }

                  if (state.status == LibraryStatus.failure &&
                      state.allEntries.isEmpty) {
                    return KomaEmptyState(
                      title: l10n.genericErrorTitle,
                      description: state.errorMessage ?? '',
                      actionLabel: l10n.retryAction,
                      onActionPressed: () {
                        context.read<LibraryBloc>().add(
                          LibraryStarted(uid: widget.uid),
                        );
                      },
                    );
                  }

                  if (state.isLibraryEmpty) {
                    return KomaEmptyState(
                      imageAssetPath: 'assets/illustrations/empty_library.png',
                      title: l10n.libraryEmptyTitle,
                      description: l10n.libraryEmptyDescription,
                      actionLabel: l10n.libraryEmptyAction,
                      onActionPressed: () => _openDiscover(context),
                    );
                  }

                  if (state.isHomeSectionsView) {
                    final toRead = state.toReadEntries;
                    final caughtUp = state.caughtUpEntries;
                    final finished = state.finishedOrPausedEntries;
                    final hasToReadQuickAction = toRead.any(
                      _canQuickMarkLatestRead,
                    );

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final toReadLayout = _computeGridLayout(
                          context,
                          constraints.maxWidth,
                          hasQuickAction: hasToReadQuickAction,
                        );
                        final baseLayout = _computeGridLayout(
                          context,
                          constraints.maxWidth,
                        );

                        return RefreshIndicator.adaptive(
                          onRefresh: () => _handleRefresh(context),
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: _buildSectionHeader(
                                  context,
                                  headerKey: const Key('home_section_to_read'),
                                  title: l10n.homeSectionToRead,
                                  count: toRead.length,
                                ),
                              ),
                              if (toRead.isEmpty)
                                SliverToBoxAdapter(
                                  child: _buildCaughtUpBanner(context),
                                )
                              else
                                _buildEntrySliverGrid(
                                  context,
                                  entries: toRead,
                                  layout: toReadLayout,
                                  markingReadMangaIds:
                                      state.markingReadMangaIds,
                                ),
                              if (caughtUp.isNotEmpty) ...[
                                SliverToBoxAdapter(
                                  child: _buildSectionHeader(
                                    context,
                                    headerKey: const Key(
                                      'home_section_caught_up',
                                    ),
                                    title: l10n.homeSectionCaughtUp,
                                    count: caughtUp.length,
                                  ),
                                ),
                                _buildEntrySliverGrid(
                                  context,
                                  entries: caughtUp,
                                  layout: baseLayout,
                                  markingReadMangaIds:
                                      state.markingReadMangaIds,
                                ),
                              ],
                              if (finished.isNotEmpty) ...[
                                SliverToBoxAdapter(
                                  child: _buildSectionHeader(
                                    context,
                                    headerKey: const Key(
                                      'home_section_finished',
                                    ),
                                    title: l10n.homeSectionFinished,
                                    count: finished.length,
                                    isExpanded: _isFinishedExpanded,
                                    onToggle: () => setState(
                                      () => _isFinishedExpanded =
                                          !_isFinishedExpanded,
                                    ),
                                  ),
                                ),
                                if (_isFinishedExpanded)
                                  _buildEntrySliverGrid(
                                    context,
                                    entries: finished,
                                    layout: baseLayout,
                                    markingReadMangaIds:
                                        state.markingReadMangaIds,
                                  ),
                              ],
                              const SliverPadding(
                                padding: EdgeInsetsDirectional.only(bottom: 16),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  if (state.isFilterEmpty) {
                    return KomaEmptyState(
                      title: l10n.libraryFilterEmptyTitle,
                      description: l10n.libraryFilterEmptyDescription,
                      actionLabel: l10n.libraryClearFilters,
                      onActionPressed: () {
                        _searchController.clear();
                        context.read<LibraryBloc>()
                          ..add(const LibraryStatusFilterChanged(null))
                          ..add(const LibrarySearchQueryChanged(''));
                      },
                    );
                  }

                  final entries = state.filteredEntries;
                  final hasFilteredQuickAction = entries.any(
                    _canQuickMarkLatestRead,
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final layout = _computeGridLayout(
                        context,
                        constraints.maxWidth,
                        hasQuickAction: hasFilteredQuickAction,
                      );

                      return RefreshIndicator.adaptive(
                        onRefresh: () => _handleRefresh(context),
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsetsDirectional.all(layout.spacing),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: layout.crossAxisCount,
                                mainAxisSpacing: layout.spacing,
                                crossAxisSpacing: layout.spacing,
                                mainAxisExtent: layout.mainAxisExtent,
                              ),
                          itemCount: entries.length,
                          itemBuilder: (context, index) => _buildEntryCard(
                            context,
                            entry: entries[index],
                            cellWidth: layout.cellWidth,
                            isMarkingRead: state.markingReadMangaIds.contains(
                              entries[index].mangaId,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required Key headerKey,
    required String title,
    required int count,
    bool? isExpanded,
    VoidCallback? onToggle,
  }) {
    final l10n = context.l10n;
    final colors = context.colorScheme;
    final headerText = Text(
      title,
      style: context.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
    final countBadge = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadiusDirectional.circular(999)
            .resolve(Directionality.of(context)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 2,
        ),
        child: Text(
          '$count',
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    if (onToggle != null && isExpanded != null) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
        child: Semantics(
          button: true,
          header: true,
          expanded: isExpanded,
          label: '$title ($count)',
          hint: l10n.sectionCollapseSemantics(title),
          child: InkWell(
            key: headerKey,
            borderRadius: BorderRadiusDirectional.circular(8)
                .resolve(Directionality.of(context)),
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kKomaMinTouchTarget),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Flexible(child: headerText),
                    const SizedBox(width: 8),
                    countBadge,
                    const Spacer(),
                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
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

    return Padding(
      key: headerKey,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
      child: Semantics(
        container: true,
        header: true,
        label: count > 0 ? '$title ($count)' : title,
        child: ExcludeSemantics(
          child: Row(
            children: [
              Flexible(child: headerText),
              if (count > 0) ...[const SizedBox(width: 8), countBadge],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaughtUpBanner(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colorScheme;

    return Padding(
      key: const Key('home_caught_up_banner'),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadiusDirectional.circular(16)
              .resolve(Directionality.of(context)),
          border: Border.all(color: context.komaColors.inkBorder),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.verified_rounded,
                  size: 36,
                  color: context.komaColors.completed,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.homeUpToDateTitle,
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.homeUpToDateDescription,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _openDiscover(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  l10n.homeUpToDateAction,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntrySliverGrid(
    BuildContext context, {
    required List<LibraryEntry> entries,
    required _LibraryGridLayout layout,
    required Set<String> markingReadMangaIds,
  }) {
    return SliverPadding(
      padding: EdgeInsetsDirectional.fromSTEB(
        layout.spacing,
        4,
        layout.spacing,
        12,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: layout.crossAxisCount,
          mainAxisSpacing: layout.spacing,
          crossAxisSpacing: layout.spacing,
          mainAxisExtent: layout.mainAxisExtent,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) => _buildEntryCard(
          context,
          entry: entries[index],
          cellWidth: layout.cellWidth,
          isMarkingRead: markingReadMangaIds.contains(entries[index].mangaId),
        ),
      ),
    );
  }

  Widget _buildEntryCard(
    BuildContext context, {
    required LibraryEntry entry,
    required double cellWidth,
    required bool isMarkingRead,
  }) {
    final l10n = context.l10n;
    final unreadCount = calculateUnreadHint(entry);
    final totalChapters =
        double.tryParse(entry.latestKnownChapterNumber ?? '')?.round() ?? 0;
    final double? progressFraction;
    final int? percent;
    if (entry.status == ReadingStatus.completed) {
      progressFraction = 1.0;
      percent = 100;
    } else if (totalChapters > 0) {
      final readDenominator = totalChapters;
      final readCount = entry.readChapters.length;
      final fraction = (readCount / readDenominator).clamp(0.0, 1.0);
      progressFraction = fraction;
      percent = (fraction * 100).toInt();
    } else {
      progressFraction = null;
      percent = null;
    }

    final statusLabel = localizedReadingStatus(l10n, entry.status);
    final semanticsBuffer = StringBuffer('${entry.title}, $statusLabel');
    if (unreadCount > 0) {
      semanticsBuffer.write(', ${l10n.mangaCardUnreadSemantics(unreadCount)}');
    }
    if (percent != null) {
      semanticsBuffer.write(', ${l10n.mangaCardProgressSemantics(percent)}');
    }

    Widget? footerAction;
    if (_canQuickMarkLatestRead(entry)) {
      final latestChapter = entry.latestKnownChapterNumber!.trim();
      final colors = context.colorScheme;
      footerAction = FilledButton.tonalIcon(
        key: Key('library_quick_mark_read_${entry.mangaId}'),
        onPressed: isMarkingRead
            ? null
            : () {
                context.read<LibraryBloc>().add(
                  LibraryQuickMarkLatestReadRequested(entry),
                );
              },
        style: FilledButton.styleFrom(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          disabledBackgroundColor: colors.surfaceContainerHighest,
          disabledForegroundColor: colors.onSurfaceVariant,
          minimumSize: const Size(double.infinity, kKomaMinTouchTarget),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.circular(10),
          ),
        ),
        icon: isMarkingRead
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                  semanticsLabel: l10n.loadingLabel,
                ),
              )
            : const ExcludeSemantics(
                child: Icon(Icons.check_circle_outline_rounded, size: 18),
              ),
        label: Text(
          l10n.homeQuickMarkReadLabel(latestChapter),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          semanticsLabel: l10n.homeQuickMarkReadSemantics(
            entry.title,
            latestChapter,
          ),
        ),
      );
    }

    return KomaMangaCard(
      title: entry.title,
      imageUrl: resolveLibraryCoverUrl(entry.mangaId, entry.coverFileName),
      width: cellWidth,
      unreadCount: unreadCount,
      progress: progressFraction,
      semanticsLabel: semanticsBuffer.toString(),
      statusChip: KomaStatusChip(
        status: entry.status.toKomaStatusType(),
        label: statusLabel,
        semanticsLabel: l10n.statusChipSemantics(statusLabel),
      ),
      footerAction: footerAction,
      onTap: () {
        if (widget.onMangaTap != null) {
          widget.onMangaTap!(entry.mangaId);
        } else {
          unawaited(context.push('/manga/${entry.mangaId}'));
        }
      },
    );
  }
}
