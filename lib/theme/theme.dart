import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

ThemeData buildLightTheme(Color seed) {
  return FlexThemeData.light(
    // Use your accent as the seed for a full M3 palette
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 12,
    visualDensity: VisualDensity.comfortable,
    useMaterial3: true,
  );
}

ThemeData buildDarkTheme(Color seed) {
  return FlexThemeData.dark(
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 12,
    visualDensity: VisualDensity.comfortable,
    useMaterial3: true,
  );
}
