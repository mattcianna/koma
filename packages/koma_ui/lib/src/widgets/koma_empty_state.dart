import 'package:flutter/material.dart';
import 'package:koma_ui/src/constants/koma_constants.dart';
import 'package:koma_ui/src/extensions/build_context_extensions.dart';

/// Reusable illustration-driven empty state widget.
///
/// Displays an asset image or fallback icon, headline title, explanatory
/// description, and an optional call-to-action button with >=48dp hit target.
class KomaEmptyState extends StatelessWidget {
  /// Creates an instance of this widget.
  const new({
    required this.title,
    required this.description,
    this.imageAssetPath,
    this.fallbackIcon,
    this.actionLabel,
    this.onActionPressed,
    super.key,
  });

  /// The headline title describing the empty condition.
  final String title;

  /// Explanatory supporting text or guidance.
  final String description;

  /// Optional asset path to an illustration PNG/SVG.
  final String? imageAssetPath;

  /// Optional fallback icon when asset is unavailable or fails to load.
  final IconData? fallbackIcon;

  /// Label for the optional call-to-action button.
  final String? actionLabel;

  /// Callback executed when the call-to-action button is pressed.
  final VoidCallback? onActionPressed;

  Widget _buildGraphic(BuildContext context) {
    final colors = context.colorScheme;
    final icon = fallbackIcon ?? Icons.menu_book_rounded;

    if (imageAssetPath != null && imageAssetPath!.isNotEmpty) {
      return Image.asset(
        imageAssetPath!,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (ctx, error, stackTrace) => ExcludeSemantics(
          child: Icon(icon, size: 72, color: colors.onSurfaceVariant),
        ),
      );
    }

    return ExcludeSemantics(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, size: 56, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final spacing = context.komaSpacing;

    return Center(
      child: SingleChildScrollView(
        padding: spacing.horizontalLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGraphic(context),
            SizedBox(height: spacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              SizedBox(height: spacing.lg),
              FilledButton(
                onPressed: onActionPressed,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, kKomaMinTouchTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusDirectional.circular(12),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
