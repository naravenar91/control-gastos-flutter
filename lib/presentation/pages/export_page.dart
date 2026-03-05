import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../bloc/export_bloc.dart';

class ExportPage extends StatelessWidget {
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Reportes'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.description_outlined, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 24),
              const Text(
                'Genera reportes detallados de tus finanzas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              
              const Text('FORMATOS DISPONIBLES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const Divider(),
              const SizedBox(height: 16),
              
              BlocConsumer<ExportBloc, ExportState>(
                listener: (context, state) {
                  if (state is ExportError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                    );
                  } else if (state is ExportSuccess) {
                    if (state.isPdf) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF compartido correctamente')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Reporte generado con éxito'),
                          action: SnackBarAction(
                            label: 'COMPARTIR',
                            textColor: Colors.white,
                            onPressed: () {
                              Share.shareXFiles([XFile(state.path)], text: 'Mi reporte mensual');
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
                builder: (context, state) {
                  final isLoading = state is ExportLoading;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => context.read<ExportBloc>().add(ExportToPdfEvent(DateTime.now())),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar a PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => context.read<ExportBloc>().add(ExportToExcelEvent(DateTime.now())),
                        icon: const Icon(Icons.table_view),
                        label: const Text('Exportar a Excel'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 24.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
