import 'package:flutter/material.dart';

class ThemeService extends ValueNotifier<ThemeMode> {
  ThemeService(super.value);

  void toggleTheme() {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeService = ThemeService(ThemeMode.system);