import '../models/presupuesto_mensual.dart';

/// Interfaz abstracta para el repositorio de Presupuestos Mensuales.
///
/// Define el contrato que cualquier implementación de repositorio de presupuestos
/// debe seguir. Esto asegura la independencia de la capa de Dominio
/// de los detalles de implementación de la persistencia de datos.
abstract class PresupuestoRepository {
  /// Obtiene el presupuesto mensual para un mes y una categoría específicos.
  ///
  /// [mes]: El mes del presupuesto (ej. 1 para enero).
  /// [idCategoria]: El identificador único de la categoría.
  /// Retorna un `Future` que se resolverá con el objeto [PresupuestoMensual] si se encuentra,
  /// o `null` si no existe un presupuesto para la combinación mes/categoría.
  Future<PresupuestoMensual?> getPresupuestoMensual(int mes, int idCategoria);

  /// Actualiza el monto límite de un presupuesto mensual existente o crea uno nuevo.
  ///
  /// [presupuesto]: El objeto [PresupuestoMensual] con el monto límite actualizado
  /// o para crear un nuevo presupuesto.
  /// Retorna un `Future<void>` que se completa cuando la operación ha terminado.
  Future<void> savePresupuestoMensual(PresupuestoMensual presupuesto);
}
