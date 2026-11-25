import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:koma_ui/src/constants/koma_constants.dart';
import 'package:koma_ui/src/extensions/build_context_extensions.dart';

/// Manga grid card with cover art, title, status, and unread chapter badge.
///
/// Complies with WCAG 2.2 AA interactive hit target sizing and
/// includes rich accessibility semantics.
class KomaMangaCard extends StatelessWidget {
  /// Creates an instance of this widget.
  const new({
    required this.title,
    required this.onTap,
    this.imageUrl,
    this.author,
    this.statusChip,
    this.unreadCount = 0,
    this.progress,
    this.width = 160.0,
    this.imageBuilder,
    this.semanticsLabel,
    this.footerAction,
    super.key,
  });

  /// The title of the manga.
  final String title;

  /// Callback executed when the card is pressed.
  final VoidCallback onTap;

  /// The remote URL of the cover art.
  final String? imageUrl;

  /// Optional author/artist attribution text.
  final String? author;

  /// Optional status chip widget (such as a status chip).
  final Widget? statusChip;

  /// Number of unread chapters to display in the alert badge.
  final int unreadCount;

  /// Optional reading progression value from 0.0 to 1.0.
  final double? progress;

  /// The fixed width of the card. Defaults to 160.0.
  final double width;

  /// Optional custom image builder, primarily used for hermetic testing.
  final WidgetBuilder? imageBuilder;

  /// Optional custom semantics label override.
  final String? semanticsLabel;

  /// Optional action widget rendered below the card tap region.
  ///
  /// Placed outside the card's [Semantics] and [InkWell] so assistive
  /// technologies expose the card and action as separate interactive controls.
  final Widget? footerAction;

  Widget _buildCoverImage(BuildContext context) {
    final colors = context.colorScheme;

    if (imageBuilder != null) {
      return imageBuilder!(context);
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        httpHeaders: kKomaUserAgentHeaders,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => ColoredBox(
          color: colors.surfaceContainer,
          child: const Center(
            child: ExcludeSemantics(
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (ctx, url, err) => ColoredBox(
          color: colors.surfaceContainerHigh,
          child: ExcludeSemantics(
            child: Icon(
              Icons.broken_image_rounded,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: colors.surfaceContainer,
      child: Center(
        child: ExcludeSemantics(
          child: Icon(
            Icons.menu_book_rounded,
            size: 40,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final komaColors = context.komaColors;
    final spacing = context.komaSpacing;
    final textScaler = MediaQuery.textScalerOf(context);
    final authorMaxLines = textScaler.scale(1) > 1.5 ? 2 : 1;

    final String effectiveSemanticsLabel;
    if (semanticsLabel != null && semanticsLabel!.isNotEmpty) {
      effectiveSemanticsLabel = semanticsLabel!;
    } else {
      final buffer = StringBuffer(title);
      if (author != null && author!.isNotEmpty) {
        buffer.write(', by $author');
      }
      if (unreadCount > 0) {
        buffer.write(', $unreadCount unread chapters');
      }
      if (progress != null) {
        final percent = (progress!.clamp(0.0, 1.0) * 100).toInt();
        buffer.write(', $percent% completed');
      }
      effectiveSemanticsLabel = buffer.toString();
    }

    final cardTapTarget = Semantics(
      container: true,
      button: true,
      label: effectiveSemanticsLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadiusDirectional.circular(12)
            .resolve(Directionality.of(context)),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadiusDirectional.circular(12)
                          .resolve(Directionality.of(context)),
                      child: _buildCoverImage(context),
                    ),
                    // Ink Panel Outer Border
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadiusDirectional.circular(12)
                              .resolve(Directionality.of(context)),
                          border: Border.all(color: komaColors.inkBorder),
                        ),
                      ),
                    ),
                    // Optional Progress Track at bottom of cover
                    if (progress != null && progress! > 0)
                      PositionedDirectional(
                        start: 0,
                        end: 0,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadiusDirectional.vertical(
                            bottom: Radius.circular(12),
                          ).resolve(Directionality.of(context)),
                          child: LinearProgressIndicator(
                            value: progress!.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.3,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              komaColors.reading,
                            ),
                          ),
                        ),
                      ),
                    // Unread Chapters Badge (Top-End corner)
                    if (unreadCount > 0)
                      PositionedDirectional(
                        top: spacing.xs,
                        end: spacing.xs,
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: komaColors.unreadBadge,
                            borderRadius: BorderRadiusDirectional.circular(16)
                                .resolve(Directionality.of(context)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '+$unreadCount',
                            style: TextStyle(
                              color: komaColors.onUnreadBadge,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: spacing.xs),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              if (author != null && author!.isNotEmpty) ...[
                SizedBox(height: spacing.xxs),
                Text(
                  author!,
                  maxLines: authorMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (statusChip != null) ...[
                SizedBox(height: spacing.xs),
                statusChip!,
              ],
            ],
          ),
        ),
      ),
    );

    if (footerAction == null) {
      return SizedBox(width: width, child: cardTapTarget);
    }

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          cardTapTarget,
          SizedBox(height: spacing.xs),
          footerAction!,
        ],
      ),
    );
  }
}
