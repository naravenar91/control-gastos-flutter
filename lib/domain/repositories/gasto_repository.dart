import '../models/gasto.dart';

/// Interfaz abstracta para el repositorio de Gastos.
///
/// Define el contrato que cualquier implementación de repositorio de gastos
/// debe seguir. Esto asegura la independencia de la capa de Dominio
/// de los detalles de implementación de la persistencia de datos.
abstract class GastoRepository {
  /// Guarda un gasto en la fuente de datos.
  ///
  /// Si el gasto ya existe (basado en su ID), lo actualiza. De lo contrario,
  /// crea un nuevo registro.
  /// [gasto]: El objeto [Gasto] a guardar.
  /// Retorna un `Future<void>` que se completa cuando la operación ha terminado.
  Future<void> saveGasto(Gasto gasto);

  /// Elimina un gasto de la fuente de datos por su identificador.
  ///
  /// [id]: El identificador único del gasto a eliminar.
  /// Retorna un `Future<void>` que se completa cuando la operación ha terminado.
  Future<void> deleteGasto(int id);

  /// Obtiene una lista de gastos dentro de un rango de fechas específico.
  ///
  /// [startDate]: La fecha de inicio del rango (inclusive).
  /// [endDate]: La fecha de fin del rango (inclusive).
  /// Retorna un `Future` que se resolverá con una lista de objetos [Gasto].
  Future<List<Gasto>> getGastosByDateRange(DateTime startDate, DateTime endDate);

  /// Obtiene una lista de gastos filtrados por una categoría específica.
  ///
  /// [idCategoria]: El identificador único de la categoría.
  /// Retorna un `Future` que se resolverá con una lista de objetos [Gasto].
  Future<List<Gasto>> getGastosByCategoria(int idCategoria);
}
