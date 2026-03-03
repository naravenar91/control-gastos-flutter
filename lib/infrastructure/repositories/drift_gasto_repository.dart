import 'package:drift/drift.dart' hide Gasto; // Oculta Gasto de drift para evitar conflicto con nuestro modelo de dominio

import '../../domain/models/gasto.dart';
import '../../domain/repositories/gasto_repository.dart';
import '../app_database.dart'; // Asegúrate de que esta ruta sea correcta

/// Implementación de [GastoRepository] utilizando Drift para la persistencia de datos.
///
/// Esta clase se encarga de traducir las operaciones de repositorio
/// definidas en la capa de Dominio a operaciones concretas de base de datos
/// utilizando la librería Drift (SQLite).
class DriftGastoRepository implements GastoRepository {
  final AppDatabase _db;

  /// Constructor que inyecta la instancia de [AppDatabase].
  DriftGastoRepository(this._db);

  @override
  Future<void> saveGasto(Gasto gasto) async {
    // Convierte el modelo de dominio Gasto a un GastosCompanion (objeto de Drift)
    // y lo inserta/actualiza en la tabla 'gastos'.
    // `insertOnConflictUpdate` permite insertar si no existe, o actualizar si ya existe (por ID).
    await _db.into(_db.gastos).insertOnConflictUpdate(toGastosCompanion(gasto));
  }

  @override
  Future<void> deleteGasto(int id) async {
    // Elimina un gasto de la tabla 'gastos' basándose en su ID.
    await (_db.delete(_db.gastos)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<List<Gasto>> getGastosByDateRange(
      DateTime startDate, DateTime endDate) async {
    // Consulta los gastos que se encuentran dentro de un rango de fechas.
    // 'isBetween' es un comparador de Drift para rangos de fechas.
    final gastoEntries = await (_db.select(_db.gastos)
          ..where((tbl) => tbl.fecha.isBetween(Variable(startDate), Variable(endDate))))
        .get();
    return gastoEntries.map((entry) => toDomainGasto(entry)).toList();
  }

  @override
  Future<List<Gasto>> getGastosByCategoria(int idCategoria) async {
    // Consulta los gastos filtrando por el ID de la categoría.
    final gastoEntries = await (_db.select(_db.gastos)
          ..where((tbl) => tbl.idCategoria.equals(idCategoria)))
        .get();
    return gastoEntries.map((entry) => toDomainGasto(entry)).toList();
  }
}
