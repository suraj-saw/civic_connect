import 'package:flutter/material.dart';

class TAppBarTheme {
  TAppBarTheme._();

  static AppBarTheme light(ColorScheme scheme) => AppBarTheme(
    backgroundColor: scheme.primary,
    foregroundColor: scheme.onPrimary,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: scheme.onPrimary),
    actionsIconTheme: IconThemeData(color: scheme.onPrimary),
  );

  static AppBarTheme dark(ColorScheme scheme) => AppBarTheme(
    backgroundColor: scheme.surface,
    foregroundColor: scheme.onSurface,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: scheme.onSurface),
    actionsIconTheme: IconThemeData(color: scheme.onSurface),
  );
}
