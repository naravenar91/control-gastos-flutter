import 'package:drift/drift.dart' hide PresupuestoMensual; // Oculta PresupuestoMensual de drift para evitar conflicto con nuestro modelo de dominio

import '../../domain/models/presupuesto_mensual.dart';
import '../../domain/repositories/presupuesto_repository.dart';
import '../app_database.dart'; // Asegúrate de que esta ruta sea correcta

/// Implementación de [PresupuestoRepository] utilizando Drift para la persistencia de datos.
///
/// Esta clase se encarga de traducir las operaciones de repositorio
/// definidas en la capa de Dominio a operaciones concretas de base de datos
/// utilizando la librería Drift (SQLite).
class DriftPresupuestoRepository implements PresupuestoRepository {
  final AppDatabase _db;

  /// Constructor que inyecta la instancia de [AppDatabase].
  DriftPresupuestoRepository(this._db);

  @override
  Future<PresupuestoMensual?> getPresupuestoMensual(
      int mes, int idCategoria) async {
    // Consulta un presupuesto mensual específico por el mes y el ID de la categoría.
    // 'getSingleOrNull()' retorna el único resultado o null si no se encuentra.
    final presupuestoEntry = await (_db.select(_db.presupuestosMensuales)
          ..where((tbl) => tbl.mes.equals(mes) & tbl.idCategoria.equals(idCategoria)))
        .getSingleOrNull();

    // Si se encuentra la entrada, la convierte a un modelo de dominio 'PresupuestoMensual'.
    return presupuestoEntry != null
        ? toDomainPresupuestoMensual(presupuestoEntry)
        : null;
  }

  @override
  Future<void> savePresupuestoMensual(PresupuestoMensual presupuesto) async {
    // Convierte el modelo de dominio PresupuestoMensual a un PresupuestosMensualesCompanion
    // (objeto de Drift) y lo inserta/actualiza en la tabla 'presupuestosMensuales'.
    // `insertOnConflictUpdate` permite insertar si no existe, o actualizar si ya existe (por mes e idCategoria).
    await _db.into(_db.presupuestosMensuales)
        .insertOnConflictUpdate(toPresupuestosMensualesCompanion(presupuesto));
  }
}
