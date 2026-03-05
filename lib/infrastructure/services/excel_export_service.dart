import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/gasto.dart';
import '../../domain/models/categoria.dart';
import '../../domain/models/tipo_categoria.dart';

class ExcelExportService {
  Future<String> exportToExcel(List<Gasto> gastos, List<Categoria> categorias, DateTime date) async {
    final excel = Excel.createExcel();
    final sheetName = DateFormat('MMMM yyyy', 'es_ES').format(date).toUpperCase();
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final Map<int, Categoria> catMap = {for (var c in categorias) c.id: c};

    // Geometría de Celdas: A: 15, B: 45, C: 20
    sheet.setColumnWidth(0, 15.0);
    sheet.setColumnWidth(1, 45.0);
    sheet.setColumnWidth(2, 20.0);

    const String blueHeader = '#FF0070C0';
    const String greySubHeader = '#EEEEEE';
    const String yellowSectionTotal = '#FFF9C4';
    const String orangeNetTotal = '#FFE0B2';

    int currentRow = 0;
    int? incomeRowIdx;
    int? savingsRowIdx;
    int? expensesRowIdx;

    // --- SECCIÓN INGRESOS ---
    final ingresos = gastos.where((g) => catMap[g.idCategoria]?.tipo == TipoCategoria.ingreso).toList();
    incomeRowIdx = _addSection(sheet, 'INGRESOS', ingresos, currentRow, blueHeader, greySubHeader, yellowSectionTotal);
    currentRow = incomeRowIdx + 2;

    // --- SECCIÓN AHORROS ---
    final ahorros = gastos.where((g) => catMap[g.idCategoria]?.tipo == TipoCategoria.ahorro).toList();
    savingsRowIdx = _addSection(sheet, 'AHORROS', ahorros, currentRow, blueHeader, greySubHeader, yellowSectionTotal);
    currentRow = savingsRowIdx + 2;

    // --- SECCIÓN GASTOS ---
    final otrosGastos = gastos.where((g) => catMap[g.idCategoria]?.tipo == TipoCategoria.gasto || catMap[g.idCategoria]?.tipo == TipoCategoria.ocio).toList();
    expensesRowIdx = _addSection(sheet, 'GASTOS', otrosGastos, currentRow, blueHeader, greySubHeader, yellowSectionTotal);
    currentRow = expensesRowIdx + 2;

    // --- TOTAL NETO (FÓRMULA) ---
    String cellInc = "C${incomeRowIdx + 1}";
    String cellSav = "C${savingsRowIdx + 1}";
    String cellExp = "C${expensesRowIdx + 1}";

    // Label
    var netLabelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
    netLabelCell.value = TextCellValue('TOTAL NETO');
    _applyStyle(netLabelCell, backgroundColor: blueHeader, isBold: true, textColor: '#FFFFFF');

    // Value con Fórmula
    var netValueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
    netValueCell.value = FormulaCellValue("=$cellInc-($cellSav+$cellExp)");
    _applyStyle(netValueCell, backgroundColor: orangeNetTotal, isBold: true, isNumeric: true);

    // Guardar archivo
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Reporte_${DateFormat('yyyy_MM').format(date)}.xlsx';
    final filePath = '${directory.path}/$fileName';
    final fileBytes = excel.save();

    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      return filePath;
    } else {
      throw Exception('No se pudo generar el archivo Excel');
    }
  }

  int _addSection(Sheet sheet, String title, List<Gasto> items, int startRow, String headerColor, String subHeaderColor, String totalColor) {
    // Título de Sección
    for (int i = 0; i < 3; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow));
      if (i == 0) cell.value = TextCellValue(title);
      _applyStyle(cell, backgroundColor: headerColor, isBold: true, textColor: '#FFFFFF');
    }
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: startRow));

    startRow++;
    // Sub-encabezados (Fecha, Descripción, Monto)
    List<String> headers = ['Fecha', 'Descripción', 'Monto'];
    for (int i = 0; i < 3; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow));
      cell.value = TextCellValue(headers[i]);
      _applyStyle(cell, backgroundColor: subHeaderColor, isBold: true);
    }
    
    startRow++;
    double total = 0;
    
    if (items.isEmpty) {
      for (int i = 0; i < 3; i++) {
        _applyStyle(sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow)));
      }
      startRow++;
    } else {
      for (var item in items) {
        var cellFecha = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow));
        cellFecha.value = TextCellValue(DateFormat('dd/MM/yyyy').format(item.fecha));
        _applyStyle(cellFecha);

        var cellDesc = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow));
        cellDesc.value = TextCellValue(item.descripcion);
        _applyStyle(cellDesc, horizontalAlign: HorizontalAlign.Left);

        var cellMonto = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: startRow));
        cellMonto.value = DoubleCellValue(item.monto);
        _applyStyle(cellMonto, isNumeric: true);

        total += item.monto;
        startRow++;
      }
    }

    // Fila de Total
    for (int i = 0; i < 3; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow));
      if (i == 1) cell.value = TextCellValue('TOTAL $title');
      if (i == 2) cell.value = DoubleCellValue(total);
      _applyStyle(cell, backgroundColor: totalColor, isBold: true, isNumeric: i == 2);
    }

    return startRow;
  }

  void _applyStyle(Data cell, {
    String? backgroundColor, 
    bool isBold = false, 
    String? textColor, 
    bool isNumeric = false,
    HorizontalAlign horizontalAlign = HorizontalAlign.Center,
  }) {
    // 1. Preparar colores (evita el error de ExcelColor?)
    final bgCol = backgroundColor != null 
        ? ExcelColor.fromHexString(backgroundColor) 
        : ExcelColor.fromHexString('#FFFFFF'); // Blanco por defecto
    final txtCol = textColor != null
        ? ExcelColor.fromHexString(textColor)
        : ExcelColor.fromHexString('#000000'); // Negro por defecto

    // 2. Definir estilo con todos los parámetros (evita error de setters)
    cell.cellStyle = CellStyle(
      backgroundColorHex: bgCol,
      fontColorHex: txtCol,
      bold: isBold,
      horizontalAlign: isNumeric ? HorizontalAlign.Right : horizontalAlign,
      numberFormat: isNumeric
          ? NumFormat.custom(formatCode: '#,##0')
          : NumFormat.standard_0,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
  }
}
