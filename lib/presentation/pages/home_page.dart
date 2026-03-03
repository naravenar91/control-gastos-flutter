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

  @override
  Widget build(BuildContext context) {
    // Se asegura que el BLoC esté disponible en el árbol de widgets.
    // Esto es un ejemplo, en una app real se inyectaría con un Provider/RepositoryProvider.
    return Scaffold(
      body: BlocBuilder<GastoBloc, GastoState>(
        builder: (context, state) {
          if (state is GastoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GastoError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is GastoLoaded) {
            final NumberFormat currencyFormat =
                NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
            final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

            // Calcula el saldo total para mostrar en el SliverAppBar
            final double balanceTotal = state.incomeTotal - state.expenseTotal;

            return CustomScrollView(
              slivers: [
                /// SliverAppBar que desaparece al hacer scroll.
                /// Muestra el saldo total del mes.
                SliverAppBar(
                  expandedHeight: 200.0,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Saldo del mes: ${currencyFormat.format(balanceTotal)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                    centerTitle: true,
                    background: Container(
                      color: Theme.of(context).colorScheme.primary,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tu Balance Total',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                          ),
                          Text(
                            currencyFormat.format(balanceTotal),
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
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
                                Text('Ingresos:'),
                                Text(
                                  currencyFormat.format(state.incomeTotal),
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
                                Text('Gastos:'),
                                Text(
                                  currencyFormat.format(state.expenseTotal),
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

                      // Determina el color del monto según el tipo de categoría
                      Color montoColor = Theme.of(context).colorScheme.onSurface;
                      if (categoria != null) {
                        if (categoria.tipo == TipoCategoria.INGRESO) {
                          montoColor = Colors.green.shade700;
                        } else if (categoria.tipo == TipoCategoria.GASTO ||
                            categoria.tipo == TipoCategoria.OCIO) {
                          montoColor = Colors.red.shade700;
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
                        onDismissed: (direction) {
                          context.read<GastoBloc>().add(DeleteGasto(gasto.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gasto ${gasto.descripcion} eliminado')),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: categoria != null
                                  ? Color(int.parse(categoria.colorHex.replaceFirst('#', '0xFF')))
                                  : Theme.of(context).colorScheme.secondary,
                              child: Text(
                                categoria != null ? categoria.descripcion[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(gasto.descripcion),
                            subtitle: Text(dateFormat.format(gasto.fecha)),
                            trailing: Text(
                              currencyFormat.format(gasto.monto),
                              style: TextStyle(
                                color: montoColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              // TODO: Implementar navegación a detalles del gasto
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
      ),
      /// FloatingActionButton para agregar un nuevo gasto.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Muestra el ModalBottomSheet para agregar un nuevo gasto
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Permite que el sheet ocupe toda la altura necesaria
            builder: (context) => const AddGastoSheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Gasto'),
      ),
    );
  }
}