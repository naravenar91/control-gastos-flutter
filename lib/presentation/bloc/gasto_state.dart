import 'package:equatable/equatable.dart';
import '../../domain/models/gasto.dart';
import '../../domain/models/categoria.dart'; // Importar Categoria
import '../../domain/models/tipo_categoria.dart'; // Importar TipoCategoria

/// Clase base abstracta para todos los estados relacionados con los gastos.
///
/// Extiende [Equatable] para permitir la comparación de estados por valor.
abstract class GastoState extends Equatable {
  const GastoState();

  @override
  List<Object> get props => [];
}

/// Estado inicial cuando los gastos están siendo cargados.
class GastoLoading extends GastoState {
  const GastoLoading();
}

/// Clase para representar los totales de un mes específico.
class MonthlySummary {
  final double income;
  final double expense;
  final double savings;
  final double balance;

  const MonthlySummary({
    required this.income,
    required this.expense,
    required this.savings,
    required this.balance,
  });
}

/// Estado cuando los gastos se han cargado exitosamente.
class GastoLoaded extends GastoState {
  final List<Gasto> gastos;
  final double totalMes;
  final double incomeTotal; // Total de ingresos
  final double expenseTotal; // Total de gastos
  final double savingsTotal; // Total de ahorros
  final Map<int, Categoria> categoriasMap; // Mapa de categorías por ID
  final DateTime selectedMonth; // Mes seleccionado actual
  final Map<int, MonthlySummary> annualTotals; // Totales por mes (1-12) del año actual

  const GastoLoaded({
    this.gastos = const [],
    this.totalMes = 0.0,
    this.incomeTotal = 0.0,
    this.expenseTotal = 0.0,
    this.savingsTotal = 0.0,
    this.categoriasMap = const {},
    required this.selectedMonth,
    this.annualTotals = const {},
  });

  @override
  List<Object> get props => [
        gastos,
        totalMes,
        incomeTotal,
        expenseTotal,
        savingsTotal,
        categoriasMap,
        selectedMonth,
        annualTotals,
      ];
}

/// Estado cuando ocurre un error al cargar o procesar los gastos.
class GastoError extends GastoState {
  final String message;

  const GastoError(this.message);

  @override
  List<Object> get props => [message];
}
