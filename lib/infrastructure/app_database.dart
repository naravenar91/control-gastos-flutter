// Importaciones necesarias para Drift y los modelos de dominio.
import 'package:drift/drift.dart';
import 'package:drift/native.dart'; // Importar para NativeDatabase
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';

import '../domain/models/categoria.dart' as domain_categoria;
import '../domain/models/gasto.dart' as domain_gasto;
import '../domain/models/presupuesto_mensual.dart' as domain_presupuesto;
import '../domain/models/tipo_categoria.dart' as domain_tipo_categoria;

// Configuración del target para la generación de código de Drift.
// Esto le dice a `drift_dev` qué archivos procesar.
part 'app_database.g.dart';

/// Definición de la tabla 'Categorias' para la base de datos.
///
/// Corresponde al modelo de dominio `Categoria`.
@DataClassName('CategoriaEntry') // Nombre de la clase de entidad generada
class Categorias extends Table {
  /// Columna para el ID de la categoría. Es la clave primaria y se auto-incrementa.
  IntColumn get id => integer().autoIncrement()();

  /// Columna para la descripción de la categoría. Es un campo de texto no nulo.
  TextColumn get descripcion => text()();

  /// Valor entero del color asociado a la categoría (ARGB).
  IntColumn get colorValue => integer()();

  /// Columna para el tipo de categoría (INGRESO, GASTO, OCIO).
  /// Se almacena como un entero que representa el índice del enum `TipoCategoria`.
  IntColumn get tipo => integer()();
}

/// Definición de la tabla 'Gastos' para la base de datos.
///
/// Corresponde al modelo de dominio `Gasto`.
@DataClassName('GastoEntry') // Nombre de la clase de entidad generada
class Gastos extends Table {
  /// Columna para el ID del gasto. Es la clave primaria y se auto-incrementa.
  IntColumn get id => integer().autoIncrement()();

  /// Columna para la descripción del gasto. Es un campo de texto no nulo.
  TextColumn get descripcion => text()();

  /// Columna para el monto del gasto. Es un número de punto flotante no nulo.
  RealColumn get monto => real()();

  /// Columna para la fecha del gasto. Se almacena como un entero (timestamp).
  DateTimeColumn get fecha => dateTime()();

  /// Columna que indica si el gasto está activo. Es un booleano no nulo.
  BoolColumn get activo => boolean()();

  /// Columna para el ID de la categoría a la que pertenece el gasto.
  /// Es una clave foránea que referencia a la tabla `Categorias`.
  IntColumn get idCategoria => integer().references(Categorias, #id)();

  /// Columna que indica si el gasto es fijo. Es un booleano no nulo.
  BoolColumn get esFijo => boolean()();

  /// Columna opcional para la fecha de inicio de un gasto fijo.
  DateTimeColumn get fechaInicio => dateTime().nullable()();

  /// Columna opcional para la fecha de fin de un gasto fijo.
  DateTimeColumn get fechaFin => dateTime().nullable()();
}

/// Definición de la tabla 'PresupuestosMensuales' para la base de datos.
///
/// Corresponde al modelo de dominio `PresupuestoMensual`.
@DataClassName('PresupuestoMensualEntry') // Nombre de la clase de entidad generada
class PresupuestosMensuales extends Table {
  /// Columna para el ID del presupuesto mensual. Es la clave primaria y se auto-incrementa.
  IntColumn get id => integer().autoIncrement()();

  /// Columna para el mes del presupuesto. Es un entero no nulo (1-12).
  IntColumn get mes => integer()();

  /// Columna para el ID de la categoría a la que aplica el presupuesto.
  /// Es una clave foránea que referencia a la tabla `Categorias`.
  IntColumn get idCategoria => integer().references(Categorias, #id)();

  /// Columna para el monto límite del presupuesto. Es un número de punto flotante no nulo.
  RealColumn get montoLimite => real()();

  /// Se define una clave única compuesta por mes e idCategoria
  /// para asegurar que no haya presupuestos duplicados para el mismo mes y categoría.
  @override
  List<Set<Column>> get uniqueKeys => [
        {mes, idCategoria},
      ];
}

/// Base de datos principal de la aplicación utilizando Drift.
///
/// Incluye las tablas definidas: `Categorias`, `Gastos`, `PresupuestosMensuales`.
@DriftDatabase(tables: [Categorias, Gastos, PresupuestosMensuales])
class AppDatabase extends _$AppDatabase {
  /// Constructor de la base de datos.
  ///
  /// Inicializa la conexión de la base de datos.
  AppDatabase() : super(_openConnection());

