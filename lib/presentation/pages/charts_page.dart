import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/models/categoria.dart';
import '../../domain/models/chart_view.dart';
import '../../domain/models/gasto.dart';
import '../../domain/models/tipo_categoria.dart';
import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_event.dart';
import '../bloc/gasto_state.dart';
import '../widgets/chart_legend.dart';
import '../widgets/overspent_alert.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  int touchedIndex = -1;
  ChartView _currentView = ChartView.monthly;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.analisisDeGastos),
        centerTitle: true,
      ),
      body: BlocBuilder<GastoBloc, GastoState>(
        builder: (context, state) {
          if (state is GastoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GastoLoaded) {
            if (_currentView == ChartView.annual && state.annualTotals.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<GastoBloc>().add(LoadAnnualData(state.selectedMonth.year));
              });
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de Vista con Padding
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: SegmentedButton<ChartView>(
                          segments: const [
                            ButtonSegment(
                              value: ChartView.monthly,
                              label: Text(AppStrings.vistaMensual),
                              icon: Icon(Icons.pie_chart),
                            ),
                            ButtonSegment(
                              value: ChartView.annual,
                              label: Text(AppStrings.vistaAnual),
                              icon: Icon(Icons.bar_chart),
                            ),
                          ],
                          selected: {_currentView},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _currentView = newSelection.first;
                            });
                          },
                        ),
                      ),
                    ),

                    if (_currentView == ChartView.monthly)
                      _buildMonthlyView(state, currencyFormat)
                    else
                      _buildAnnualView(state, currencyFormat),

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

  Widget _buildMonthlyView(GastoLoaded state, NumberFormat currencyFormat) {
    final double income = state.incomeTotal;
    final double expense = state.expenseTotal;
    final double savings = state.savingsTotal;
    final double balance = state.totalMes;
    
    if (income <= 0 && expense == 0 && savings == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50),
          child: Text(AppStrings.noHayDatosGrficos, style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final bool isOverspent = balance < 0;

    // Agrupar gastos por categoría
    final Map<int, List<Gasto>> groupedByCat = {};
    for (var g in state.gastos) {
      groupedByCat.putIfAbsent(g.idCategoria, () => []).add(g);
    }

    // Calcular fontSize dinámico para el centro del gráfico
    final String balanceText = '\$${currencyFormat.format(balance)}';
    double balanceFontSize = 18;
    if (balanceText.length > 10) balanceFontSize = 15;
    if (balanceText.length > 13) balanceFontSize = 13;

    return Column(
      children: [
        const Text(
          AppStrings.distribucionIngreso,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          '${AppStrings.totalIngresos} \$${currencyFormat.format(income)}',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 32),
        
        // Gráfico de Dona con Saldo Neto al centro
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!isOverspent)
                Container(
                  width: 120, // Limitar ancho para que el texto no choque
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        AppStrings.saldoNeto,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          balanceText,
                          style: TextStyle(
                            fontSize: balanceFontSize,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              isOverspent 
                ? OverspentAlert(totalSpent: expense + savings, income: income, format: currencyFormat)
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
                  sectionsSpace: 3,
                  centerSpaceRadius: 75, 
                  sections: _buildSections(
                    income: income,
                    expense: expense,
                    savings: savings,
                    balance: balance,
                    currencyFormat: currencyFormat,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40), // Espacio entre gráfico y leyenda solicitado
        const ChartLegend(),
        const SizedBox(height: 40),
        
        // Detalle de movimientos AGRUPADOS
        const Divider(thickness: 1),
        const SizedBox(height: 16),
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Text(
              AppStrings.detallePorCategoria, 
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.0),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...groupedByCat.entries.map((entry) {
          final categoria = state.categoriasMap[entry.key];
          if (categoria == null) return const SizedBox.shrink();
          
          final items = entry.value;
          final total = items.fold(0.0, (sum, item) => sum + item.monto);
          final color = categoria.tipo == TipoCategoria.ahorro ? const Color(0xFF00BFFF) : (categoria.tipo == TipoCategoria.ingreso ? Colors.green : Colors.red);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade200), 
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1), 
                child: Icon(Icons.category, color: color, size: 20),
              ),
              title: Text(
                categoria.descripcion, 
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              trailing: Text(
                '\$${currencyFormat.format(total)}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              children: items.map((g) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                title: Text(g.descripcion, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(g.fecha), style: const TextStyle(fontSize: 11)),
                trailing: Text(
                  '\$${currencyFormat.format(g.monto)}', 
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              )).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAnnualView(GastoLoaded state, NumberFormat currencyFormat) {
    if (state.annualTotals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        Text(
          '${AppStrings.resumenAnual} ${state.selectedMonth.year}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 48), // Aumentado para dar aire superior
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0), // Padding extra superior al gráfico
            child: SizedBox(
              width: 800, 
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxY(state.annualTotals),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey.shade900.withOpacity(0.9),
                      tooltipMargin: 0,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String category = '';
                        switch (rodIndex) {
                          case 0: category = 'Ingreso'; break;
                          case 1: category = 'Gasto'; break;
                          case 2: category = 'Ahorro'; break;
                        }
                        return BarTooltipItem(
                          '$category\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          children: [
                            TextSpan(
                              text: currencyFormat.format(rod.toY),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                          final int index = value.toInt() - 1;
                          if (index < 0 || index >= months.length) return const SizedBox.shrink();
                          
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(months[index], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55, // Aumentado de 45 a 55 solicitado
                        interval: _calculateInterval(state.annualTotals),
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _formatCompact(value),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: Colors.black12,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: state.annualTotals.entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(toY: entry.value.income, color: Colors.green.shade600, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                        BarChartRodData(toY: entry.value.expense, color: Colors.red.shade600, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                        BarChartRodData(toY: entry.value.savings, color: const Color(0xFF00BFFF), width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 60), // Aumentado espacio entre gráfico y leyenda
        const ChartLegend(),
      ],
    );
  }

  double _calculateMaxY(Map<int, MonthlySummary> data) {
    double max = 0;
    for (var m in data.values) {
      if (m.income > max) max = m.income;
      if (m.expense > max) max = m.expense;
      if (m.savings > max) max = m.savings;
    }
    return max == 0 ? 100 : max * 1.2;
  }

  double _calculateInterval(Map<int, MonthlySummary> data) {
    double max = 0;
    for (var m in data.values) {
      if (m.income > max) max = m.income;
      if (m.expense > max) max = m.expense;
      if (m.savings > max) max = m.savings;
    }
    if (max == 0) return 20;
    return (max * 1.2) / 5; // Para mostrar aprox 5-6 etiquetas
  }

  String _formatCompact(double value) {
    if (value == 0) return '0';
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  List<PieChartSectionData> _buildSections({required double income, required double expense, required double savings, required double balance, required NumberFormat currencyFormat}) {
    final List<PieChartSectionData> sections = [];
    int currentIndex = 0;
    if (income <= 0) return sections;

    if (expense > 0) sections.add(_buildSection(index: currentIndex++, value: expense, percentage: (expense / income) * 100, title: 'Gastos', color: Colors.red.shade600, amount: expense, currencyFormat: currencyFormat));
    if (savings > 0) sections.add(_buildSection(index: currentIndex++, value: savings, percentage: (savings / income) * 100, title: 'Ahorros', color: const Color(0xFF00BFFF), amount: savings, currencyFormat: currencyFormat));
    if (balance > 0) sections.add(_buildSection(index: currentIndex++, value: balance, percentage: (balance / income) * 100, title: 'Saldo', color: Colors.green.shade600, amount: balance, currencyFormat: currencyFormat));

    return sections;
  }

  PieChartSectionData _buildSection({required int index, required double value, required double percentage, required String title, required Color color, required double amount, required NumberFormat currencyFormat}) {
    final isTouched = index == touchedIndex;
    return PieChartSectionData(
      color: color,
      value: value,
      title: isTouched ? '${percentage.toStringAsFixed(1)}%\n\$${currencyFormat.format(amount)}' : '${percentage.toStringAsFixed(1)}%',
      radius: isTouched ? 85.0 : 75.0,
      titleStyle: TextStyle(fontSize: isTouched ? 15.0 : 11.0, fontWeight: FontWeight.bold, color: Colors.white, shadows: const [Shadow(color: Colors.black, blurRadius: 2)]),
    );
  }
}
