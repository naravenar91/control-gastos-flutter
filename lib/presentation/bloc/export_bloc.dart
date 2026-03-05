import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/gasto_repository.dart';
import '../../domain/repositories/categoria_repository.dart';
import '../../infrastructure/services/excel_export_service.dart';
import '../../infrastructure/services/pdf_export_service.dart';

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

class ExportToPdfEvent extends ExportEvent {
  final DateTime date;
  const ExportToPdfEvent(this.date);
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
  final bool isPdf;
  const ExportSuccess(this.path, {this.isPdf = false});
  @override
  List<Object?> get props => [path, isPdf];
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
  final PdfExportService pdfExportService;

  ExportBloc({
    required this.gastoRepository,
    required this.categoriaRepository,
    required this.excelExportService,
    required this.pdfExportService,
  }) : super(ExportInitial()) {
    on<ExportToExcelEvent>(_onExportToExcel);
    on<ExportToPdfEvent>(_onExportToPdf);
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
      emit(ExportError('Error al exportar a Excel: ${e.toString()}'));
    }
  }

  Future<void> _onExportToPdf(ExportToPdfEvent event, Emitter<ExportState> emit) async {
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

      await pdfExportService.exportToPdf(gastos, categorias, event.date);
      emit(const ExportSuccess('', isPdf: true));
    } catch (e) {
      emit(ExportError('Error al exportar a PDF: ${e.toString()}'));
    }
  }
}
