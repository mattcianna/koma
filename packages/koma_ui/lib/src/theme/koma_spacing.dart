import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Spacing and padding scale tokens for Koma UI.
///
/// Follows an 8dp baseline grid with 4dp micro steps.
/// Provides directional EdgeInsets helpers to guarantee RTL layout safety.
@immutable
class KomaSpacing extends ThemeExtension<KomaSpacing> {
  /// Creates an instance of this theme extension.
  const new({
    this.xxs = 4.0,
    this.xs = 8.0,
    this.sm = 12.0,
    this.md = 16.0,
    this.lg = 24.0,
    this.xlg = 32.0,
    this.xxlg = 48.0,
  });

  /// Micro spacing (4dp): badge padding, icon-text micro offsets.
  final double xxs;

  /// Extra small spacing (8dp): chip inner padding, tag margins.
  final double xs;

  /// Small spacing (12dp): card content margins, compact list padding.
  final double sm;

  /// Medium spacing (16dp): standard screen edge padding, list separation.
  final double md;

  /// Large spacing (24dp): section dividers, header to content separation.
  final double lg;

  /// Extra large spacing (32dp): modal sheet padding, empty state margins.
  final double xlg;

  /// Double extra large spacing (48dp): minimum interactive touch target.
  final double xxlg;

  /// Symmetric horizontal xs padding ([xs]).
  EdgeInsetsDirectional get horizontalXs =>
      EdgeInsetsDirectional.symmetric(horizontal: xs);

  /// Symmetric horizontal sm padding ([sm]).
  EdgeInsetsDirectional get horizontalSm =>
      EdgeInsetsDirectional.symmetric(horizontal: sm);

  /// Symmetric horizontal md padding ([md]).
  EdgeInsetsDirectional get horizontalMd =>
      EdgeInsetsDirectional.symmetric(horizontal: md);

  /// Symmetric horizontal lg padding ([lg]).
  EdgeInsetsDirectional get horizontalLg =>
      EdgeInsetsDirectional.symmetric(horizontal: lg);

  /// Symmetric vertical xs padding ([xs]).
  EdgeInsetsDirectional get verticalXs =>
      EdgeInsetsDirectional.symmetric(vertical: xs);

  /// Symmetric vertical sm padding ([sm]).
  EdgeInsetsDirectional get verticalSm =>
      EdgeInsetsDirectional.symmetric(vertical: sm);

  /// Symmetric vertical md padding ([md]).
  EdgeInsetsDirectional get verticalMd =>
      EdgeInsetsDirectional.symmetric(vertical: md);

  /// Symmetric vertical lg padding ([lg]).
  EdgeInsetsDirectional get verticalLg =>
      EdgeInsetsDirectional.symmetric(vertical: lg);

  /// Uniform padding on all sides of [xs].
  EdgeInsetsDirectional get allXs => EdgeInsetsDirectional.all(xs);

  /// Uniform padding on all sides of [sm].
  EdgeInsetsDirectional get allSm => EdgeInsetsDirectional.all(sm);

  /// Uniform padding on all sides of [md].
  EdgeInsetsDirectional get allMd => EdgeInsetsDirectional.all(md);

  /// Uniform padding on all sides of [lg].
  EdgeInsetsDirectional get allLg => EdgeInsetsDirectional.all(lg);

  /// Uniform padding on all sides of [xlg].
  EdgeInsetsDirectional get allXlg => EdgeInsetsDirectional.all(xlg);

  /// Uniform padding on all sides of [xxlg].
  EdgeInsetsDirectional get allXxlg => EdgeInsetsDirectional.all(xxlg);

  /// Standard screen scaffold margin (horizontal [md], top [sm], bottom [md]).
  EdgeInsetsDirectional get screenMargin =>
      EdgeInsetsDirectional.fromSTEB(md, sm, md, md);

  /// Card internal content padding ([sm]).
  EdgeInsetsDirectional get cardPadding => EdgeInsetsDirectional.all(sm);

  @override
  KomaSpacing copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xlg,
    double? xxlg,
  }) {
    return KomaSpacing(
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xlg: xlg ?? this.xlg,
      xxlg: xxlg ?? this.xxlg,
    );
  }

  @override
  KomaSpacing lerp(ThemeExtension<KomaSpacing>? other, double t) {
    if (other is! KomaSpacing) return this;
    return KomaSpacing(
      xxs: ui.lerpDouble(xxs, other.xxs, t) ?? xxs,
      xs: ui.lerpDouble(xs, other.xs, t) ?? xs,
      sm: ui.lerpDouble(sm, other.sm, t) ?? sm,
      md: ui.lerpDouble(md, other.md, t) ?? md,
      lg: ui.lerpDouble(lg, other.lg, t) ?? lg,
      xlg: ui.lerpDouble(xlg, other.xlg, t) ?? xlg,
      xxlg: ui.lerpDouble(xxlg, other.xxlg, t) ?? xxlg,
    );
  }
}

/// Alias for [KomaSpacing] adhering to ThemeExtension naming conventions.
typedef KomaSpacingExtension = KomaSpacing;
