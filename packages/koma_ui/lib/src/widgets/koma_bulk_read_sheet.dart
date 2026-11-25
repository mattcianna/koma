import 'package:flutter/material.dart';
import 'package:koma_ui/src/constants/koma_constants.dart';
import 'package:koma_ui/src/extensions/build_context_extensions.dart';

/// Modal bottom sheet confirming bulk "Mark Previous as Read" operations.
///
/// Ensures explicit reader confirmation before performing multi-chapter
/// batch updates to prevent accidental progress overrides.
class KomaBulkReadSheet extends StatelessWidget {
  /// Creates an instance of this widget.
  const new({
    required this.targetChapterNumber,
    required this.affectedCount,
    required this.onConfirm,
    required this.onCancel,
    required this.titleText,
    required this.messageText,
    required this.confirmButtonText,
    required this.cancelButtonText,
    this.isLoading = false,
    this.loadingSemanticsLabel = 'Loading...',
    super.key,
  });

  /// The highest chapter number included in the batch.
  final String targetChapterNumber;

  /// The total count of chapters to be marked as read.
  final int affectedCount;

  /// Callback executed when the reader confirms the bulk action.
  final VoidCallback onConfirm;

  /// Callback executed when the reader cancels or dismisses the sheet.
  final VoidCallback onCancel;

  /// Sheet title (e.g. 'Mark Previous as Read?').
  final String titleText;

  /// Informational explanation text.
  final String messageText;

  /// Text on the primary confirmation button.
  final String confirmButtonText;

  /// Text on the secondary cancellation button.
  final String cancelButtonText;

  /// Whether an asynchronous batch update is currently in flight.
  final bool isLoading;

  /// Optional accessibility semantics label for the loading spinner.
  final String loadingSemanticsLabel;

  /// Displays the [KomaBulkReadSheet] inside a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String targetChapterNumber,
    required int affectedCount,
    required VoidCallback onConfirm,
    required String titleText,
    required String messageText,
    required String confirmButtonText,
    required String cancelButtonText,
    VoidCallback? onCancel,
    bool isLoading = false,
    String loadingSemanticsLabel = 'Loading...',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (ctx) => KomaBulkReadSheet(
        targetChapterNumber: targetChapterNumber,
        affectedCount: affectedCount,
        onConfirm: onConfirm,
        onCancel: onCancel ?? () => Navigator.of(ctx).pop(),
        titleText: titleText,
        messageText: messageText,
        confirmButtonText: confirmButtonText,
        cancelButtonText: cancelButtonText,
        isLoading: isLoading,
        loadingSemanticsLabel: loadingSemanticsLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final spacing = context.komaSpacing;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: spacing.screenMargin,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadiusDirectional.circular(2)
                        .resolve(Directionality.of(context)),
                  ),
                ),
              ),
              SizedBox(height: spacing.md),
              Semantics(
                header: true,
                child: Text(
                  titleText,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: spacing.xs),
              Text(
                messageText,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing.lg),
              FilledButton(
                onPressed: isLoading ? null : onConfirm,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, kKomaMinTouchTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusDirectional.circular(12),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          semanticsLabel: loadingSemanticsLabel,
                        ),
                      )
                    : Text('$confirmButtonText ($affectedCount)'),
              ),
              SizedBox(height: spacing.xs),
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, kKomaMinTouchTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusDirectional.circular(12),
                  ),
                ),
                child: Text(cancelButtonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
