import 'package:flutter/material.dart';
import 'package:koma_ui/src/constants/koma_constants.dart';
import 'package:koma_ui/src/extensions/build_context_extensions.dart';

/// Single chapter list row with read toggle, MangaDex external link, and
/// bulk read support.
///
/// Implements WCAG 2.2 AA >=48dp touch targets on all interactive controls
/// and reflows dynamically without clipping under 200% font scaling.
class KomaChapterRow extends StatelessWidget {
  /// Creates an instance of this widget.
  const new({
    required this.chapterNumber,
    required this.onToggleRead,
    required this.onOpenMangaDex,
    required this.onMarkPreviousRead,
    this.title,
    this.publishDate,
    this.scanlationGroup,
    this.isRead = false,
    this.hostIndicator = 'MangaDex',
    this.markPreviousReadTooltip = 'Mark previous chapters as read',
    this.openMangaDexTooltip = 'Open chapter on MangaDex',
    this.chapterTitleLabel,
    this.markReadTooltip,
    this.markUnreadTooltip,
    this.toggleSemanticsLabel,
    this.openMangaDexSemanticsLabel,
    this.markPreviousReadSemanticsLabel,
    this.tapHint,
    this.longPressHint,
    super.key,
  });

  /// The chapter identifier or number (e.g. '78' or '10.5').
  final String chapterNumber;

  /// Optional chapter subtitle or title.
  final String? title;

  /// Optional formatted publication timestamp (e.g. '2 days ago').
  final String? publishDate;

  /// Optional scanlation team name.
  final String? scanlationGroup;

  /// Whether this chapter has been marked as read.
  final bool isRead;

  /// External host indicator text (defaults to 'MangaDex').
  final String? hostIndicator;

  /// Tooltip message for the "Mark Previous as Read" action.
  final String markPreviousReadTooltip;

  /// Tooltip message for the "Open on MangaDex" action.
  final String openMangaDexTooltip;

  /// Optional custom localized label for the chapter title.
  final String? chapterTitleLabel;

  /// Optional tooltip when marking chapter as read.
  final String? markReadTooltip;

  /// Optional tooltip when marking chapter as unread.
  final String? markUnreadTooltip;

  /// Optional accessibility semantics label override for the toggle action.
  final String? toggleSemanticsLabel;

  /// Optional accessibility semantics label override for the open action.
  final String? openMangaDexSemanticsLabel;

  /// Optional accessibility semantics label override for mark previous action.
  final String? markPreviousReadSemanticsLabel;

  /// Optional accessibility hint for tapping the chapter row.
  final String? tapHint;

  /// Optional accessibility hint for long-pressing the chapter row.
  final String? longPressHint;

  /// Callback executed when the chapter read state is toggled.
  final VoidCallback onToggleRead;

  /// Callback executed to open the external reader on MangaDex.
  final VoidCallback onOpenMangaDex;

  /// Callback executed to trigger the bulk read confirmation flow.
  final VoidCallback onMarkPreviousRead;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final komaColors = context.komaColors;

    final metadataItems = <String>[
      if (publishDate != null && publishDate!.isNotEmpty) publishDate!,
      if (scanlationGroup != null && scanlationGroup!.isNotEmpty)
        scanlationGroup!,
      if (hostIndicator != null && hostIndicator!.isNotEmpty) hostIndicator!,
    ];

    final hasMetadata = metadataItems.isNotEmpty;
    final defaultToggleTooltip = isRead
        ? (markUnreadTooltip ?? 'Mark chapter unread')
        : (markReadTooltip ?? 'Mark chapter read');
    final effectiveToggleTooltip = toggleSemanticsLabel ?? defaultToggleTooltip;
    final effectiveOpenTooltip =
        openMangaDexSemanticsLabel ?? openMangaDexTooltip;
    final effectiveMarkPreviousTooltip =
        markPreviousReadSemanticsLabel ?? markPreviousReadTooltip;

    final toggleButton = IconButton(
      constraints: const BoxConstraints(
        minWidth: kKomaMinTouchTarget,
        minHeight: kKomaMinTouchTarget,
      ),
      icon: Icon(
        isRead
            ? Icons.check_box_rounded
            : Icons.check_box_outline_blank_rounded,
        color: isRead ? komaColors.reading : colors.onSurfaceVariant,
      ),
      onPressed: onToggleRead,
      tooltip: effectiveToggleTooltip,
    );

    final openMangaDexButton = IconButton(
      constraints: const BoxConstraints(
        minWidth: kKomaMinTouchTarget,
        minHeight: kKomaMinTouchTarget,
      ),
      icon: Icon(Icons.open_in_new_rounded, size: 20, color: colors.tertiary),
      tooltip: effectiveOpenTooltip,
      onPressed: onOpenMangaDex,
    );

    final markPreviousButton = IconButton(
      constraints: const BoxConstraints(
        minWidth: kKomaMinTouchTarget,
        minHeight: kKomaMinTouchTarget,
      ),
      icon: Icon(
        Icons.playlist_add_check_rounded,
        size: 22,
        color: colors.onSurfaceVariant,
      ),
      tooltip: effectiveMarkPreviousTooltip,
      onPressed: onMarkPreviousRead,
    );

    final titleWidget = Text(
      chapterTitleLabel ??
          (title != null && title!.isNotEmpty
              ? 'Ch. $chapterNumber - $title'
              : 'Chapter $chapterNumber'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodyMedium?.copyWith(
        fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
        color: isRead ? colors.onSurfaceVariant : colors.onSurface,
      ),
    );

    Widget? metadataWidget;
    if (hasMetadata) {
      metadataWidget = Text(
        metadataItems.join(' • '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    }

    return Semantics(
      onTapHint: tapHint,
      onLongPressHint: longPressHint,
      child: InkWell(
        onLongPress: onMarkPreviousRead,
        onTap: onToggleRead,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isRead
                ? colors.surfaceContainer.withValues(alpha: 0.5)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: colors.outlineVariant, width: 0.5),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScaler = MediaQuery.textScalerOf(context);
              final isStacked =
                  constraints.maxWidth < 260 || textScaler.scale(1) >= 1.5;

              if (isStacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    titleWidget,
                    if (metadataWidget != null) ...[
                      const SizedBox(height: 4),
                      metadataWidget,
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        toggleButton,
                        openMangaDexButton,
                        markPreviousButton,
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  toggleButton,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        titleWidget,
                        if (metadataWidget != null) ...[
                          const SizedBox(height: 2),
                          metadataWidget,
                        ],
                      ],
                    ),
                  ),
                  openMangaDexButton,
                  markPreviousButton,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
