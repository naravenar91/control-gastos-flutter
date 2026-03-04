/// Clase que representa un registro de gasto o ingreso.
///
/// Contiene detalles como el monto, la fecha, la descripción, si está activo,
/// la categoría a la que pertenece y si es un gasto fijo.
class Gasto {
  /// Identificador único del gasto.
  final int id;

  /// Descripción detallada del gasto o ingreso.
  final String descripcion;

  /// Monto del gasto o ingreso.
  final double monto;

  /// Fecha en que se realizó el gasto o se recibió el ingreso.
  final DateTime fecha;

  /// Indica si el gasto o ingreso está activo o inactivo.
  final bool activo;

  /// Identificador de la categoría a la que pertenece este gasto.
  final int idCategoria;

  /// Indica si el gasto es de tipo fijo (ej. alquiler, suscripciones).
  final bool esFijo;

  /// Fecha de inicio para gastos fijos recurrentes.
  final DateTime? fechaInicio;

  /// Fecha de fin para gastos fijos recurrentes (ej. fin de cuotas).
  final DateTime? fechaFin;

  /// Constructor de la clase [Gasto].
  ///
  /// Todos los parámetros son requeridos y se usan para inicializar
  /// las propiedades del gasto.
  Gasto({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    required this.activo,
    required this.idCategoria,
    required this.esFijo,
    this.fechaInicio,
    this.fechaFin,
  });

  /// Crea una nueva instancia de [Gasto] con valores posiblemente modificados.
  ///
  /// Si un parámetro es nulo, se usa el valor actual de la instancia.
  Gasto copyWith({
    int? id,
    String? descripcion,
    double? monto,
    DateTime? fecha,
    bool? activo,
    int? idCategoria,
    bool? esFijo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) {
    return Gasto(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      activo: activo ?? this.activo,
      idCategoria: idCategoria ?? this.idCategoria,
      esFijo: esFijo ?? this.esFijo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
    );
  }

  /// Crea una instancia de [Gasto] a partir de un mapa JSON.
  ///
  /// Convierte el mapa JSON a un objeto [Gasto], parseando la fecha
  /// desde su representación en String.
  factory Gasto.fromJson(Map<String, dynamic> json) {
    return Gasto(
      id: json['id'] as int,
      descripcion: json['descripcion'] as String,
      monto: (json['monto'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] as String),
      activo: json['activo'] as bool,
      idCategoria: json['idCategoria'] as int,
      esFijo: json['esFijo'] as bool,
      fechaInicio: json['fechaInicio'] != null ? DateTime.parse(json['fechaInicio'] as String) : null,
      fechaFin: json['fechaFin'] != null ? DateTime.parse(json['fechaFin'] as String) : null,
    );
  }

  /// Convierte la instancia de [Gasto] a un mapa JSON.
  ///
  /// Serializa las propiedades del gasto a un formato de mapa JSON,
  /// incluyendo la fecha en formato ISO 8601.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descripcion': descripcion,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'activo': activo,
      'idCategoria': idCategoria,
      'esFijo': esFijo,
      'fechaInicio': fechaInicio?.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
    };
  }
}
