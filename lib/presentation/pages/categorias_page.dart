import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/categoria.dart';
import '../../domain/repositories/categoria_repository.dart';
import '../widgets/add_categoria_sheet.dart';
import '../../core/constants/app_strings.dart';

class CategoriasPage extends StatelessWidget {
  const CategoriasPage({super.key});

  Future<void> _handleDelete(BuildContext context, Categoria categoria) async {
    final repo = context.read<CategoriaRepository>();
    final canDelete = await repo.canDeleteCategoria(categoria.id);

    if (!canDelete) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.noSePuedeEliminar),
          content: const Text(AppStrings.noSePuedeEliminarMensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.entendido),
            ),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.eliminarCategoria),
        content: Text('¿Estás seguro de que deseas eliminar "${categoria.descripcion}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.eliminar, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await repo.deleteCategoria(categoria.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.categoriaEliminada)),
        );
      }
    }
  }

  void _showAddCategoriaSheet(BuildContext context, {Categoria? categoria}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => AddCategoriaSheet(categoria: categoria),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.gestionarCategorias),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Categoria>>(
        stream: context.read<CategoriaRepository>().watchAllCategorias(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categoriasRaw = snapshot.data!;
          final categorias = List<Categoria>.from(categoriasRaw);
          categorias.sort((a, b) {
            int getPriority(String desc) {
              final d = desc.toLowerCase();
              if (d == 'sueldo') return 0;
              if (d == 'crédito' || d == 'credito') return 1;
              if (d == 'ahorro') return 2;
              return 3;
            }
            final pA = getPriority(a.descripcion);
            final pB = getPriority(b.descripcion);
            if (pA != pB) return pA.compareTo(pB);
            return a.descripcion.toLowerCase().compareTo(b.descripcion.toLowerCase());
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categorias.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final cat = categorias[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(cat.colorValue),
                  child: const Icon(Icons.category, color: Colors.white),
                ),
                title: Text(cat.descripcion, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(cat.tipo.toString().split('.').last.toUpperCase()),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddCategoriaSheet(context, categoria: cat);
                    } else if (value == 'delete') {
                      _handleDelete(context, cat);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text(AppStrings.editar),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text(AppStrings.eliminar, style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoriaSheet(context),
        tooltip: AppStrings.nuevaCategoria,
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.nuevaCategoria),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Extensión para corregir error tipográfico en AppBar si es necesario o asegurar consistencia
extension on Scaffold {
  AppBar get app_bar => appBar as AppBar;
}
