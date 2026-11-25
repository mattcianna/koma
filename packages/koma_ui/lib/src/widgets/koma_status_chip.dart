import 'package:flutter/material.dart';
import 'package:koma_ui/src/constants/koma_constants.dart';
import 'package:koma_ui/src/extensions/build_context_extensions.dart';

/// The 5 canonical reading status categories in Koma.
enum KomaStatusType {
  /// Currently reading chapters.
  reading,

  /// Planned for future reading.
  planToRead,

  /// Completely read all released chapters.
  completed,

  /// Temporarily paused reading.
  onHold,

  /// Dropped / discontinued reading.
  dropped,
}

/// Status chip displaying one of the 5 canonical Manga tracker reading states.
///
/// Can be used as a static badge or an interactive filter button with
/// a minimum 48dp hit target conforming to WCAG 2.2 AA.
class KomaStatusChip extends StatelessWidget {
  /// Creates an instance of this widget.
  const new({
    required this.status,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.semanticsLabel,
    this.semanticsSelected,
    super.key,
  });

  /// The domain status state represented by this chip.
  final KomaStatusType status;

  /// The display text on the chip.
  final String label;

  /// Whether this chip is currently selected in a filter context.
  final bool isSelected;

  /// Optional tap callback. When null, renders as a non-interactive badge.
  final VoidCallback? onTap;

  /// Optional accessibility semantics label override.
  final String? semanticsLabel;

  /// Optional accessibility selected override.
  final bool? semanticsSelected;

  Color _getStatusColor(BuildContext context) {
    final colors = context.komaColors;
    switch (status) {
      case KomaStatusType.reading:
        return colors.reading;
      case KomaStatusType.planToRead:
        return colors.planToRead;
      case KomaStatusType.completed:
        return colors.completed;
      case KomaStatusType.onHold:
        return colors.onHold;
      case KomaStatusType.dropped:
        return colors.dropped;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);
    final isInteractive = onTap != null;
    final effectiveLabel = semanticsLabel ?? label;
    final effectiveSelected = semanticsSelected ?? isSelected;

    final chipPill = Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? statusColor.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadiusDirectional.circular(8)
            .resolve(Directionality.of(context)),
        border: Border.all(
          color: isSelected ? statusColor : context.colorScheme.outline,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: Icon(Icons.check_rounded, size: 14, color: statusColor),
            )
          else ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (!isInteractive) {
      return Semantics(
        container: true,
        label: effectiveLabel,
        child: ExcludeSemantics(child: chipPill),
      );
    }

    return Semantics(
      container: true,
      button: true,
      selected: effectiveSelected,
      label: effectiveLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadiusDirectional.circular(8)
            .resolve(Directionality.of(context)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kKomaMinTouchTarget,
            minWidth: kKomaMinTouchTarget,
          ),
          child: Align(
            alignment: AlignmentDirectional.center,
            child: ExcludeSemantics(child: chipPill),
          ),
        ),
      ),
    );
  }
}
