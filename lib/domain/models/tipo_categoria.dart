/// Representa los diferentes tipos de categorías para gastos e ingresos.
///
/// Define si una categoría es para ingresos, gastos o actividades de ocio.
enum TipoCategoria {
  /// Categoría para ingresos.
  ingreso,

  /// Categoría para gastos.
  gasto,

  /// Categoría para actividades de ocio.
  ocio,
}

/// Extensión para la enumeración [TipoCategoria] que proporciona utilidades.
extension TipoCategoriaExtension on TipoCategoria {
  /// Convierte el valor de la enumeración a una cadena de texto corta,
  /// eliminando la parte del nombre de la enumeración (e.g., 'ingreso' en lugar de 'TipoCategoria.ingreso').
  String toShortString() {
    return toString().split('.').last;
  }
}
