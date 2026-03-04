import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/models/categoria.dart';
import '../../domain/models/gasto.dart';
import '../../domain/models/tipo_categoria.dart';
import '../../domain/repositories/categoria_repository.dart';
import '../../domain/repositories/gasto_repository.dart';
import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_event.dart';

/// Un Modal Bottom Sheet para agregar o editar gastos.
///
/// Permite al usuario introducir detalles como la descripción, el monto,
/// la categoría, la fecha y si es un gasto fijo.
class AddGastoSheet extends StatefulWidget {
  final Gasto? gasto;
  final DateTime selectedMonth;

  const AddGastoSheet({super.key, this.gasto, required this.selectedMonth});

  @override
  State<AddGastoSheet> createState() => _AddGastoSheetState();
}

class _AddGastoSheetState extends State<AddGastoSheet> {
  final _formKey = GlobalKey<FormState>(); // Clave para la validación del formulario
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  Categoria? _selectedCategoria; // Categoría seleccionada
  bool _esFijo = false; // Indica si es un gasto fijo
  DateTime _selectedDate = DateTime.now(); // Fecha seleccionada
  DateTime? _selectedFechaInicio;
  DateTime? _selectedFechaFin;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    if (widget.gasto != null) {
      _descripcionController.text = widget.gasto!.descripcion;
      // Formatear el monto inicial con separadores de miles
      final NumberFormat formatter = NumberFormat.decimalPattern('es_CL');
      _montoController.text = formatter.format(widget.gasto!.monto.toInt());
      _selectedDate = widget.gasto!.fecha;
      _esFijo = widget.gasto!.esFijo;
      _selectedFechaInicio = widget.gasto!.fechaInicio;
      _selectedFechaFin = widget.gasto!.fechaFin;

      if (_selectedFechaInicio != null) {
        _fechaInicioController.text = DateFormat('dd/MM/yyyy').format(_selectedFechaInicio!);
      }
      if (_selectedFechaFin != null) {
        _fechaFinController.text = DateFormat('dd/MM/yyyy').format(_selectedFechaFin!);
      }
    } else {
      // Lógica de Sincronización de Fecha para Nuevos Registros
      // Si el mes visualizado es el actual, usar la fecha de hoy
      if (widget.selectedMonth.year == now.year && widget.selectedMonth.month == now.month) {
        _selectedDate = now;
      } else {
        // Si es un mes distinto (futuro o pasado), usar el día 1 de ese mes
        _selectedDate = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
      }
    }
    
