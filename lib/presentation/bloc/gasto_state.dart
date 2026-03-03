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

/// Estado cuando los gastos se han cargado exitosamente.
class GastoLoaded extends GastoState {
  final List<Gasto> gastos;
  final double totalMes;
  final double incomeTotal; // Total de ingresos
  final double expenseTotal; // Total de gastos
  final Map<int, Categoria> categoriasMap; // Mapa de categorías por ID

  const GastoLoaded({
    this.gastos = const [],
    this.totalMes = 0.0,
    this.incomeTotal = 0.0,
    this.expenseTotal = 0.0,
    this.categoriasMap = const {},
  });

  @override
  List<Object> get props => [
        gastos,
        totalMes,
        incomeTotal,
        expenseTotal,
        categoriasMap,
      ];
}

/// Estado cuando ocurre un error al cargar o procesar los gastos.
class GastoError extends GastoState {
  final String message;

  const GastoError(this.message);

  @override
  List<Object> get props => [message];
}