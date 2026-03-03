import '../models/categoria.dart';

/// Interfaz abstracta para el repositorio de Categorías.
///
/// Define el contrato que cualquier implementación de repositorio de categorías
/// debe seguir. Esto asegura la independencia de la capa de Dominio
/// de los detalles de implementación de la persistencia de datos.
abstract class CategoriaRepository {
  /// Obtiene una lista de todas las categorías disponibles.
  ///
  /// Retorna un `Future` que se resolverá con una lista de objetos [Categoria].
  Future<List<Categoria>> getAllCategorias();

  /// Obtiene una categoría específica por su identificador único.
  ///
  /// [id]: El identificador único de la categoría a buscar.
  /// Retorna un `Future` que se resolverá con el objeto [Categoria] si se encuentra,
  /// o `null` si no existe una categoría con el ID proporcionado.
  Future<Categoria?> getCategoriaById(int id);
}
