import 'package:equatable/equatable.dart';
import '../../domain/models/gasto.dart';

/// Clase base abstracta para todos los eventos relacionados con los gastos.
///
/// Extiende [Equatable] para permitir la comparación de eventos por valor.
abstract class GastoEvent extends Equatable {
  const GastoEvent();

  @override
  List<Object> get props => [];
}

/// Evento para solicitar la carga de todos los gastos.
///
/// Puede incluir un rango de fechas opcional para filtrar los gastos.
class LoadGastos extends GastoEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadGastos({this.startDate, this.endDate});

  @override
  List<Object> get props => [startDate ?? '', endDate ?? ''];
}

/// Evento para agregar un nuevo gasto.
class AddGasto extends GastoEvent {
  final Gasto gasto;

  const AddGasto(this.gasto);

  @override
  List<Object> get props => [gasto];
}

/// Evento para eliminar un gasto existente.
class DeleteGasto extends GastoEvent {
  final int id;

  const DeleteGasto(this.id);

  @override
  List<Object> get props => [id];
}
