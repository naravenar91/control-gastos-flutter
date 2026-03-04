import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un Cubit para manejar el estado del tema de la aplicación (claro/oscuro).
class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    emit(ThemeMode.values[themeIndex]);
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    emit(mode);
  }

  void toLight() => setTheme(ThemeMode.light);
  void toDark() => setTheme(ThemeMode.dark);
  void toSystem() => setTheme(ThemeMode.system);

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      toLight();
    } else {
      toDark();
    }
  }
}
