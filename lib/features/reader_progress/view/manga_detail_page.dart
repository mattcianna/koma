import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koma/features/reader_progress/bloc/manga_detail_bloc.dart';
import 'package:koma/features/reader_progress/view/manga_detail_view.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';

/// Top-level detail page for viewing Manga metadata, reading progress,
/// and chapters.
class MangaDetailPage extends StatelessWidget {
  /// Creates a [MangaDetailPage].
  const new({
    required this.mangaId,
    required this.uid,
    this.highlightChapter,
    this.translatedLanguages = const ['en', 'it'],
    this.preferredLocales = const ['en', 'it'],
    this.urlLauncher,
    this.onBackFallback,
    this.mangaRepository,
    this.libraryRepository,
    this.bloc,
    super.key,
  });

  /// Canonical MangaDex manga UUID.
  final String mangaId;

  /// Active user ID.
  final String uid;

  /// Optional chapter number to highlight and expand initially.
  final String? highlightChapter;

  /// Preferred translated scanlation languages.
  final List<String> translatedLanguages;

  /// Preferred UI locales for resolving title and description.
  final List<String> preferredLocales;

  /// Optional URL launcher callback for external MangaDex links.
  final Future<bool> Function(Uri uri)? urlLauncher;

  /// Optional fallback callback when navigating back on a cold deep link.
  final VoidCallback? onBackFallback;

  /// Optional [MangaRepository] instance for dependency injection.
  final MangaRepository? mangaRepository;

  /// Optional [LibraryRepository] instance for dependency injection.
  final LibraryRepository? libraryRepository;

  /// Optional [MangaDetailBloc] instance for hermetic testing.
  final MangaDetailBloc? bloc;

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: MangaDetailView(
          highlightChapter: highlightChapter,
          urlLauncher: urlLauncher,
          onBackFallback: onBackFallback,
        ),
      );
    }

    return BlocProvider(
      create: (context) =>
          MangaDetailBloc(
            mangaRepository: mangaRepository ?? context.read<MangaRepository>(),
            libraryRepository:
                libraryRepository ?? context.read<LibraryRepository>(),
          )..add(
            MangaDetailStarted(
              mangaId: mangaId,
              uid: uid,
              preferredLocales: preferredLocales,
              translatedLanguages: translatedLanguages,
            ),
          ),
      child: MangaDetailView(
        highlightChapter: highlightChapter,
        urlLauncher: urlLauncher,
        onBackFallback: onBackFallback,
      ),
    );
  }
}
