import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../domain/models/gasto.dart';
import '../../domain/models/categoria.dart';
import '../../domain/models/tipo_categoria.dart';

class PdfExportService {
  Future<void> exportToPdf(List<Gasto> gastos, List<Categoria> categorias, DateTime date) async {
    final pdf = pw.Document();
    final Map<int, Categoria> catMap = {for (var c in categorias) c.id: c};
    final String monthYear = DateFormat('MMMM yyyy', 'es_ES').format(date).toUpperCase();

    // Filtros
    final ingresos = gastos.where((g) => catMap[g.idCategoria]?.tipo == TipoCategoria.ingreso).toList();
    final ahorros = gastos.where((g) => catMap[g.idCategoria]?.tipo == TipoCategoria.ahorro).toList();
    final otrosGastos = gastos.where((g) => catMap[g.idCategoria]?.tipo == TipoCategoria.gasto || catMap[g.idCategoria]?.tipo == TipoCategoria.ocio).toList();

    double totalIngresos = ingresos.fold(0, (sum, item) => sum + item.monto);
    double totalAhorros = ahorros.fold(0, (sum, item) => sum + item.monto);
    double totalGastos = otrosGastos.fold(0, (sum, item) => sum + item.monto);
    double totalNeto = totalIngresos - (totalAhorros + totalGastos);

    final blueColor = PdfColor.fromHex('#0070C0');
    final greyColor = PdfColors.grey200;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('REPORTE MENSUAL FINANCIERO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: blueColor, fontSize: 18)),
                  pw.Text(monthYear, style: pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            _buildSection('INGRESOS', ingresos, blueColor, greyColor),
            pw.SizedBox(height: 10),
            _buildSection('AHORROS', ahorros, blueColor, greyColor),
            pw.SizedBox(height: 10),
            _buildSection('GASTOS', otrosGastos, blueColor, greyColor),
            
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('RESUMEN FINAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.SizedBox(height: 5),
                  pw.Text('Total Ingresos: ${_formatCurrency(totalIngresos)}'),
                  pw.Text('Total Ahorros: ${_formatCurrency(totalAhorros)}'),
                  pw.Text('Total Gastos: ${_formatCurrency(totalGastos)}'),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    color: PdfColors.amber100,
                    child: pw.Text('TOTAL NETO: ${_formatCurrency(totalNeto)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Reporte_${DateFormat('yyyy_MM').format(date)}.pdf');
  }

  pw.Widget _buildSection(String title, List<Gasto> items, PdfColor headerColor, PdfColor subHeaderColor) {
    double total = items.fold(0, (sum, item) => sum + item.monto);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(5),
          color: headerColor,
          child: pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(5),
            2: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: subHeaderColor),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Fecha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Descripción', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Monto', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            ...items.map((item) => pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(DateFormat('dd/MM/yyyy').format(item.fecha))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.descripcion)),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(item.monto), textAlign: pw.TextAlign.right)),
              ],
            )),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.amber50),
              children: [
                pw.Text(''),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('TOTAL $title', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(total), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'es_ES').format(amount);
  }
}
