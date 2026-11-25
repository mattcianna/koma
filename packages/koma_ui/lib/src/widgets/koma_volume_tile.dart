import 'package:flutter/material.dart';
import 'package:koma_ui/src/constants/koma_constants.dart';
import 'package:koma_ui/src/extensions/build_context_extensions.dart';

/// Accordion tile grouping manga chapters by volume.
///
/// Features collapsible list disclosure, volume completion summary,
/// and a dedicated >=48dp action to mark the entire volume as read.
class KomaVolumeTile extends StatelessWidget {
  /// Creates an instance of this widget.
  const new({
    required this.volumeTitle,
    required this.progressSummary,
    required this.isAllRead,
    required this.onMarkVolumeRead,
    required this.children,
    this.initiallyExpanded = false,
    this.markVolumeReadTooltip = 'Mark volume as read',
    this.markVolumeUnreadTooltip = 'Mark volume as unread',
    this.markVolumeSemanticsLabel,
    super.key,
  });

  /// The volume headline (e.g. 'Volume 12' or 'Unassigned Chapters').
  final String volumeTitle;

  /// Progress subtitle (e.g. '8/8 chapters read' or '2 chapters remaining').
  final String progressSummary;

  /// Whether all chapters in this volume are currently marked read.
  final bool isAllRead;

  /// Callback executed when the volume completion button is tapped.
  final VoidCallback onMarkVolumeRead;

  /// The child chapter row widgets contained in this volume.
  final List<Widget> children;

  /// Whether the accordion is initially open.
  final bool initiallyExpanded;

  /// Tooltip message when the volume has unread chapters.
  final String markVolumeReadTooltip;

  /// Tooltip message when the entire volume is already read.
  final String markVolumeUnreadTooltip;

  /// Optional accessibility semantics label override for the volume action.
  final String? markVolumeSemanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final komaColors = context.komaColors;
    final tooltipText = isAllRead
        ? markVolumeUnreadTooltip
        : markVolumeReadTooltip;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadiusDirectional.circular(12)
              .resolve(Directionality.of(context)),
          border: Border.all(color: komaColors.inkBorder),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            volumeTitle,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            progressSummary,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          trailing: IconButton(
            constraints: const BoxConstraints(
              minWidth: kKomaMinTouchTarget,
              minHeight: kKomaMinTouchTarget,
            ),
            icon: Icon(
              isAllRead
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              color: isAllRead ? komaColors.completed : colors.onSurfaceVariant,
            ),
            tooltip: markVolumeSemanticsLabel ?? '$tooltipText: $volumeTitle',
            onPressed: onMarkVolumeRead,
          ),
          children: children,
        ),
      ),
    );
  }
}
