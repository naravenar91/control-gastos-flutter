import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/models/gasto.dart';
import '../../domain/models/categoria.dart'; // Importar Categoria
import '../../domain/models/tipo_categoria.dart'; // Importar TipoCategoria
import '../../domain/repositories/gasto_repository.dart';
import '../../domain/repositories/categoria_repository.dart'; // Importar CategoriaRepository
import 'gasto_event.dart';
import 'gasto_state.dart';

/// Clase auxiliar para almacenar los totales de ingresos, gastos, ahorros y el total general.
class _Totals {
  final double total;
  final double income;
  final double expense;
  final double savings;

  _Totals(this.total, this.income, this.expense, this.savings);
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
    on<UpdateGasto>(_onUpdateGasto);
    on<DeleteGasto>(_onDeleteGasto);
    on<DeleteGroupGasto>(_onDeleteGroupGasto);
    on<LoadAnnualData>(_onLoadAnnualData);
  }

  /// Manejador del evento [DeleteGroupGasto].
  Future<void> _onDeleteGroupGasto(DeleteGroupGasto event, Emitter<GastoState> emit) async {
    try {
      final currentState = state;
      // Realizamos el borrado secuencial (Drift maneja bien las transacciones internas)
      for (final id in event.ids) {
        await _gastoRepository.deleteGasto(id);
      }
      
      if (currentState is GastoLoaded) {
        add(LoadGastos(currentState.selectedMonth));
      } else {
        add(LoadGastos(DateTime.now()));
      }
    } catch (e) {
      emit(GastoError('Error al eliminar el grupo: $e'));
    }
  }

  /// Manejador del evento [LoadAnnualData].
  Future<void> _onLoadAnnualData(LoadAnnualData event, Emitter<GastoState> emit) async {
    final currentState = state;
    if (currentState is GastoLoaded && currentState.annualTotals.isNotEmpty && currentState.selectedMonth.year == event.year) {
      return; // Ya tenemos los datos anuales para este año
    }

    try {
      final DateTime startOfYear = DateTime(event.year, 1, 1);
      final DateTime endOfYear = DateTime(event.year, 12, 31, 23, 59, 59);

      // 1. Obtener categorías
      final List<Categoria> categorias = await _categoriaRepository.getAllCategorias();
      final Map<int, Categoria> categoriasMap = {
        for (var categoria in categorias) categoria.id: categoria
      };

      // 2. Obtener todos los gastos del año
      final List<Gasto> annualGastos = await _gastoRepository.getGastosByDateRange(startOfYear, endOfYear);

      // 3. Agrupar por mes y calcular totales
      final Map<int, MonthlySummary> annualTotals = {};
      for (int month = 1; month <= 12; month++) {
        final DateTime startOfMonth = DateTime(event.year, month, 1);
        final DateTime endOfMonth = DateTime(event.year, month + 1, 0, 23, 59, 59);
        
        // Filtrar gastos que aplican a este mes (incluyendo fijos)
        final monthGastos = annualGastos.where((g) {
          if (g.esFijo) {
            return (g.fechaInicio == null || g.fechaInicio!.isBefore(endOfMonth)) &&
                   (g.fechaFin == null || g.fechaFin!.isAfter(startOfMonth));
          }
          return g.fecha.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) && 
                 g.fecha.isBefore(endOfMonth.add(const Duration(seconds: 1)));
        }).toList();

        final _Totals totals = _calculateTotals(monthGastos, categoriasMap);
        annualTotals[month] = MonthlySummary(
          income: totals.income,
          expense: totals.expense,
          savings: totals.savings,
          balance: totals.total,
        );
      }

      if (currentState is GastoLoaded) {
        emit(GastoLoaded(
          gastos: currentState.gastos,
          totalMes: currentState.totalMes,
          incomeTotal: currentState.incomeTotal,
          expenseTotal: currentState.expenseTotal,
          savingsTotal: currentState.savingsTotal,
          categoriasMap: currentState.categoriasMap,
          selectedMonth: currentState.selectedMonth,
          annualTotals: annualTotals,
        ));
      } else {
        // Si no hay estado previo, cargamos el mes actual también
        add(LoadGastos(DateTime(event.year, DateTime.now().month)));
      }
    } catch (e) {
      emit(GastoError('Error al cargar datos anuales: $e'));
    }
  }

  /// Manejador del evento [LoadGastos].
  ///
  /// Este método se encarga de:
  /// 1. Emitir un estado [GastoLoading] para indicar que se están cargando los datos.
  /// 2. Obtener todas las categorías primero para poder usarlas en la transformación y ordenamiento.
  /// 3. Obtener los gastos desde el [GastoRepository] filtrados por el mes seleccionado.
  /// 4. Transformar gastos fijos para que tengan la fecha del mes actual.
  /// 5. Ordenar: Ingresos arriba, luego por monto descendente.
  /// 6. Calcular totales incluyendo ahorros.
  /// 7. Emitir un estado [GastoLoaded] con todos los datos.
  /// 8. Capturar cualquier error y emitir un estado [GastoError].
  Future<void> _onLoadGastos(LoadGastos event, Emitter<GastoState> emit) async {
    emit(const GastoLoading());
    try {
      // 1. Obtener datos básicos
      final DateTime selectedDate = event.month;
      final DateTime startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
      final DateTime endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);

      // 2. Obtener categorías primero para poder usarlas en la transformación y ordenamiento
      final List<Categoria> categorias = await _categoriaRepository.getAllCategorias();
      final Map<int, Categoria> categoriasMap = {
        for (var categoria in categorias) categoria.id: categoria
      };

      // 3. Obtener registros de la base de datos
      final List<Gasto> rawGastos = await _gastoRepository.getGastosByDateRange(startOfMonth, endOfMonth);

      // 4. Transformar gastos fijos para que tengan la fecha del mes actual
      final List<Gasto> gastos = rawGastos.map((g) {
        if (g.esFijo) {
          int day = g.fecha.day;
          final lastDayOfSelectedMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
          if (day > lastDayOfSelectedMonth) day = lastDayOfSelectedMonth;
          return g.copyWith(fecha: DateTime(selectedDate.year, selectedDate.month, day));
        }
        return g;
      }).toList();

      // 5. Ordenar: Ingresos arriba, luego por monto descendente
      gastos.sort((a, b) {
        final catA = categoriasMap[a.idCategoria];
        final catB = categoriasMap[b.idCategoria];
        
        // Determinar "peso" del tipo (Ingreso = 0, Ahorro = 1, Gasto/Ocio = 2)
        int getTypeOrder(TipoCategoria? tipo) {
          if (tipo == TipoCategoria.ingreso) return 0;
          if (tipo == TipoCategoria.ahorro) return 1;
          return 2;
        }

        final int typeOrderA = getTypeOrder(catA?.tipo);
        final int typeOrderB = getTypeOrder(catB?.tipo);

        if (typeOrderA != typeOrderB) {
          return typeOrderA.compareTo(typeOrderB);
        }
        
        // Si son del mismo grupo, ordenar por monto desc
        return b.monto.compareTo(a.monto);
      });

      // 6. Calcular totales
      final _Totals totals = _calculateTotals(gastos, categoriasMap);

      emit(GastoLoaded(
        gastos: gastos,
        totalMes: totals.total,
        incomeTotal: totals.income,
        expenseTotal: totals.expense,
        savingsTotal: totals.savings,
        categoriasMap: categoriasMap,
        selectedMonth: selectedDate,
      ));
    } catch (e) {
      emit(GastoError('Error al cargar gastos: $e'));
    }
  }

  /// Manejador del evento [AddGasto].
  Future<void> _onAddGasto(AddGasto event, Emitter<GastoState> emit) async {
    try {
      await _gastoRepository.saveGasto(event.gasto);
      add(LoadGastos(event.gasto.fecha));
    } catch (e) {
      emit(GastoError('Error al agregar registro: $e'));
    }
  }

  /// Manejador del evento [UpdateGasto].
  Future<void> _onUpdateGasto(UpdateGasto event, Emitter<GastoState> emit) async {
    try {
      await _gastoRepository.saveGasto(event.gasto);
      add(LoadGastos(event.gasto.fecha));
    } catch (e) {
      emit(GastoError('Error al actualizar registro: $e'));
    }
  }

  /// Manejador del evento [DeleteGasto].
  Future<void> _onDeleteGasto(DeleteGasto event, Emitter<GastoState> emit) async {
    try {
      final currentState = state;
      await _gastoRepository.deleteGasto(event.id);
      
      if (currentState is GastoLoaded) {
        add(LoadGastos(currentState.selectedMonth));
      } else {
        add(LoadGastos(DateTime.now()));
      }
    } catch (e) {
      emit(GastoError('Error al eliminar registro: $e'));
    }
  }

  /// Calcula el monto total (saldo restante), total de ingresos, total de gastos y ahorros.
  ///
  /// Siguiendo la lógica financiera:
  /// Saldo (Disponible) = Total Ingresos - Total Gastos - Total Ahorros.
  _Totals _calculateTotals(List<Gasto> gastos, Map<int, Categoria> categoriasMap) {
    double incomeTotal = 0.0;
    double expenseTotal = 0.0;
    double savingsTotal = 0.0;

    for (var gasto in gastos) {
      final categoria = categoriasMap[gasto.idCategoria];
      if (categoria != null) {
        switch (categoria.tipo) {
          case TipoCategoria.ingreso:
            incomeTotal += gasto.monto;
            break;
          case TipoCategoria.ahorro:
            savingsTotal += gasto.monto;
            break;
          case TipoCategoria.gasto:
          case TipoCategoria.ocio:
            expenseTotal += gasto.monto;
            break;
        }
      }
    }

    // Saldo (Disponible) es lo que sobra después de gastos y ahorros.
    final double saldoRestante = incomeTotal - expenseTotal - savingsTotal;
    
    return _Totals(saldoRestante, incomeTotal, expenseTotal, savingsTotal);
  }
}
