import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/categoria.dart';
import '../../domain/models/gasto.dart';
import '../../domain/models/tipo_categoria.dart';
import '../../domain/repositories/categoria_repository.dart';
import '../../domain/repositories/gasto_repository.dart';
import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_event.dart';

/// Un Modal Bottom Sheet para agregar o editar gastos.
class AddGastoSheet extends StatefulWidget {
  final Gasto? gasto;
  final DateTime selectedMonth;

  const AddGastoSheet({super.key, this.gasto, required this.selectedMonth});

  @override
  State<AddGastoSheet> createState() => _AddGastoSheetState();
}

class _AddGastoSheetState extends State<AddGastoSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  Categoria? _selectedCategoria;
  bool _esFijo = false;
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedFechaInicio;
  DateTime? _selectedFechaFin;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    if (widget.gasto != null) {
      _descripcionController.text = widget.gasto!.descripcion;
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
      // 3. Sincronización de Fecha (UX)
      if (widget.selectedMonth.year == now.year && widget.selectedMonth.month == now.month) {
        _selectedDate = now;
      } else {
        _selectedDate = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
      }
    }
    
    _fechaController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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

  Future<void> _saveGasto() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoria == null) {
        _showSnackBar('Debe seleccionar una categoría.', Colors.red);
        return;
      }

      final cleanMonto = _montoController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final double? monto = double.tryParse(cleanMonto);
      
      if (monto == null || monto <= 0) {
        _showSnackBar('El monto debe ser un número positivo.', Colors.red);
        return;
      }

      final newGasto = Gasto(
        id: widget.gasto?.id ?? 0,
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
          
          // Lógica de Primer Registro (SharedPreferences)
          final prefs = await SharedPreferences.getInstance();
          final bool firstRecordDone = prefs.getBool('first_record_done') ?? false;
          
          if (!firstRecordDone) {
            await prefs.setBool('first_record_done', true);
            if (mounted) {
              Navigator.pop(context); // Cerrar formulario
              _showReminderDialog(context);
              return;
            }
          }
        } else {
          context.read<GastoBloc>().add(UpdateGasto(newGasto));
        }
        
        if (mounted) {
          _showSnackBar('Registro guardado exitosamente.', Colors.green);
          Navigator.pop(context);
        }
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  void _showReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¿Recordatorios diarios?'),
        content: const Text('¿Quieres activar avisos para no olvidar registrar tus gastos? Puedes configurar los días y la hora más tarde.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('LUEGO'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', true);
              if (context.mounted) {
                Navigator.pop(context);
                _showSnackBar('Notificaciones activadas. Ve a Ajustes para personalizarlas.', Colors.blue);
              }
            },
            child: const Text('ACTIVAR'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
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
          left: 16.0, right: 16.0, top: 16.0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.gasto == null ? 'Nuevo Registro' : 'Editar Registro',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descripcionController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingrese una descripción' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(labelText: 'Monto', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingrese un monto' : null,
              ),
              const SizedBox(height: 15),
              const Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildCategoriasSelector(),
              const SizedBox(height: 15),
              TextFormField(
                controller: _fechaController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveGasto,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Registro'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildCategoriasSelector() {
    return StreamBuilder<List<Categoria>>(
      stream: context.read<CategoriaRepository>().watchAllCategorias(),
      builder: (context, snapshot) {
        final categoriasRaw = snapshot.data ?? [];
        if (categoriasRaw.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

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

        if (_selectedCategoria == null && categorias.isNotEmpty) {
          _selectedCategoria = widget.gasto != null 
            ? categorias.firstWhere((c) => c.id == widget.gasto!.idCategoria, orElse: () => categorias.first)
            : categorias.first;
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

              final cat = categorias[index];
              final isSelected = _selectedCategoria?.id == cat.id;
              final color = Color(cat.colorValue);

              return ChoiceChip(
                label: Text(cat.descripcion),
                selected: isSelected,
                selectedColor: color.withOpacity(0.3),
                side: isSelected ? BorderSide(color: color, width: 2) : null,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCategoria = cat);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('es_CL');
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    int? value = int.tryParse(newText);
    if (value == null) return old;
    String formatted = _formatter.format(value);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
