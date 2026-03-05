import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/gasto_repository.dart';
import '../../domain/repositories/categoria_repository.dart';
import '../../infrastructure/services/excel_export_service.dart';

// Events
abstract class ExportEvent extends Equatable {
  const ExportEvent();
  @override
  List<Object?> get props => [];
}

class ExportToExcelEvent extends ExportEvent {
  final DateTime date;
  const ExportToExcelEvent(this.date);
  @override
  List<Object?> get props => [date];
}

// States
abstract class ExportState extends Equatable {
  const ExportState();
  @override
  List<Object?> get props => [];
}

class ExportInitial extends ExportState {}
class ExportLoading extends ExportState {}
class ExportSuccess extends ExportState {
  final String path;
  const ExportSuccess(this.path);
  @override
  List<Object?> get props => [path];
}
class ExportError extends ExportState {
  final String message;
  const ExportError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final GastoRepository gastoRepository;
  final CategoriaRepository categoriaRepository;
  final ExcelExportService excelExportService;

  ExportBloc({
    required this.gastoRepository,
    required this.categoriaRepository,
    required this.excelExportService,
  }) : super(ExportInitial()) {
    on<ExportToExcelEvent>(_onExportToExcel);
  }

  Future<void> _onExportToExcel(ExportToExcelEvent event, Emitter<ExportState> emit) async {
    emit(ExportLoading());
    try {
      final startDate = DateTime(event.date.year, event.date.month, 1);
      final endDate = DateTime(event.date.year, event.date.month + 1, 0);

      final gastos = await gastoRepository.getGastosByDateRange(startDate, endDate);
      final categorias = await categoriaRepository.getAllCategorias();

      if (gastos.isEmpty) {
        emit(const ExportError('No hay datos para exportar en este mes'));
        return;
      }

      final path = await excelExportService.exportToExcel(gastos, categorias, event.date);
      emit(ExportSuccess(path));
    } catch (e) {
      emit(ExportError('Error al exportar: ${e.toString()}'));
    }
  }
}
