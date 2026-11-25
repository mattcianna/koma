import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:koma_ui/src/constants/koma_constants.dart';
import 'package:koma_ui/src/extensions/build_context_extensions.dart';

/// Progress summary banner for Manga detail views.
///
/// Features cover thumbnail, title, author, reading status chip,
/// read/total counter, and an accessible live region progress indicator.
class KomaProgressHeader extends StatelessWidget {
  /// Creates an instance of this widget.
  const new({
    required this.readChapters,
    required this.totalChapters,
    this.title,
    this.author,
    this.coverImageUrl,
    this.coverImage,
    this.statusChip,
    this.continueChapterLabel,
    this.onContinuePressed,
    this.progressFractionLabel,
    this.progressSummaryText,
    this.progressSemanticsLabel,
    this.coverSemanticsLabel,
    super.key,
  });

  /// The count of chapters marked as read.
  final int readChapters;

  /// The total count of known released chapters.
  final int totalChapters;

  /// Optional manga title displayed in the header.
  final String? title;

  /// Optional author/artist attribution text.
  final String? author;

  /// Optional remote cover image URL.
  final String? coverImageUrl;

  /// Optional custom cover image widget (overrides [coverImageUrl]).
  final Widget? coverImage;

  /// Optional status chip or button.
  final Widget? statusChip;

  /// Action button label (e.g., 'Continue Ch. 45').
  final String? continueChapterLabel;

  /// Callback executed when the continue reading button is tapped.
  final VoidCallback? onContinuePressed;

  /// Custom formatted fraction string (e.g. 'Ch. 78 / 142').
  final String? progressFractionLabel;

  /// Optional progress summary text override.
  final String? progressSummaryText;

  /// Optional live region accessibility semantics label for progress.
  final String? progressSemanticsLabel;

  /// Optional accessibility semantics label for the cover image thumbnail.
  final String? coverSemanticsLabel;

  Widget _buildCoverThumbnail(BuildContext context) {
    final Widget coverChild;
    if (coverImage != null) {
      coverChild = coverImage!;
    } else {
      final colors = context.colorScheme;
      final komaColors = context.komaColors;

      coverChild = Container(
        width: 56,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadiusDirectional.circular(8)
              .resolve(Directionality.of(context)),
          border: Border.all(color: komaColors.inkBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadiusDirectional.circular(8)
              .resolve(Directionality.of(context)),
          child: coverImageUrl != null && coverImageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: coverImageUrl!,
                  httpHeaders: kKomaUserAgentHeaders,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => ColoredBox(
                    color: colors.surfaceContainer,
                    child: const Center(
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (ctx, url, err) => ColoredBox(
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
      );
    }

    if (coverSemanticsLabel != null && coverSemanticsLabel!.isNotEmpty) {
      return Semantics(
        image: true,
        label: coverSemanticsLabel,
        excludeSemantics: true,
        child: coverChild,
      );
    }

    return ExcludeSemantics(child: coverChild);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final komaColors = context.komaColors;
    final spacing = context.komaSpacing;

    final progress = totalChapters > 0
        ? (readChapters / totalChapters).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (progress * 100).toInt();

    final hasMetadataHeader =
        title != null ||
        coverImage != null ||
        coverImageUrl != null ||
        coverSemanticsLabel != null ||
        statusChip != null;

    return Container(
      padding: spacing.allMd,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadiusDirectional.circular(16)
            .resolve(Directionality.of(context)),
        border: Border.all(color: komaColors.inkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasMetadataHeader) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoverThumbnail(context),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null && title!.isNotEmpty)
                        Text(
                          title!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (author != null && author!.isNotEmpty) ...[
                        SizedBox(height: spacing.xxs),
                        Text(
                          author!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (statusChip != null) ...[
                        SizedBox(height: spacing.xs),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: kKomaMinTouchTarget,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: statusChip,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.md),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  progressFractionLabel ??
                      progressSummaryText ??
                      '$readChapters of $totalChapters Chapters',
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percentage%',
                style: context.textTheme.titleMedium?.copyWith(
                  color: komaColors.reading,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          Semantics(
            liveRegion: true,
            label:
                progressSemanticsLabel ??
                '$percentage% complete, $readChapters of $totalChapters '
                    'chapters read',
            child: ClipRRect(
              borderRadius: BorderRadiusDirectional.circular(6)
                  .resolve(Directionality.of(context)),
              child: ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(komaColors.reading),
                ),
              ),
            ),
          ),
          if (onContinuePressed != null &&
              continueChapterLabel != null &&
              continueChapterLabel!.isNotEmpty) ...[
            SizedBox(height: spacing.md),
            FilledButton.icon(
              onPressed: onContinuePressed,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(continueChapterLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
