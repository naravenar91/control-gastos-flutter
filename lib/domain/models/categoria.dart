import 'package:control_de_gastos/domain/models/tipo_categoria.dart';

/// Clase que representa una categoría de gasto o ingreso.
///
/// Una categoría tiene un identificador único, una descripción, un color
/// para su representación visual y un tipo (ingreso, gasto u ocio).
class Categoria {
  /// Identificador único de la categoría.
  final int id;

  /// Descripción de la categoría (ej. "Comida", "Transporte", "Salario").
  final String descripcion;

  /// Código hexadecimal del color asociado a la categoría (ej. "#FF0000").
  final String colorHex;

  /// Tipo de categoría, definido por el enum [TipoCategoria].
  final TipoCategoria tipo;

  /// Constructor de la clase [Categoria].
  ///
  /// Todos los parámetros son requeridos y se usan para inicializar
  /// las propiedades de la categoría.
  Categoria({
    required this.id,
    required this.descripcion,
    required this.colorHex,
    required this.tipo,
  });

  /// Crea una nueva instancia de [Categoria] con valores posiblemente modificados.
  ///
  /// Si un parámetro es nulo, se usa el valor actual de la instancia.
  Categoria copyWith({
    int? id,
    String? descripcion,
    String? colorHex,
    TipoCategoria? tipo,
  }) {
    return Categoria(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      colorHex: colorHex ?? this.colorHex,
      tipo: tipo ?? this.tipo,
    );
  }

  /// Crea una instancia de [Categoria] a partir de un mapa JSON.
  ///
  /// Convierte el mapa JSON a un objeto [Categoria], parseando el tipo
  /// de categoría desde su representación en String.
  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as int,
      descripcion: json['descripcion'] as String,
      colorHex: json['colorHex'] as String,
      tipo: TipoCategoria.values.firstWhere(
          (e) => e.toString().split('.').last == json['tipo'] as String),
    );
  }

  /// Convierte la instancia de [Categoria] a un mapa JSON.
  ///
  /// Serializa las propiedades de la categoría a un formato de mapa JSON,
  /// incluyendo la representación en String del tipo de categoría.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descripcion': descripcion,
      'colorHex': colorHex,
      'tipo': tipo.toString().split('.').last,
    };
  }
}