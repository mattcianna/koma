import 'package:flutter/material.dart';

/// Semantic color tokens specific to Koma manga tracking domains.
///
/// Implements [ThemeExtension] so custom design tokens can be queried
/// via `Theme.of(context).extension<KomaColors>()`.
@immutable
class KomaColors extends ThemeExtension<KomaColors> {
  /// Creates an instance of this theme extension.
  const new({
    required this.reading,
    required this.onReading,
    required this.planToRead,
    required this.onPlanToRead,
    required this.completed,
    required this.onCompleted,
    required this.onHold,
    required this.onOnHold,
    required this.dropped,
    required this.onDropped,
    required this.unreadBadge,
    required this.onUnreadBadge,
    required this.inkBorder,
  });

  /// Status: Reading ('Reading') - Vermilion primary.
  final Color reading;

  /// Foreground color on [reading] surfaces.
  final Color onReading;

  /// Status: Plan to Read ('Plan to Read') - Purple / Indigo.
  final Color planToRead;

  /// Foreground color on [planToRead] surfaces.
  final Color onPlanToRead;

  /// Status: Completed ('Completed') - Emerald Green.
  final Color completed;

  /// Foreground color on [completed] surfaces.
  final Color onCompleted;

  /// Status: On Hold ('On Hold') - Amber / Ochre.
  final Color onHold;

  /// Foreground color on [onHold] surfaces.
  final Color onOnHold;

  /// Status: Dropped ('Dropped') - Muted Slate.
  final Color dropped;

  /// Foreground color on [dropped] surfaces.
  final Color onDropped;

  /// Unread chapters alert pill badge background.
  final Color unreadBadge;

  /// Foreground text color on [unreadBadge].
  final Color onUnreadBadge;

  /// High-contrast panel ink border.
  final Color inkBorder;

  /// Light mode ("Warm Washi Paper") preset.
  static const light = KomaColors(
    reading: Color(0xFFBE123C),
    onReading: Color(0xFFFFFFFF),
    planToRead: Color(0xFF6D28D9),
    onPlanToRead: Color(0xFFFFFFFF),
    completed: Color(0xFF047857),
    onCompleted: Color(0xFFFFFFFF),
    onHold: Color(0xFFB45309),
    onOnHold: Color(0xFFFFFFFF),
    dropped: Color(0xFF475569),
    onDropped: Color(0xFFFFFFFF),
    unreadBadge: Color(0xFFBE123C),
    onUnreadBadge: Color(0xFFFFFFFF),
    inkBorder: Color(0xFF78716C),
  );

  /// OLED dark mode ("Sumi Ink") preset.
  static const dark = KomaColors(
    reading: Color(0xFFFB7185),
    onReading: Color(0xFF4C0519),
    planToRead: Color(0xFFC4B5FD),
    onPlanToRead: Color(0xFF2E1065),
    completed: Color(0xFF34D399),
    onCompleted: Color(0xFF064E3B),
    onHold: Color(0xFFFBBF24),
    onOnHold: Color(0xFF451A03),
    dropped: Color(0xFF94A3B8),
    onDropped: Color(0xFF0F172A),
    unreadBadge: Color(0xFFE11D48),
    onUnreadBadge: Color(0xFFFFFFFF),
    inkBorder: Color(0xFF71717A),
  );

  @override
  KomaColors copyWith({
    Color? reading,
    Color? onReading,
    Color? planToRead,
    Color? onPlanToRead,
    Color? completed,
    Color? onCompleted,
    Color? onHold,
    Color? onOnHold,
    Color? dropped,
    Color? onDropped,
    Color? unreadBadge,
    Color? onUnreadBadge,
    Color? inkBorder,
  }) {
    return KomaColors(
      reading: reading ?? this.reading,
      onReading: onReading ?? this.onReading,
      planToRead: planToRead ?? this.planToRead,
      onPlanToRead: onPlanToRead ?? this.onPlanToRead,
      completed: completed ?? this.completed,
      onCompleted: onCompleted ?? this.onCompleted,
      onHold: onHold ?? this.onHold,
      onOnHold: onOnHold ?? this.onOnHold,
      dropped: dropped ?? this.dropped,
      onDropped: onDropped ?? this.onDropped,
      unreadBadge: unreadBadge ?? this.unreadBadge,
      onUnreadBadge: onUnreadBadge ?? this.onUnreadBadge,
      inkBorder: inkBorder ?? this.inkBorder,
    );
  }

  @override
  KomaColors lerp(ThemeExtension<KomaColors>? other, double t) {
    if (other is! KomaColors) return this;
    return KomaColors(
      reading: Color.lerp(reading, other.reading, t) ?? reading,
      onReading: Color.lerp(onReading, other.onReading, t) ?? onReading,
      planToRead: Color.lerp(planToRead, other.planToRead, t) ?? planToRead,
      onPlanToRead:
          Color.lerp(onPlanToRead, other.onPlanToRead, t) ?? onPlanToRead,
      completed: Color.lerp(completed, other.completed, t) ?? completed,
      onCompleted: Color.lerp(onCompleted, other.onCompleted, t) ?? onCompleted,
      onHold: Color.lerp(onHold, other.onHold, t) ?? onHold,
      onOnHold: Color.lerp(onOnHold, other.onOnHold, t) ?? onOnHold,
      dropped: Color.lerp(dropped, other.dropped, t) ?? dropped,
      onDropped: Color.lerp(onDropped, other.onDropped, t) ?? onDropped,
      unreadBadge: Color.lerp(unreadBadge, other.unreadBadge, t) ?? unreadBadge,
      onUnreadBadge:
          Color.lerp(onUnreadBadge, other.onUnreadBadge, t) ?? onUnreadBadge,
      inkBorder: Color.lerp(inkBorder, other.inkBorder, t) ?? inkBorder,
    );
  }
}

/// Alias for [KomaColors] adhering to ThemeExtension naming conventions.
typedef KomaPaletteExtension = KomaColors;
