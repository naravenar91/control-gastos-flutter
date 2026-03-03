import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/models/categoria.dart';
import '../../domain/models/gasto.dart';
import '../../domain/models/tipo_categoria.dart';
import '../../domain/repositories/categoria_repository.dart';
import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_event.dart';

/// Un Modal Bottom Sheet para agregar o editar gastos.
///
/// Permite al usuario introducir detalles como la descripción, el monto,
/// la categoría, la fecha y si es un gasto fijo.
class AddGastoSheet extends StatefulWidget {
  const AddGastoSheet({super.key});

  @override
  State<AddGastoSheet> createState() => _AddGastoSheetState();
}

class _AddGastoSheetState extends State<AddGastoSheet> {
  final _formKey = GlobalKey<FormState>(); // Clave para la validación del formulario
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();

  Categoria? _selectedCategoria; // Categoría seleccionada
  bool _esFijo = false; // Indica si es un gasto fijo
  DateTime _selectedDate = DateTime.now(); // Fecha seleccionada, por defecto hoy
  List<Categoria> _categorias = []; // Lista de categorías disponibles

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Carga las categorías al inicializar el estado
    _fechaController.text = DateFormat('dd/MM/yyyy').format(_selectedDate); // Formatea la fecha inicial
  }

  /// Carga todas las categorías desde el [CategoriaRepository].
  ///
  /// Se ejecuta al inicializar el Bottom Sheet para poblar el selector de categorías.
  Future<void> _loadCategories() async {
    final categorias = await context.read<CategoriaRepository>().getAllCategorias();
    setState(() {
      _categorias = categorias;
      // Selecciona la primera categoría si hay, o un valor por defecto.
      _selectedCategoria = categorias.isNotEmpty ? categorias.first : null;
    });
  }

  /// Muestra un DatePicker para seleccionar la fecha del gasto.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _fechaController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  /// Guarda el gasto actual.
  ///
  /// Realiza la validación del formulario y, si es exitosa, construye
  /// un objeto [Gasto] y lo envía al [GastoBloc] a través del evento [AddGasto].
  /// Muestra un [SnackBar] con el resultado de la operación.
  Future<void> _saveGasto() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedCategoria == null) {
        _showSnackBar('Debe seleccionar una categoría.', Colors.red);
        return;
      }

      final double? monto = double.tryParse(_montoController.text);
      if (monto == null || monto <= 0) {
        _showSnackBar('El monto debe ser un número positivo.', Colors.red);
        return;
      }

      final newGasto = Gasto(
        id: 0, // El ID se generará en la base de datos
        descripcion: _descripcionController.text,
        monto: monto,
        fecha: _selectedDate,
        activo: true, // Por defecto, el gasto está activo
        idCategoria: _selectedCategoria!.id,
        esFijo: _esFijo,
      );

      try {
        context.read<GastoBloc>().add(AddGasto(newGasto));
        _showSnackBar('Gasto "${newGasto.descripcion}" guardado exitosamente.', Colors.green);
        Navigator.pop(context); // Cierra el Bottom Sheet en caso de éxito
      } catch (e) {
        _showSnackBar('Error al guardar gasto: $e', Colors.red);
      }
    }
  }

  /// Muestra un [SnackBar] con un mensaje y color específicos.
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    _fechaController.dispose();
    super.dispose();
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
                'Nuevo Gasto',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              /// Campo de texto para la descripción del gasto.
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              /// Campo numérico para el monto del gasto.
              TextFormField(
                controller: _montoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un monto';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Ingrese un monto válido (mayor que 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              /// Selector de Categoría (usando ChoiceChips).
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      'Categoría',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: _categorias.map((categoria) {
                      final isSelected = _selectedCategoria?.id == categoria.id;
                      return ChoiceChip(
                        label: Text(categoria.descripcion),
                        selected: isSelected,
                        selectedColor: Color(int.parse(categoria.colorHex.replaceFirst('#', '0xFF'))).withOpacity(0.7),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoria = selected ? categoria : null;
                          });
                        },
                        // Estilo del texto para mayor legibilidad
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              /// Selector de Fecha.
              TextFormField(
                controller: _fechaController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 15),

              /// Switch para Gasto Fijo.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Es Gasto Fijo', style: Theme.of(context).textTheme.titleMedium),
                  Switch(
                    value: _esFijo,
                    onChanged: (value) {
                      setState(() {
                        _esFijo = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// Botón para guardar el gasto.
              ElevatedButton.icon(
                onPressed: _saveGasto,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Gasto'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