  /// Versión del esquema de la base de datos.
  ///
  /// Se utiliza para manejar migraciones de la base de datos.
  @override
  int get schemaVersion => 1;

  /// Estrategia de migración para la base de datos.
  ///
  /// Se ejecuta al crear la base de datos por primera vez.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();

          // Insertar categorías por defecto
          await batch((batch) {
            batch.insertAll(categorias, [
              CategoriasCompanion.insert(
                descripcion: 'Sueldo',
                colorValue: 0xFF4CAF50, // Verde para ingresos
                tipo: domain_tipo_categoria.TipoCategoria.ingreso.index,
              ),
              CategoriasCompanion.insert(
                descripcion: 'Crédito ',
                colorValue: 0xFFF44336, // Rojo
                tipo: domain_tipo_categoria.TipoCategoria.gasto.index,
              ),
              CategoriasCompanion.insert(
                descripcion: 'Ahorro',
                colorValue: 0xFF2196F3, // Azul
                tipo: domain_tipo_categoria.TipoCategoria.ahorro.index,
              )/*,
              CategoriasCompanion.insert(
                descripcion: 'Comida',
                colorValue: 0xFFFF9800, // Naranja para comida
                tipo: domain_tipo_categoria.TipoCategoria.gasto.index,
              )*/
            ]);
          });
        },
      );

  /// Método para abrir la conexión de la base de datos.
  ///
  /// Determina la ubicación de la base de datos según la plataforma
  /// (Android/iOS, Linux/Windows/macOS) y la inicializa.
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));

      // Manejo específico para Android/iOS para asegurar que SQLite esté disponible.
      if (Platform.isAndroid || Platform.isIOS) {
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      }

      return NativeDatabase.createInBackground(file);
    });
  }

  // --- Funcionalidad de Respaldo y Restauración ---

  /// Exporta todos los datos de la base de datos a un String JSON.
  Future<String> exportToJson() async {
    final allCategorias = await select(categorias).get();
    final allGastos = await select(gastos).get();
    final allPresupuestos = await select(presupuestosMensuales).get();

    final data = {
      'categorias': allCategorias.map((e) => e.toJson()).toList(),
      'gastos': allGastos.map((e) => e.toJson()).toList(),
      'presupuestos': allPresupuestos.map((e) => e.toJson()).toList(),
    };

    return jsonEncode(data);
  }

  /// Importa datos desde un String JSON a la base de datos, evitando duplicados.
  Future<void> importFromJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    await transaction(() async {
      // 1. Importar Categorías y crear mapa de ID antiguo -> ID nuevo
      final Map<int, int> categoriaIdMap = {};
      final List<dynamic> categoriasJson = data['categorias'] ?? [];

      for (final catJson in categoriasJson) {
        final entry = CategoriaEntry.fromJson(catJson);
        
        // Verificar si existe por descripción y tipo
        final existing = await (select(categorias)
              ..where((t) => t.descripcion.equals(entry.descripcion) & t.tipo.equals(entry.tipo)))
            .getSingleOrNull();

        if (existing != null) {
          categoriaIdMap[entry.id] = existing.id;
        } else {
          final newId = await into(categorias).insert(CategoriasCompanion.insert(
            descripcion: entry.descripcion,
            colorValue: entry.colorValue,
            tipo: entry.tipo,
          ));
          categoriaIdMap[entry.id] = newId;
        }
      }

      // 2. Importar Gastos
      final List<dynamic> gastosJson = data['gastos'] ?? [];
      for (final gastoJson in gastosJson) {
        final entry = GastoEntry.fromJson(gastoJson);
        final newIdCategoria = categoriaIdMap[entry.idCategoria];

        if (newIdCategoria != null) {
          // Verificar duplicado (misma desc, monto, fecha y categoria)
          final existing = await (select(gastos)
                ..where((t) =>
                    t.descripcion.equals(entry.descripcion) &
                    t.monto.equals(entry.monto) &
                    t.fecha.equals(entry.fecha) &
                    t.idCategoria.equals(newIdCategoria)))
              .getSingleOrNull();

          if (existing == null) {
            await into(gastos).insert(GastosCompanion.insert(
              descripcion: entry.descripcion,
              monto: entry.monto,
              fecha: entry.fecha,
              activo: entry.activo,
              idCategoria: newIdCategoria,
              esFijo: entry.esFijo,
            ));
          }
        }
      }

      // 3. Importar Presupuestos
      final List<dynamic> presupuestosJson = data['presupuestos'] ?? [];
      for (final presuJson in presupuestosJson) {
        final entry = PresupuestoMensualEntry.fromJson(presuJson);
        final newIdCategoria = categoriaIdMap[entry.idCategoria];

        if (newIdCategoria != null) {
          final existing = await (select(presupuestosMensuales)
                ..where((t) => t.mes.equals(entry.mes) & t.idCategoria.equals(newIdCategoria)))
              .getSingleOrNull();

          if (existing == null) {
            await into(presupuestosMensuales).insert(PresupuestosMensualesCompanion.insert(
              mes: entry.mes,
              idCategoria: newIdCategoria,
              montoLimite: entry.montoLimite,
            ));
          }
        }
      }
    });
  }
}

