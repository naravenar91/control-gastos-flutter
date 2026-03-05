import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/categoria.dart';
import '../../domain/models/tipo_categoria.dart';
import '../../domain/repositories/categoria_repository.dart';
import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_event.dart';
import '../bloc/gasto_state.dart';

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

  Future<void> _showCreateCategoriaDialog(BuildContext context) async {
    final TextEditingController categoriaController = TextEditingController();
    TipoCategoria selectedTipo = TipoCategoria.gasto;
    Color selectedColor = Colors.orange;
    
    final List<Color> availableColors = [
      Colors.green,
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      const Color(0xFF00BFFF), // Celeste Ahorro
    ];
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoriaController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej: Supermercado, Salario...',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 15),
                const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<TipoCategoria>(
                        title: const Text('Gasto', style: TextStyle(fontSize: 10)),
                        value: TipoCategoria.gasto,
                        groupValue: selectedTipo,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) => setDialogState(() => selectedTipo = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<TipoCategoria>(
                        title: const Text('Ingreso', style: TextStyle(fontSize: 10)),
                        value: TipoCategoria.ingreso,
                        groupValue: selectedTipo,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) => setDialogState(() => selectedTipo = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<TipoCategoria>(
                        title: const Text('Ahorro', style: TextStyle(fontSize: 10)),
                        value: TipoCategoria.ahorro,
                        groupValue: selectedTipo,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) => setDialogState(() => selectedTipo = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text('Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  width: double.maxFinite,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableColors.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final color = availableColors[index];
                      final isSelected = color.value == selectedColor.value;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = color),
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = categoriaController.text.trim();
                if (nombre.isNotEmpty) {
                  final newCategoria = Categoria(
                    id: 0,
                    descripcion: nombre,
                    colorValue: selectedColor.value,
                    tipo: selectedTipo,
                  );
                  
                  try {
                    await context.read<CategoriaRepository>().insertCategoria(newCategoria);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Categoría creada exitosamente')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al crear categoría: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditCategoriaDialog(BuildContext context, Categoria categoria) async {
    final TextEditingController categoriaController = TextEditingController(text: categoria.descripcion);
    TipoCategoria selectedTipo = categoria.tipo;
    Color selectedColor = Color(categoria.colorValue);
    
    final List<Color> availableColors = [
      Colors.green,
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      const Color(0xFF00BFFF), // Celeste Ahorro
    ];
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoriaController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 15),
                const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<TipoCategoria>(
                        title: const Text('Gasto', style: TextStyle(fontSize: 10)),
                        value: TipoCategoria.gasto,
                        groupValue: selectedTipo,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) => setDialogState(() => selectedTipo = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<TipoCategoria>(
                        title: const Text('Ingreso', style: TextStyle(fontSize: 10)),
                        value: TipoCategoria.ingreso,
                        groupValue: selectedTipo,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) => setDialogState(() => selectedTipo = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<TipoCategoria>(
                        title: const Text('Ahorro', style: TextStyle(fontSize: 10)),
                        value: TipoCategoria.ahorro,
                        groupValue: selectedTipo,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) => setDialogState(() => selectedTipo = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text('Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  width: double.maxFinite,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableColors.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final color = availableColors[index];
                      final isSelected = color.value == selectedColor.value;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = color),
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = categoriaController.text.trim();
                if (nombre.isNotEmpty) {
                  final updatedCategoria = categoria.copyWith(
                    descripcion: nombre,
                    colorValue: selectedColor.value,
                    tipo: selectedTipo,
                  );
                  
                  try {
                    await context.read<CategoriaRepository>().updateCategoria(updatedCategoria);
                    
                    if (context.mounted) {
                      final gastoBloc = context.read<GastoBloc>();
                      if (gastoBloc.state is GastoLoaded) {
                        gastoBloc.add(LoadGastos((gastoBloc.state as GastoLoaded).selectedMonth));
                      }
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Categoría actualizada')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
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
                      _showEditCategoriaDialog(context, cat);
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
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCategoriaDialog(context),
        tooltip: 'Nueva Categoría',
        child: const Icon(Icons.add),
      ),
    );
  }
}
