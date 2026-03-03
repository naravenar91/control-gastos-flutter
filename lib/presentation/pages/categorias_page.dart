import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/categoria.dart';
import '../../domain/repositories/categoria_repository.dart';

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
          title: const Text('No se puede eliminar'),
          content: const Text(
              'No se puede eliminar esta categoría porque tiene registros asociados. Por favor, mueva o elimine los registros primero.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ENTENDIDO'),
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
        title: const Text('Eliminar Categoría'),
        content: Text('¿Estás seguro de que deseas eliminar "${categoria.descripcion}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await repo.deleteCategoria(categoria.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría eliminada con éxito')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Categorías'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Categoria>>(
        stream: context.read<CategoriaRepository>().watchAllCategorias(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categorias = snapshot.data!;

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
                title: Text(cat.descripcion),
                subtitle: Text(cat.tipo.toString().split('.').last.toUpperCase()),
                trailing: const Icon(Icons.more_vert),
                onLongPress: () => _handleDelete(context, cat),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mantén presionado para eliminar')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
