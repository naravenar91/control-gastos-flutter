import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_state.dart';

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
            final double total = income + expense;

            if (total == 0) {
              return const Center(child: Text('No hay datos suficientes para mostrar gráficos'));
            }

            final double incomePercent = (income / total) * 100;
            final double expensePercent = (expense / total) * 100;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Distribución Ingresos vs Gastos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total Transaccionado: ${currencyFormat.format(total)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: PieChart(
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
                        sections: [
                          _buildSection(
                            index: 0,
                            value: income,
                            percentage: incomePercent,
                            title: 'Ingresos',
                            color: Colors.green,
                            amount: income,
                            currencyFormat: currencyFormat,
                          ),
                          _buildSection(
                            index: 1,
                            value: expense,
                            percentage: expensePercent,
                            title: 'Gastos',
                            color: Colors.red,
                            amount: expense,
                            currencyFormat: currencyFormat,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLegend(),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
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
    final fontSize = isTouched ? 20.0 : 14.0;
    final radius = isTouched ? 110.0 : 100.0;
    final widgetSize = isTouched ? 55.0 : 40.0;

    return PieChartSectionData(
      color: color,
      value: value,
      title: isTouched 
        ? '${percentage.toStringAsFixed(1)}%\n${currencyFormat.format(amount)}'
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Ingresos', Colors.green),
        const SizedBox(width: 20),
        _legendItem('Gastos', Colors.red),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