    _fechaController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  /// Muestra un DatePicker para seleccionar la fecha del gasto.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // El calendario se abrirá en el mes correcto automáticamente
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _fechaController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  /// Muestra un DatePicker para seleccionar la fecha de inicio del gasto fijo.
  Future<void> _selectFechaInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFechaInicio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedFechaInicio = picked;
        _fechaInicioController.text = DateFormat('dd/MM/yyyy').format(_selectedFechaInicio!);
      });
    }
  }

  /// Muestra un DatePicker para seleccionar la fecha de fin del gasto fijo.
  Future<void> _selectFechaFin(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFechaFin ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedFechaFin = picked;
        _fechaFinController.text = DateFormat('dd/MM/yyyy').format(_selectedFechaFin!);
      });
    }
  }

  /// Muestra un diálogo para crear una nueva categoría.
  Future<void> _showCreateCategoriaDialog() async {
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
                    final newId = await context.read<CategoriaRepository>().insertCategoria(newCategoria);
                    if (mounted) {
                      setState(() {
                        _selectedCategoria = newCategoria.copyWith(id: newId);
                      });
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    _showSnackBar('Error al crear categoría: $e', Colors.red);
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

  /// Muestra un diálogo de confirmación para eliminar la categoría seleccionada.
  Future<void> _confirmDeleteCategoria(Categoria categoria) async {
    final gastoRepo = context.read<GastoRepository>();
    final catRepo = context.read<CategoriaRepository>();
    
    // 1. Verificar si hay gastos asociados
    final gastosAsociados = await gastoRepo.getGastosByCategoria(categoria.id);
    
    if (gastosAsociados.isNotEmpty) {
      if (mounted) {
        _showSnackBar('No se puede eliminar una categoría con gastos asociados.', Colors.orange);
      }
      return;
    }

    // 2. Si está vacía, pedir confirmación
    if (!mounted) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Categoría'),
          content: Text('¿Estás seguro de que deseas eliminar la categoría "${categoria.descripcion}"?'),
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

    if (confirmed == true && mounted) {
      try {
        await catRepo.deleteCategoria(categoria.id);
        
        // Resetear selección si se eliminó la categoría actual
        if (_selectedCategoria?.id == categoria.id) {
          setState(() {
            _selectedCategoria = null; // El StreamBuilder seleccionará el siguiente disponible
          });
        }
        
        _showSnackBar('Categoría eliminada exitosamente.', Colors.green);
      } catch (e) {
        _showSnackBar('Error al eliminar categoría: $e', Colors.red);
      }
    }
  }

  /// Muestra un diálogo de confirmación para eliminar el registro.
  Future<void> _confirmDeleteGasto() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar el registro "${widget.gasto!.descripcion}"?'),
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

    if (confirmed == true && mounted) {
      context.read<GastoBloc>().add(DeleteGasto(widget.gasto!.id));
      _showSnackBar('Registro eliminado exitosamente.', Colors.green);
      Navigator.pop(context); // Cierra el bottom sheet
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

      // Quitar separadores de miles para obtener el valor numérico
      final cleanMonto = _montoController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final double? monto = double.tryParse(cleanMonto);
      
      if (monto == null || monto <= 0) {
        _showSnackBar('El monto debe ser un número positivo.', Colors.red);
        return;
      }

      final newGasto = Gasto(
        id: widget.gasto?.id ?? 0, // Conservar ID si se edita, 0 para nuevo
        descripcion: _descripcionController.text,
        monto: monto,
        fecha: _selectedDate,
        activo: true,
        idCategoria: _selectedCategoria!.id,
        esFijo: _esFijo,
        fechaInicio: _selectedFechaInicio,
        fechaFin: _selectedFechaFin,
      );

      try {
        if (widget.gasto == null) {
          context.read<GastoBloc>().add(AddGasto(newGasto));
        } else {
          context.read<GastoBloc>().add(UpdateGasto(newGasto));
        }
        _showSnackBar('Registro "${newGasto.descripcion}" guardado exitosamente.', Colors.green);
        Navigator.pop(context);
      } catch (e) {
        _showSnackBar('Error al guardar registro: $e', Colors.red);
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
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
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
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    widget.gasto == null ? 'Nuevo Registro' : 'Editar Registro',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (widget.gasto != null)
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: _confirmDeleteGasto,
                        tooltip: 'Eliminar Registro',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              /// Campo de texto para la descripción del gasto.
              TextFormField(
                controller: _descripcionController,
                textCapitalization: TextCapitalization.words,
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
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un monto';
                  }
                  // Quitar separadores de miles para validar
                  final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (double.tryParse(cleanValue) == null || double.parse(cleanValue) <= 0) {
                    return 'Ingrese un monto válido (mayor que 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              /// Selector de Categoría (usando StreamBuilder y Chips).
              const Text('Categoría', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<List<Categoria>>(
                stream: context.read<CategoriaRepository>().watchAllCategorias(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final categoriasRaw = snapshot.data ?? [];
                  
                  // Ordenar categorías: 1. Sueldo, 2. Crédito, 3. Ahorro, luego alfabéticamente
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

                  if (categorias.isEmpty) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'No hay categorías disponibles.',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showCreateCategoriaDialog,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Crear Categoría'),
                        ),
                      ],
                    );
                  }

                  // Si no hay nada seleccionado, seleccionar el primero por defecto o el del gasto si estamos editando.
                  // También se actualiza si la categoría seleccionada ya no existe.
                  if (_selectedCategoria == null || !categorias.any((c) => c.id == _selectedCategoria!.id)) {
                    if (widget.gasto != null && _selectedCategoria == null) {
                      _selectedCategoria = categorias.firstWhere(
                        (c) => c.id == widget.gasto!.idCategoria,
                        orElse: () => categorias.first,
                      );
                    } else {
                      _selectedCategoria = categorias.first;
                    }
                    // Se usa postFrameCallback para evitar errores de setState durante el build.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() {});
                    });
                  }

                  return SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categorias.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == categorias.length) {
                          return ActionChip(
                            avatar: const Icon(Icons.add, size: 18),
                            label: const Text('Nueva'),
                            onPressed: _showCreateCategoriaDialog,
                          );
                        }

                        final categoria = categorias[index];
                        final isSelected = _selectedCategoria?.id == categoria.id;
                        final color = Color(categoria.colorValue);

                        return GestureDetector(
                          onLongPress: () => _confirmDeleteCategoria(categoria),
                          child: ChoiceChip(
                            label: Text(categoria.descripcion),
                            selected: isSelected,
                            selectedColor: color.withOpacity(0.3),
                            side: isSelected ? BorderSide(color: color, width: 2) : null,
                            avatar: CircleAvatar(
                              backgroundColor: color,
                              radius: 8,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategoria = categoria;
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
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
                        if (!_esFijo) {
                          _selectedFechaInicio = null;
                          _selectedFechaFin = null;
                          _fechaInicioController.clear();
                          _fechaFinController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
              if (_esFijo) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fechaInicioController,
                        readOnly: true,
                        onTap: () => _selectFechaInicio(context),
                        decoration: const InputDecoration(
                          labelText: 'Desde',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _fechaFinController,
                        readOnly: true,
                        onTap: () => _selectFechaFin(context),
                        decoration: const InputDecoration(
                          labelText: 'Hasta',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              /// Botón para guardar el gasto.
              ElevatedButton.icon(
                onPressed: _saveGasto,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Registro'),
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

/// Formateador para añadir separadores de miles en tiempo real.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('es_CL');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Eliminar cualquier carácter que no sea dígito
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Formatear el número
    int? value = int.tryParse(newText);
    if (value == null) return oldValue;
    
    String formattedText = _formatter.format(value);

    // Mantener la posición del cursor de forma coherente
    int cursorPosition = formattedText.length - (newValue.text.length - newValue.selection.end);
    if (cursorPosition < 0) cursorPosition = 0;
    if (cursorPosition > formattedText.length) cursorPosition = formattedText.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
