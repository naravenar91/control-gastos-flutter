import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_state.dart';
import '../../domain/models/tipo_categoria.dart';
import '../../domain/models/gasto.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Gastos'),
        centerTitle: true,
      ),
      body: BlocBuilder<GastoBloc, GastoState>(
        builder: (context, state) {
          if (state is GastoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GastoLoaded) {
            final double income = state.incomeTotal;
            final double expense = state.expenseTotal;
            final double savings = state.savingsTotal;
            final double balance = state.totalMes; // Este es el saldo restante (income - expense - savings)
            
            // Base del cálculo: El ingreso total
            final double baseTotal = income;

            if (baseTotal <= 0 && expense == 0 && savings == 0) {
              return const Center(child: Text('No hay datos suficientes para mostrar gráficos'));
            }

            final bool isOverspent = balance < 0;

            // Filtrar listas para el detalle
            final ingresosList = state.gastos
                .where((g) => state.categoriasMap[g.idCategoria]?.tipo == TipoCategoria.ingreso)
                .toList();
            final gastosList = state.gastos
                .where((g) => 
                    state.categoriasMap[g.idCategoria]?.tipo == TipoCategoria.gasto ||
                    state.categoriasMap[g.idCategoria]?.tipo == TipoCategoria.ocio)
                .toList();
            final ahorrosList = state.gastos
                .where((g) => state.categoriasMap[g.idCategoria]?.tipo == TipoCategoria.ahorro)
                .toList();

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Distribución del Ingreso',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Total Ingresos: \$ ${currencyFormat.format(income)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),
                    // PieChart con altura fija para scroll
                    SizedBox(
                      height: 250,
                      child: isOverspent 
                        ? _buildOverspentAlert(expense + savings, income, currencyFormat)
                        : PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _buildSections(
                            income: income,
                            expense: expense,
                            savings: savings,
                            balance: balance,
                            currencyFormat: currencyFormat,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildLegend(),
                    const SizedBox(height: 30),
                    
                    // Detalle de movimientos
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna de Ingresos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INGRESOS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...ingresosList.map((g) => _buildDetailItem(g, Colors.green.shade700, currencyFormat)),
                              if (ingresosList.isEmpty)
                                const Text('Sin datos', style: TextStyle(fontSize: 9, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Columna de Gastos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GASTOS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...gastosList.map((g) => _buildDetailItem(g, Colors.red.shade700, currencyFormat)),
                              if (gastosList.isEmpty)
                                const Text('Sin datos', style: TextStyle(fontSize: 9, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Columna de Ahorros
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AHORROS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00BFFF),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...ahorrosList.map((g) => _buildDetailItem(g, const Color(0xFF00BFFF), currencyFormat, textColor: Colors.black)),
                              if (ahorrosList.isEmpty)
                                const Text('Sin datos', style: TextStyle(fontSize: 9, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOverspentAlert(double totalSpent, double income, NumberFormat format) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 60),
        const SizedBox(height: 10),
        const Text(
          '¡Gasto Excedido!',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          'Los egresos (\$${format.format(totalSpent)}) superan a los ingresos (\$${format.format(income)})',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          width: 100,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: Colors.red,
                  value: 100,
                  title: '100%',
                  radius: 40,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections({
    required double income,
    required double expense,
    required double savings,
    required double balance,
    required NumberFormat currencyFormat,
  }) {
    final List<PieChartSectionData> sections = [];
    int currentIndex = 0;
    
    if (income <= 0) return sections;

    // Gastos
    if (expense > 0) {
      sections.add(_buildSection(
        index: currentIndex++,
        value: expense,
        percentage: (expense / income) * 100,
        title: 'Gastos',
        color: Colors.red,
        amount: expense,
        currencyFormat: currencyFormat,
      ));
    }

    // Ahorros
    if (savings > 0) {
      sections.add(_buildSection(
        index: currentIndex++,
        value: savings,
        percentage: (savings / income) * 100,
        title: 'Ahorros',
        color: const Color(0xFF00BFFF),
        amount: savings,
        currencyFormat: currencyFormat,
      ));
    }

    // Saldo (Disponible)
    if (balance > 0) {
      sections.add(_buildSection(
        index: currentIndex++,
        value: balance,
        percentage: (balance / income) * 100,
        title: 'Saldo',
        color: Colors.green,
        amount: balance,
        currencyFormat: currencyFormat,
      ));
    }

    return sections;
  }

  Widget _buildDetailItem(Gasto gasto, Color color, NumberFormat format, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gasto.descripcion,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: textColor ?? Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '\$ ${format.format(gasto.monto)}',
            style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildSection({
    required int index,
    required double value,
    required double percentage,
    required String title,
    required Color color,
    required double amount,
    required NumberFormat currencyFormat,
  }) {
    final isTouched = index == touchedIndex;
    final fontSize = isTouched ? 16.0 : 11.0;
    final radius = isTouched ? 95.0 : 85.0;

    return PieChartSectionData(
      color: color,
      value: value,
      title: isTouched 
        ? '${percentage.toStringAsFixed(1)}%\n\$${currencyFormat.format(amount)}'
        : '${percentage.toStringAsFixed(1)}%',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 15,
      runSpacing: 10,
      children: [
        _legendItem('Saldo', Colors.green),
        _legendItem('Gastos', Colors.red),
        _legendItem('Ahorros', const Color(0xFF00BFFF)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
