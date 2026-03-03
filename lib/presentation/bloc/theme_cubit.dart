import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Un Cubit para manejar el estado del tema de la aplicación (claro/oscuro).
///
/// Emite un [ThemeMode] que puede ser [ThemeMode.light] o [ThemeMode.dark].
class ThemeCubit extends Cubit<ThemeMode> {
  /// Constructor. Inicializa el tema con [ThemeMode.system] por defecto.
  ThemeCubit() : super(ThemeMode.system);

  /// Cambia el tema a modo claro.
  void toLight() => emit(ThemeMode.light);

  /// Cambia el tema a modo oscuro.
  void toDark() => emit(ThemeMode.dark);

  /// Alterna entre el modo claro y oscuro.
  void toggleTheme() {
    emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
