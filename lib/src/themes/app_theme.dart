import 'package:civic_connect/src/themes/appbar_theme.dart';
import 'package:civic_connect/src/themes/elevated_button_theme.dart';
import 'package:civic_connect/src/themes/text_button_theme.dart';
import 'package:civic_connect/src/themes/text_form_field_theme.dart';
import 'package:civic_connect/src/themes/text_theme.dart';
import 'package:flutter/material.dart';

class TAppTheme {
  TAppTheme._();

  static ThemeData light({
    Color seedColor = Colors.blue,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: TTextTheme.baseTextTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface
      ),

      appBarTheme: TAppBarTheme.light(colorScheme),
      elevatedButtonTheme: TElevatedButtonTheme.light(colorScheme),
      textButtonTheme: TTextButtonTheme.light(colorScheme),
      inputDecorationTheme: TInputDecorationTheme.light(colorScheme),
    );
  }

  static ThemeData dark({
    Color seedColor = Colors.blue,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: TTextTheme.baseTextTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),


      appBarTheme: TAppBarTheme.dark(colorScheme),
      elevatedButtonTheme: TElevatedButtonTheme.dark(colorScheme),
      textButtonTheme: TTextButtonTheme.dark(colorScheme),
      inputDecorationTheme: TInputDecorationTheme.dark(colorScheme),
    );
  }
}