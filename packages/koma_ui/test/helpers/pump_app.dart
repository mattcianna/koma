import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ThemeData? theme,
    TextScaler? textScaler,
    Locale locale = const Locale('en'),
  }) {
    return pumpWidget(
      MaterialApp(
        theme: theme ?? KomaTheme.light,
        locale: locale,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              textScaler: textScaler ?? TextScaler.noScaling,
            ),
            child: widget,
          ),
        ),
      ),
    );
  }
}
