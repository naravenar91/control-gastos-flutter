import 'package:flutter/material.dart';

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
              
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementar exportación a PDF
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función PDF en desarrollo')),
                  );
                },
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
                onPressed: () {
                  // TODO: Implementar exportación a CSV
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función CSV/Excel en desarrollo')),
                  );
                },
                icon: const Icon(Icons.table_view),
                label: const Text('Exportar a CSV/Excel'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              
              const SizedBox(height: 40),
              /*const Card(
                color: Color(0xFFFFF9C4), // Amarillo suave informativo
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Las funciones de Respaldo y Restauración se han movido a la pestaña de Ajustes.',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}
