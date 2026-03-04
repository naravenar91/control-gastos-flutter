import 'package:drift/drift.dart';

import '../../domain/models/categoria.dart';
import '../../domain/models/tipo_categoria.dart';
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
    final categoriaEntries = await _db.select(_db.categorias).get();
    final categorias = categoriaEntries.map((entry) => toDomainCategoria(entry)).toList();
    return _sortCategorias(categorias);
  }

  @override
  Stream<List<Categoria>> watchAllCategorias() {
    return _db.select(_db.categorias).watch().map((entries) {
      final categorias = entries.map((entry) => toDomainCategoria(entry)).toList();
      return _sortCategorias(categorias);
    });
  }

  /// Lógica de ordenamiento personalizada:
  /// 1° Sueldo (o ingresos principales)
  /// 2° Crédito (o gastos fijos)
  /// 3° Ahorro
  /// 4° Alfabético
  List<Categoria> _sortCategorias(List<Categoria> lista) {
    lista.sort((a, b) {
      int getPriority(Categoria c) {
        final desc = c.descripcion.toLowerCase();
        // 1° Ingreso principal (Sueldo)
        if (c.tipo == TipoCategoria.ingreso || desc.contains('sueldo')) return 1;
        // 2° Gasto importante (Crédito)
        if (desc.contains('crédito') || desc.contains('credito')) return 2;
        // 3° Ahorro
        if (c.tipo == TipoCategoria.ahorro) return 3;
        // 4° El resto
        return 4;
      }

      final pA = getPriority(a);
      final pB = getPriority(b);

      if (pA != pB) {
        return pA.compareTo(pB);
      }
      
      // Orden alfabético si tienen la misma prioridad
      return a.descripcion.toLowerCase().compareTo(b.descripcion.toLowerCase());
    });
    return lista;
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

  @override
  Future<int> insertCategoria(Categoria categoria) async {
    // Inserta una nueva categoría en la tabla 'categorias'.
    // Convierte el objeto de dominio a un 'CategoriasCompanion' para Drift.
    return await _db.into(_db.categorias).insert(toCategoriasCompanion(categoria));
  }

  @override
  Future<void> updateCategoria(Categoria categoria) async {
    // Actualiza una categoría existente en la tabla 'categorias'.
    // Utiliza el método 'replace' que busca por la clave primaria (ID).
    await _db.update(_db.categorias).replace(toCategoriasCompanion(categoria));
  }

  @override
  Future<bool> canDeleteCategoria(int id) async {
    // Verifica si hay gastos asociados a esta categoría.
    final countExp = _db.selectOnly(_db.gastos)..addColumns([_db.gastos.id.count()]);
    countExp.where(_db.gastos.idCategoria.equals(id));
    final result = await countExp.map((row) => row.read(_db.gastos.id.count())).getSingle();
    return (result ?? 0) == 0;
  }

  @override
  Future<void> deleteCategoria(int id) async {
    // Elimina la categoría de la tabla 'categorias'.
    await (_db.delete(_db.categorias)..where((tbl) => tbl.id.equals(id))).go();
  }
}
