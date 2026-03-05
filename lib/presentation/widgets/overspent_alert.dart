import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class OverspentAlert extends StatelessWidget {
  final double totalSpent;
  final double income;
  final NumberFormat format;

  const OverspentAlert({
    super.key,
    required this.totalSpent,
    required this.income,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 50),
        const SizedBox(height: 8),
        const Text(
          '¡Gasto Excedido!',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Egresos (\$${format.format(totalSpent)}) > Ingresos (\$${format.format(income)})',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          width: 50,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: Colors.red,
                  value: 100,
                  title: '100%',
                  radius: 20,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
