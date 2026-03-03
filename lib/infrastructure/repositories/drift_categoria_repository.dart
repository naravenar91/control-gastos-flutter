import 'package:drift/drift.dart';

import '../../domain/models/categoria.dart';
import '../../domain/repositories/categoria_repository.dart';
import '../app_database.dart'; // Asegúrate de que esta ruta sea correcta

/// Implementación de [CategoriaRepository] utilizando Drift para la persistencia de datos.
///
/// Esta clase se encarga de traducir las operaciones de repositorio
/// definidas en la capa de Dominio a operaciones concretas de base de datos
/// utilizando la librería Drift (SQLite).
class DriftCategoriaRepository implements CategoriaRepository {
  final AppDatabase _db;

  /// Constructor que inyecta la instancia de [AppDatabase].
  DriftCategoriaRepository(this._db);

  @override
  Future<List<Categoria>> getAllCategorias() async {
    // Realiza una consulta para obtener todas las categorías de la tabla 'categorias'.
    // Luego, mapea cada 'CategoriaEntry' (generado por Drift) a un modelo de dominio 'Categoria'.
    final categoriaEntries = await _db.select(_db.categorias).get();
    return categoriaEntries.map((entry) => toDomainCategoria(entry)).toList();
  }

  @override
  Future<Categoria?> getCategoriaById(int id) async {
    // Realiza una consulta para obtener una categoría específica por su ID.
    // Utiliza el método 'where' para filtrar por el ID de la columna.
    // 'getSingleOrNull()' retorna el único resultado o null si no se encuentra.
    final categoriaEntry = await (_db.select(_db.categorias)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();

    // Si se encuentra la entrada, la convierte a un modelo de dominio 'Categoria'.
    return categoriaEntry != null ? toDomainCategoria(categoriaEntry) : null;
  }
}