/// --- Mappers de Dominio a Drift y viceversa ---

/// Convierte un objeto `domain_categoria.Categoria` a un `CategoriasCompanion` para inserción/actualización en Drift.
CategoriasCompanion toCategoriasCompanion(domain_categoria.Categoria categoria) {
  return CategoriasCompanion(
    id: categoria.id == 0 ? const Value.absent() : Value(categoria.id),
    descripcion: Value(categoria.descripcion),
    colorValue: Value(categoria.colorValue),
    tipo: Value(categoria.tipo.index), // Almacena el índice del enum
  );
}

/// Convierte un `CategoriaEntry` (entidad generada por Drift) a un `domain_categoria.Categoria`.
domain_categoria.Categoria toDomainCategoria(CategoriaEntry entry) {
  return domain_categoria.Categoria(
    id: entry.id,
    descripcion: entry.descripcion,
    colorValue: entry.colorValue,
    tipo: domain_tipo_categoria.TipoCategoria.values[entry.tipo], // Recrea el enum desde el índice
  );
}

/// Convierte un objeto `domain_gasto.Gasto` a un `GastosCompanion` para inserción/actualización en Drift.
GastosCompanion toGastosCompanion(domain_gasto.Gasto gasto) {
  return GastosCompanion(
    id: gasto.id == 0 ? const Value.absent() : Value(gasto.id),
    descripcion: Value(gasto.descripcion),
    monto: Value(gasto.monto),
    fecha: Value(gasto.fecha),
    activo: Value(gasto.activo),
    idCategoria: Value(gasto.idCategoria),
    esFijo: Value(gasto.esFijo),
    fechaInicio: Value(gasto.fechaInicio),
    fechaFin: Value(gasto.fechaFin),
  );
}

/// Convierte un `GastoEntry` (entidad generada por Drift) a un `domain_gasto.Gasto`.
domain_gasto.Gasto toDomainGasto(GastoEntry entry) {
  return domain_gasto.Gasto(
    id: entry.id,
    descripcion: entry.descripcion,
    monto: entry.monto,
    fecha: entry.fecha,
    activo: entry.activo,
    idCategoria: entry.idCategoria,
    esFijo: entry.esFijo,
    fechaInicio: entry.fechaInicio,
    fechaFin: entry.fechaFin,
  );
}

/// Convierte un objeto `domain_presupuesto.PresupuestoMensual` a un `PresupuestosMensualesCompanion` para inserción/actualización en Drift.
PresupuestosMensualesCompanion toPresupuestosMensualesCompanion(domain_presupuesto.PresupuestoMensual presupuesto) {
  return PresupuestosMensualesCompanion(
    id: presupuesto.id == 0 ? const Value.absent() : Value(presupuesto.id),
    mes: Value(presupuesto.mes),
    idCategoria: Value(presupuesto.idCategoria),
    montoLimite: Value(presupuesto.montoLimite),
  );
}

/// Convierte un `PresupuestoMensualEntry` (entidad generada por Drift) a un `domain_presupuesto.PresupuestoMensual`.
domain_presupuesto.PresupuestoMensual toDomainPresupuestoMensual(PresupuestoMensualEntry entry) {
  return domain_presupuesto.PresupuestoMensual(
    id: entry.id,
    mes: entry.mes,
    idCategoria: entry.idCategoria,
    montoLimite: entry.montoLimite,
  );
}
