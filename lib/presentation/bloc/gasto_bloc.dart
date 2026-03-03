import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/models/gasto.dart';
import '../../domain/models/categoria.dart'; // Importar Categoria
import '../../domain/models/tipo_categoria.dart'; // Importar TipoCategoria
import '../../domain/repositories/gasto_repository.dart';
import '../../domain/repositories/categoria_repository.dart'; // Importar CategoriaRepository
import 'gasto_event.dart';
import 'gasto_state.dart';

/// Clase auxiliar para almacenar los totales de ingresos, gastos y el total general.
class _Totals {
  final double total;
  final double income;
  final double expense;

  _Totals(this.total, this.income, this.expense);
}

/// Un BLoC (Business Logic Component) que maneja la lógica de negocio
/// relacionada con los gastos.
///
/// Se comunica con la capa de Dominio a través de [GastoRepository]
/// y [CategoriaRepository] para realizar operaciones de persistencia y cálculo.
class GastoBloc extends Bloc<GastoEvent, GastoState> {
  final GastoRepository _gastoRepository;
  final CategoriaRepository _categoriaRepository; // Nueva dependencia

  /// Constructor de [GastoBloc].
  ///
  /// Recibe instancias de [GastoRepository] y [CategoriaRepository] para interactuar
  /// con las fuentes de datos.
  /// Define el estado inicial como [GastoLoading].
  GastoBloc(this._gastoRepository, this._categoriaRepository) : super(const GastoLoading()) {
    // Registra los manejadores de eventos.
    on<LoadGastos>(_onLoadGastos);
    on<AddGasto>(_onAddGasto);
    on<DeleteGasto>(_onDeleteGasto);
  }

  /// Manejador del evento [LoadGastos].
  ///
  /// Este método se encarga de:
  /// 1. Emitir un estado [GastoLoading] para indicar que se están cargando los datos.
  /// 2. Obtener los gastos desde el [GastoRepository]. Si se proporcionan fechas, filtra por ellas.
  /// 3. Obtener todas las categorías desde el [CategoriaRepository] y crear un mapa para acceso rápido.
  /// 4. Calcular el total general, total de ingresos y total de gastos de los gastos cargados.
  /// 5. Emitir un estado [GastoLoaded] con la lista de gastos, todos los totales y el mapa de categorías.
  /// 6. Capturar cualquier error y emitir un estado [GastoError].
  Future<void> _onLoadGastos(LoadGastos event, Emitter<GastoState> emit) async {
    emit(const GastoLoading());
    try {
      // 1. Obtener gastos
      List<Gasto> gastos;
      DateTime startOfMonth;
      DateTime endOfMonth;

      if (event.startDate != null && event.endDate != null) {
        startOfMonth = event.startDate!;
        endOfMonth = event.endDate!;
      } else {
        final now = DateTime.now();
        startOfMonth = DateTime(now.year, now.month, 1);
        // Último día del mes actual, el '0' en el día crea el último día del mes anterior,
        // al sumarle 1 al mes, obtenemos el primer día del siguiente mes, y al poner 0, el último del actual.
        endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }
      gastos = await _gastoRepository.getGastosByDateRange(startOfMonth, endOfMonth);

      // 2. Obtener categorías y crear un mapa para acceso rápido
      final List<Categoria> categorias = await _categoriaRepository.getAllCategorias();
      final Map<int, Categoria> categoriasMap = {
        for (var categoria in categorias) categoria.id: categoria
      };

      // 3. Calcular totales
      final _Totals totals = _calculateTotals(gastos, categoriasMap);

      emit(GastoLoaded(
        gastos: gastos,
        totalMes: totals.total,
        incomeTotal: totals.income,
        expenseTotal: totals.expense,
        categoriasMap: categoriasMap,
      ));
    } catch (e) {
      emit(GastoError('Error al cargar gastos: $e'));
    }
  }

  /// Manejador del evento [AddGasto].
  ///
  /// Este método se encarga de:
  /// 1. Llamar al [GastoRepository] para guardar el nuevo gasto.
  /// 2. Una vez guardado, dispara un evento [LoadGastos] para recargar la lista
  ///    y actualizar la UI con el nuevo gasto y el total.
  /// 3. Capturar cualquier error y emitir un estado [GastoError].
  Future<void> _onAddGasto(AddGasto event, Emitter<GastoState> emit) async {
    try {
      await _gastoRepository.saveGasto(event.gasto);
      // Después de agregar, recarga los gastos para actualizar la UI
      add(LoadGastos());
    } catch (e) {
      emit(GastoError('Error al agregar gasto: $e'));
    }
  }

  /// Manejador del evento [DeleteGasto].
  ///
  /// Este método se encarga de:
  /// 1. Llamar al [GastoRepository] para eliminar el gasto por su ID.
  /// 2. Una vez eliminado, dispara un evento [LoadGastos] para recargar la lista
  ///    y actualizar la UI.
  /// 3. Capturar cualquier error y emitir un estado [GastoError].
  Future<void> _onDeleteGasto(DeleteGasto event, Emitter<GastoState> emit) async {
    try {
      await _gastoRepository.deleteGasto(event.id);
      // Después de eliminar, recarga los gastos para actualizar la UI
      add(LoadGastos());
    } catch (e) {
      emit(GastoError('Error al eliminar gasto: $e'));
    }
  }

  /// Calcula el monto total, total de ingresos y total de gastos de una lista de gastos.
  ///
  /// [gastos]: La lista de gastos a procesar.
  /// [categoriasMap]: Un mapa de categorías para determinar el tipo de cada gasto.
  /// Retorna un objeto [_Totals] con los montos calculados.
  _Totals _calculateTotals(List<Gasto> gastos, Map<int, Categoria> categoriasMap) {
    double total = 0.0;
    double income = 0.0;
    double expense = 0.0;

    for (var gasto in gastos) {
      final categoria = categoriasMap[gasto.idCategoria];
      if (categoria != null) {
        if (categoria.tipo == TipoCategoria.INGRESO) {
          income += gasto.monto;
        } else {
          // GASTO y OCIO se consideran gastos para el balance general
          expense += gasto.monto;
        }
      }
    }
    total = income - expense;
    return _Totals(total, income, expense);
  }
}