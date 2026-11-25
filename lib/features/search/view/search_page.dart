import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:koma/features/search/bloc/search_bloc.dart';
import 'package:koma/features/search/bloc/search_event.dart';
import 'package:koma/features/search/bloc/search_state.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:manga_repository/manga_repository.dart';

/// {@template search_page}
/// Root discovery and search page providing [SearchBloc] to [SearchView].
/// {@endtemplate}
class SearchPage extends StatelessWidget {
  /// {@macro search_page}
  const new({
    this.translatedLanguages = const ['en', 'it'],
    this.contentRatings = const ['safe', 'suggestive'],
    this.preferredLocales = const ['en', 'it'],
    this.onMangaTap,
    this.cardImageBuilder,
    super.key,
  });

  /// Filter languages requested from MangaDex.
  final List<String> translatedLanguages;

  /// Content rating classifications permitted.
  final List<String> contentRatings;

  /// Locales preferred for title resolution.
  final List<String> preferredLocales;

  /// Callback fired when a manga card is tapped.
  final ValueChanged<String>? onMangaTap;

  /// Optional custom image builder for cards in tests.
  final WidgetBuilder? cardImageBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc(
        mangaRepository: context.read<MangaRepository>(),
        translatedLanguages: translatedLanguages,
        contentRatings: contentRatings,
        preferredLocales: preferredLocales,
      )..add(const SearchStarted()),
      child: SearchView(
        onMangaTap: onMangaTap ?? (id) => context.push('/manga/$id'),
        cardImageBuilder: cardImageBuilder,
      ),
    );
  }
}

/// {@template search_view}
/// Presentation view for manga discovery, title search, and infinite
/// scrolling.
/// {@endtemplate}
class SearchView extends StatefulWidget {
  /// {@macro search_view}
  const new({required this.onMangaTap, this.cardImageBuilder, super.key});

  /// Callback fired when a manga card is tapped.
  final ValueChanged<String> onMangaTap;

  /// Optional custom image builder for cards in tests.
  final WidgetBuilder? cardImageBuilder;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late final SearchController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<SearchBloc>().add(const SearchLoadMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Widget _buildEmptyState(BuildContext context, SearchState state) {
    final l10n = context.l10n;

    if (state.isFailure) {
      final message = switch (state.errorKind) {
        SearchErrorKind.rateLimit => l10n.discoverRateLimitError,
        SearchErrorKind.network => l10n.discoverOfflineNotice,
        _ => l10n.authUnknownError,
      };

      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsetsDirectional.all(context.komaSpacing.lg),
          child: KomaEmptyState(
            key: const Key('discover_error_state'),
            title: l10n.genericErrorTitle,
            description: message,
            fallbackIcon: Icons.wifi_off_rounded,
            actionLabel: l10n.retryAction,
            onActionPressed: () {
              context.read<SearchBloc>().add(const SearchRefreshed());
            },
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.all(context.komaSpacing.lg),
        child: KomaEmptyState(
          key: const Key('discover_empty_state'),
          title: l10n.discoverEmptyTitle,
          description: l10n.discoverEmptyDescription,
          imageAssetPath: 'assets/illustrations/empty_search.png',
          fallbackIcon: Icons.search_off_rounded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.komaSpacing;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.all(spacing.md),
              child: Semantics(
                label: l10n.discoverSearchHint,
                child: SearchBar(
                  key: const Key('discover_search_bar'),
                  controller: _searchController,
                  hintText: l10n.discoverSearchHint,
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(fontSize: 16, height: 3),
                  ),
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      Tooltip(
                        message: l10n.discoverClearSearchTooltip,
                        child: IconButton(
                          key: const Key('discover_search_clear_button'),
                          tooltip: l10n.discoverClearSearchTooltip,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            context.read<SearchBloc>().add(
                              const SearchQueryChanged(''),
                            );
                            setState(() {});
                          },
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    context.read<SearchBloc>().add(SearchQueryChanged(value));
                    setState(() {});
                  },
                  onSubmitted: (value) {
                    context.read<SearchBloc>().add(SearchQueryChanged(value));
                  },
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state.isLoading && state.results.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator.adaptive(
                        key: const Key('discover_loading_indicator'),
                        semanticsLabel: l10n.loadingLabel,
                      ),
                    );
                  }

                  if (state.results.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        final bloc = context.read<SearchBloc>()
                          ..add(const SearchRefreshed());
                        await bloc.stream.firstWhere(
                          (s) => s.status != SearchStatus.loading,
                        );
                      },
                      child: _buildEmptyState(context, state),
                    );
                  }

                  final header = state.isPopular
                      ? l10n.discoverPopularHeader
                      : l10n.discoverResultsHeader;

                  return RefreshIndicator(
                    onRefresh: () async {
                      final bloc = context.read<SearchBloc>()
                        ..add(const SearchRefreshed());
                      await bloc.stream.firstWhere(
                        (s) => s.status != SearchStatus.loading,
                      );
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        final textScale = MediaQuery.textScalerOf(context)
                            .scale(1);
                        final isNarrowScale =
                            screenWidth < 420 && textScale >= 1.5;
                        final crossAxisCount = screenWidth >= 600
                            ? 3
                            : (isNarrowScale ? 1 : 2);
                        final crossAxisSpacing = spacing.md;
                        final horizontalPadding = spacing.md * 2;
                        final availableWidth =
                            screenWidth -
                            horizontalPadding -
                            (crossAxisSpacing * (crossAxisCount - 1));
                        final cellWidth = availableWidth / crossAxisCount;

                        final effectiveScale = textScale < 1.0
                            ? 1.0
                            : textScale;
                        final metadataHeight =
                            12.0 +
                            ((effectiveScale > 1.5 ? 74.0 : 60.0) *
                                effectiveScale);
                        final mainAxisExtent =
                            (cellWidth * 1.5) + metadataHeight;

                        return CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsetsDirectional.only(
                                start: spacing.md,
                                end: spacing.md,
                                bottom: spacing.sm,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    header,
                                    style: context.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: context.colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsetsDirectional.symmetric(
                                horizontal: spacing.md,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: spacing.md,
                                      crossAxisSpacing: crossAxisSpacing,
                                      mainAxisExtent: mainAxisExtent,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final manga = state.results[index];
                                  final semanticsLabel =
                                      (manga.authorName != null &&
                                          manga.authorName!.isNotEmpty)
                                      ? l10n.mangaCardSemanticsWithAuthor(
                                          manga.title,
                                          manga.authorName!,
                                        )
                                      : manga.title;
                                  return KomaMangaCard(
                                    key: Key('manga_card_${manga.id}'),
                                    title: manga.title,
                                    author: manga.authorName,
                                    semanticsLabel: semanticsLabel,
                                    imageUrl:
                                        manga.coverUrl256 ?? manga.coverUrl512,
                                    width: cellWidth,
                                    onTap: () => widget.onMangaTap(manga.id),
                                    imageBuilder: widget.cardImageBuilder,
                                  );
                                }, childCount: state.results.length),
                              ),
                            ),
                            if (state.isLoadingMore)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsetsDirectional.all(
                                    spacing.md,
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator.adaptive(
                                      semanticsLabel: l10n.loadingLabel,
                                    ),
                                  ),
                                ),
                              ),
                            SliverPadding(
                              padding: EdgeInsetsDirectional.only(
                                bottom: spacing.lg,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
