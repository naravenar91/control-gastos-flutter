import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/categoria.dart';
import '../../domain/models/tipo_categoria.dart';
import '../../domain/repositories/categoria_repository.dart';
import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_event.dart';
import '../bloc/gasto_state.dart';

class AddCategoriaSheet extends StatefulWidget {
  final Categoria? categoria;

  const AddCategoriaSheet({super.key, this.categoria});

  @override
  State<AddCategoriaSheet> createState() => _AddCategoriaSheetState();
}

class _AddCategoriaSheetState extends State<AddCategoriaSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TipoCategoria _selectedTipo;
  late Color _selectedColor;

  final List<Color> _availableColors = [
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

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.categoria?.descripcion ?? '',
    );
    _selectedTipo = widget.categoria?.tipo ?? TipoCategoria.gasto;
    _selectedColor = widget.categoria != null 
        ? Color(widget.categoria!.colorValue) 
        : Colors.orange;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _saveCategoria() async {
    if (_formKey.currentState!.validate()) {
      final nombre = _nombreController.text.trim();
      final repository = context.read<CategoriaRepository>();

      try {
        if (widget.categoria == null) {
          // Crear nueva
          final newCategoria = Categoria(
            id: 0,
            descripcion: nombre,
            colorValue: _selectedColor.value,
            tipo: _selectedTipo,
          );
          await repository.insertCategoria(newCategoria);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Categoría creada exitosamente')),
            );
          }
        } else {
          // Editar existente
          final updatedCategoria = widget.categoria!.copyWith(
            descripcion: nombre,
            colorValue: _selectedColor.value,
            tipo: _selectedTipo,
          );
          await repository.updateCategoria(updatedCategoria);
          
          if (mounted) {
            final gastoBloc = context.read<GastoBloc>();
            if (gastoBloc.state is GastoLoaded) {
              gastoBloc.add(LoadGastos((gastoBloc.state as GastoLoaded).selectedMonth));
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Categoría actualizada')),
            );
          }
        }
        
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.0,
          right: 16.0,
          top: 16.0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.categoria == null ? 'Nueva Categoría' : 'Editar Categoría',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Supermercado, Salario...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 20),
              const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<TipoCategoria>(
                      title: const Text('Gasto', style: TextStyle(fontSize: 12)),
                      value: TipoCategoria.gasto,
                      groupValue: _selectedTipo,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _selectedTipo = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<TipoCategoria>(
                      title: const Text('Ingreso', style: TextStyle(fontSize: 12)),
                      value: TipoCategoria.ingreso,
                      groupValue: _selectedTipo,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _selectedTipo = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<TipoCategoria>(
                      title: const Text('Ahorro', style: TextStyle(fontSize: 12)),
                      value: TipoCategoria.ahorro,
                      groupValue: _selectedTipo,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _selectedTipo = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text('Color:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                width: double.maxFinite,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final color = _availableColors[index];
                    final isSelected = color.value == _selectedColor.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                        child: isSelected 
                            ? const Icon(Icons.check, color: Colors.white, size: 24) 
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom > 0 ? 0 : 16.0
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _saveCategoria,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Categoría'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
