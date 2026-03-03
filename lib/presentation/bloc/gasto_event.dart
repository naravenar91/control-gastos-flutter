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
/// Filtra los gastos por el mes y año del [month] proporcionado.
class LoadGastos extends GastoEvent {
  final DateTime month;

  const LoadGastos(this.month);

  @override
  List<Object> get props => [month];
}

/// Evento para agregar un nuevo gasto.
class AddGasto extends GastoEvent {
  final Gasto gasto;

  const AddGasto(this.gasto);

  @override
  List<Object> get props => [gasto];
}

/// Evento para actualizar un gasto existente.
class UpdateGasto extends GastoEvent {
  final Gasto gasto;

  const UpdateGasto(this.gasto);

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
