import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/models/categoria.dart';
import '../../domain/models/gasto.dart';
import '../../domain/models/tipo_categoria.dart';
import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_event.dart';
import '../bloc/gasto_state.dart';
import '../widgets/add_gasto_sheet.dart';

/// La pantalla principal de la aplicación que muestra un resumen de gastos e ingresos.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _changeMonth(BuildContext context, DateTime currentMonth, int offset) {
    final newMonth = DateTime(currentMonth.year, currentMonth.month + offset);
    context.read<GastoBloc>().add(LoadGastos(newMonth));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GastoBloc, GastoState>(
      builder: (context, state) {
        if (state is GastoLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is GastoError) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is GastoLoaded) {
          final NumberFormat currencyFormat = NumberFormat.decimalPattern('es_CL');
          final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
          final double balanceTotal = state.totalMes;

          return Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220.0,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                          onPressed: () => _changeMonth(context, state.selectedMonth, -1),
                        ),
                        Text(
                          '${DateFormat('MMMM yyyy', 'es_CL').format(state.selectedMonth).toUpperCase()} ',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                          onPressed: () => _changeMonth(context, state.selectedMonth, 1),
                        ),
                      ],
                    ),
                    centerTitle: true,
                    background: Container(
                      color: balanceTotal >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Saldo del Mes',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                          ),
                          Text(
                            '${balanceTotal >= 0 ? '\$ ' : '-\$ '}${currencyFormat.format(balanceTotal.abs())}',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Resumen Mensual', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Ingresos:'),
                                Text(
                                  '+\$ ${currencyFormat.format(state.incomeTotal)}',
                                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Gastos:'),
                                Text(
                                  '-\$ ${currencyFormat.format(state.expenseTotal)}',
                                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final Map<int, List<Gasto>> groupedGastos = {};
                      for (var g in state.gastos) {
                        groupedGastos.putIfAbsent(g.idCategoria, () => []).add(g);
                      }
                      final List<int> categoryIds = groupedGastos.keys.toList();
                      if (index >= categoryIds.length) return null;

                      final int catId = categoryIds[index];
                      final List<Gasto> items = groupedGastos[catId]!;
                      final Categoria? categoria = state.categoriasMap[catId];
                      final double totalGroup = items.fold(0, (sum, item) => sum + item.monto);
                      final Color themeColor = categoria != null 
                          ? (categoria.tipo == TipoCategoria.ahorro ? const Color(0xFF00BFFF) : Color(categoria.colorValue))
                          : Theme.of(context).colorScheme.secondary;

                      if (items.length == 1) {
                        return _buildGastoTile(context, items.first, categoria, themeColor, currencyFormat, dateFormat, state.selectedMonth);
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        elevation: 1,
                        child: GestureDetector(
                          onLongPress: () => _confirmGroupDeletion(context, items, categoria?.descripcion ?? 'Sin Categoría'),
                          child: ExpansionTile(
                            shape: const RoundedRectangleBorder(side: BorderSide.none),
                            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                            leading: CircleAvatar(
                              backgroundColor: themeColor,
                              child: Text(
                                categoria != null ? categoria.descripcion[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(categoria?.descripcion ?? 'Sin Categoría', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${items.length} registros'),
                            trailing: Text(
                              _formatWithSign(totalGroup, categoria?.tipo, currencyFormat),
                              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            children: items.map((gasto) => _buildGastoDetailTile(context, gasto, categoria, themeColor, currencyFormat, dateFormat, state.selectedMonth)).toList(),
                          ),
                        ),
                      );
                    },
                    childCount: state.gastos.map((g) => g.idCategoria).toSet().length,
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => AddGastoSheet(selectedMonth: state.selectedMonth),
                );
              },
              child: const Icon(Icons.add),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGastoTile(BuildContext context, Gasto gasto, Categoria? categoria, Color color, NumberFormat format, DateFormat dateFormat, DateTime selectedMonth) {
    return Dismissible(
      key: ValueKey(gasto.id),
      background: _buildDeleteBackground(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) => _confirmDeletion(context, gasto),
      onDismissed: (dir) => _handleDeletion(context, gasto),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        elevation: 1,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color,
            child: Text(
              categoria != null ? categoria.descripcion[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(gasto.descripcion)),
              if (gasto.esFijo) const Icon(Icons.autorenew, size: 16, color: Colors.blueGrey),
            ],
          ),
          subtitle: Text(dateFormat.format(gasto.fecha)),
          trailing: Text(
            _formatWithSign(gasto.monto, categoria?.tipo, format),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          onTap: () => _openEditSheet(context, gasto, selectedMonth),
        ),
      ),
    );
  }

  Widget _buildGastoDetailTile(BuildContext context, Gasto gasto, Categoria? categoria, Color color, NumberFormat format, DateFormat dateFormat, DateTime selectedMonth) {
    return Dismissible(
      key: ValueKey(gasto.id),
      background: _buildDeleteBackground(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) => _confirmDeletion(context, gasto),
      onDismissed: (dir) => _handleDeletion(context, gasto),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 72.0, right: 16.0),
        title: Text(gasto.descripcion, style: const TextStyle(fontSize: 14)),
        subtitle: Text(dateFormat.format(gasto.fecha), style: const TextStyle(fontSize: 12)),
        trailing: Text(
          _formatWithSign(gasto.monto, categoria?.tipo, format),
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 13),
        ),
        onTap: () => _openEditSheet(context, gasto, selectedMonth),
      ),
    );
  }

  String _formatWithSign(double amount, TipoCategoria? tipo, NumberFormat format) {
    final String formatted = format.format(amount.abs());
    if (tipo == TipoCategoria.ingreso) return '+\$ $formatted';
    if (tipo == TipoCategoria.ahorro) return '\$ $formatted';
    if (tipo == TipoCategoria.gasto || tipo == TipoCategoria.ocio) return '-\$ $formatted';
    return '\$ $formatted';
  }

  Widget _buildDeleteBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20.0),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Future<bool?> _confirmDeletion(BuildContext context, Gasto gasto) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar "${gasto.descripcion}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ELIMINAR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _handleDeletion(BuildContext context, Gasto gasto) {
    context.read<GastoBloc>().add(DeleteGasto(gasto.id));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registro ${gasto.descripcion} eliminado')));
  }

  Future<void> _confirmGroupDeletion(BuildContext context, List<Gasto> items, String categoryName) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar todo el grupo?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Se eliminarán:'),
            const SizedBox(height: 8),
            ...items.take(5).map((g) => Text('• ${g.descripcion}', style: const TextStyle(fontSize: 13, color: Colors.black87))),
            if (items.length > 5) Text('... y ${items.length - 5} más', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('ELIMINAR TODO', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      _handleGroupDeletion(context, items, categoryName);
    }
  }

  void _handleGroupDeletion(BuildContext context, List<Gasto> items, String categoryName) {
    final ids = items.map((g) => g.id).toList();
    context.read<GastoBloc>().add(DeleteGroupGasto(ids, categoryName));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Grupo "$categoryName" eliminado con éxito')));
  }

  void _openEditSheet(BuildContext context, Gasto gasto, DateTime selectedMonth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddGastoSheet(gasto: gasto, selectedMonth: selectedMonth),
    );
  }
}
