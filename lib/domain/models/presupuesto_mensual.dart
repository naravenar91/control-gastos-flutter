/// Clase que representa un presupuesto mensual para una categoría específica.
///
/// Permite definir un límite de gasto para una categoría en un mes dado.
class PresupuestoMensual {
  /// Identificador único del presupuesto mensual.
  final int id;

  /// Mes al que aplica el presupuesto (ej. 1 para enero, 12 para diciembre).
  final int mes;

  /// Identificador de la categoría a la que aplica este presupuesto.
  final int idCategoria;

  /// Monto límite establecido para la categoría en el mes.
  final double montoLimite;

  /// Constructor de la clase [PresupuestoMensual].
  ///
  /// Todos los parámetros son requeridos y se usan para inicializar
  /// las propiedades del presupuesto.
  PresupuestoMensual({
    required this.id,
    required this.mes,
    required this.idCategoria,
    required this.montoLimite,
  });

  /// Crea una nueva instancia de [PresupuestoMensual] con valores posiblemente modificados.
  ///
  /// Si un parámetro es nulo, se usa el valor actual de la instancia.
  PresupuestoMensual copyWith({
    int? id,
    int? mes,
    int? idCategoria,
    double? montoLimite,
  }) {
    return PresupuestoMensual(
      id: id ?? this.id,
      mes: mes ?? this.mes,
      idCategoria: idCategoria ?? this.idCategoria,
      montoLimite: montoLimite ?? this.montoLimite,
    );
  }

  /// Crea una instancia de [PresupuestoMensual] a partir de un mapa JSON.
  ///
  /// Convierte el mapa JSON a un objeto [PresupuestoMensual].
  factory PresupuestoMensual.fromJson(Map<String, dynamic> json) {
    return PresupuestoMensual(
      id: json['id'] as int,
      mes: json['mes'] as int,
      idCategoria: json['idCategoria'] as int,
      montoLimite: (json['montoLimite'] as num).toDouble(),
    );
  }

  /// Convierte la instancia de [PresupuestoMensual] a un mapa JSON.
  ///
  /// Serializa las propiedades del presupuesto a un formato de mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mes': mes,
      'idCategoria': idCategoria,
      'montoLimite': montoLimite,
    };
  }
}