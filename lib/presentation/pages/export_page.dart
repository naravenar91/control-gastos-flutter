import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../infrastructure/app_database.dart';
import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_event.dart';

class ExportPage extends StatelessWidget {
  const ExportPage({super.key});

  Future<void> _generateBackup(BuildContext context) async {
    try {
      final db = context.read<AppDatabase>();
      final jsonData = await db.exportToJson();
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/mibilletera_backup.json');
      await file.writeAsString(jsonData);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'MiBilletera - Respaldo de datos',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar respaldo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        
        if (context.mounted) {
          final db = context.read<AppDatabase>();
          
          // Mostrar diálogo de progreso o confirmación
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Restaurar Datos'),
              content: const Text('¿Deseas importar los datos desde este archivo? Los registros existentes no se borrarán, solo se añadirán los nuevos.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('RESTAURAR')),
              ],
            ),
          );

          if (confirm == true && context.mounted) {
            await db.importFromJson(jsonString);
            
            // Recargar datos en el BLoC
            if (context.mounted) {
              context.read<GastoBloc>().add(LoadGastos(DateTime.now()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos restaurados con éxito'), backgroundColor: Colors.green),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al restaurar datos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar y Respaldo'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.import_export, size: 80, color: Colors.blueGrey),
                      const SizedBox(height: 24),
                      const Text(
                        'Seleccione una opción para gestionar sus datos',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 40),
                      
                      // --- Sección de Exportación ---
                      const Text('REPORTES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const Divider(),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implementar exportación a PDF
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar a PDF'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implementar exportación a CSV
                        },
                        icon: const Icon(Icons.table_view),
                        label: const Text('Exportar a CSV/Excel'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      ),
                      
                      // Espaciador para empujar la siguiente sección al fondo
                      const Spacer(),
                      
                      const SizedBox(height: 40),
                      
                      // --- Sección de Respaldo ---
                      const Text('RESPALDO COMPLETO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const Divider(),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _generateBackup(context),
                        icon: const Icon(Icons.backup),
                        label: const Text('Generar Respaldo (JSON)'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _restoreData(context),
                        icon: const Icon(Icons.restore),
                        label: const Text('Restaurar Datos'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: BorderSide(color: Colors.indigo.shade700),
                          foregroundColor: Colors.indigo.shade700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'El respaldo permite transferir todos sus datos a otro dispositivo compatible.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      // Margen inferior para no chocar con el navbar
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
