import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/models/categoria.dart';
import '../../domain/models/gasto.dart';
import '../../domain/models/tipo_categoria.dart';
import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_event.dart';
import '../bloc/gasto_state.dart';
import '../widgets/add_gasto_sheet.dart'; // Importar el AddGastoSheet

/// La pantalla principal de la aplicación que muestra un resumen de gastos e ingresos.
///
/// Utiliza un [CustomScrollView] con un [SliverAppBar] que desaparece
/// y un resumen en forma de tarjeta, seguido de una lista de gastos recientes.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _changeMonth(BuildContext context, DateTime currentMonth, int offset) {
    final newMonth = DateTime(currentMonth.year, currentMonth.month + offset);
    context.read<GastoBloc>().add(LoadGastos(newMonth));
  }

  @override
  Widget build(BuildContext context) {
    // Se asegura que el BLoC esté disponible en el árbol de widgets.
    // Esto es un ejemplo, en una app real se inyectaría con un Provider/RepositoryProvider.
    return BlocBuilder<GastoBloc, GastoState>(
      builder: (context, state) {
        if (state is GastoLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is GastoError) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is GastoLoaded) {
          final NumberFormat currencyFormat =
              NumberFormat.decimalPattern('es_CL');
          final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

          // Utiliza el saldo total calculado en el BLoC (Ingresos - Gastos - Ahorros)
          final double balanceTotal = state.totalMes;

          // Función auxiliar para formatear montos con signo y símbolo al inicio
          String formatAmount(double amount, TipoCategoria? tipo) {
            final String formatted = currencyFormat.format(amount.abs());
            if (tipo == TipoCategoria.ingreso) return '+\$ $formatted';
            if (tipo == TipoCategoria.ahorro) return '\$ $formatted';
            if (tipo == TipoCategoria.gasto || tipo == TipoCategoria.ocio) return '-\$ $formatted';
            return '\$ $formatted';
          }

          return CustomScrollView(
            slivers: [
              /// SliverAppBar que desaparece al hacer scroll.
              /// Muestra el saldo total del mes.
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
                        const SizedBox(height: 40), // Espacio para que el título del FlexibleSpaceBar no choque
                      ],
                    ),
                  ),
                ),
              ),

              /// Tarjeta de Resumen con Ingresos vs. Gastos.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen Mensual',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ingresos:'),
                              Text(
                                '+\$ ${currencyFormat.format(state.incomeTotal)}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
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
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// Lista de Gastos Recientes.
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final Gasto gasto = state.gastos[index];
                    final Categoria? categoria = state.categoriasMap[gasto.idCategoria];

                    // Determina el color del monto según el color de su categoría en la DB
                    Color montoColor = Theme.of(context).colorScheme.onSurface;
                    if (categoria != null) {
                      if (categoria.tipo == TipoCategoria.ahorro) {
                        montoColor = const Color(0xFF00BFFF);
                      } else {
                        montoColor = Color(categoria.colorValue);
                      }
                    }

                    return Dismissible(
                      key: ValueKey(gasto.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirmar eliminación'),
                              content: Text('¿Estás seguro de que deseas eliminar el registro "${gasto.descripcion}"?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('CANCELAR'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        context.read<GastoBloc>().add(DeleteGasto(gasto.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registro ${gasto.descripcion} eliminado')),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: categoria != null
                                ? Color(categoria.colorValue)
                                : Theme.of(context).colorScheme.secondary,
                            child: Text(
                              categoria != null ? categoria.descripcion[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(gasto.descripcion)),
                              if (gasto.esFijo)
                                const Icon(Icons.autorenew, size: 16, color: Colors.blueGrey),
                            ],
                          ),
                          subtitle: Text(dateFormat.format(gasto.fecha)),
                          trailing: Text(
                            formatAmount(gasto.monto, categoria?.tipo),
                            style: TextStyle(
                              color: montoColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => AddGastoSheet(gasto: gasto),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  childCount: state.gastos.length,
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink(); // Estado inicial o desconocido
      },
    );
  }
  }