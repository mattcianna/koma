import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koma/features/library/bloc/library_bloc.dart';
import 'package:koma/features/library/view/library_view.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';

/// Top-level entry page for the user's Manga library.
class LibraryPage extends StatelessWidget {
  /// Creates a [LibraryPage].
  const new({
    required this.uid,
    this.onMangaTap,
    this.onDiscoverTap,
    this.libraryRepository,
    this.mangaRepository,
    super.key,
  });

  /// The active user ID.
  final String uid;

  /// Callback executed when a manga card is tapped.
  ///
  /// Defaults to navigating to `'/manga/:id'`.
  final ValueChanged<String>? onMangaTap;

  /// Callback executed when the empty library discover button is tapped.
  ///
  /// Defaults to navigating to `'/discover'`.
  final VoidCallback? onDiscoverTap;

  /// Optional [LibraryRepository] injection for hermetic testing.
  final LibraryRepository? libraryRepository;

  /// Optional [MangaRepository] injection for release synchronization.
  final MangaRepository? mangaRepository;

  @override
  Widget build(BuildContext context) {
    var resolvedMangaRepo = mangaRepository;
    if (resolvedMangaRepo == null) {
      try {
        resolvedMangaRepo = context.read<MangaRepository>();
      } on Object catch (_) {
        resolvedMangaRepo = null;
      }
    }

    return BlocProvider(
      create: (context) => LibraryBloc(
        libraryRepository:
            libraryRepository ?? context.read<LibraryRepository>(),
        mangaRepository: resolvedMangaRepo,
      )..add(LibraryStarted(uid: uid)),
      child: LibraryView(
        uid: uid,
        onMangaTap: onMangaTap,
        onDiscoverTap: onDiscoverTap,
      ),
    );
  }
}
