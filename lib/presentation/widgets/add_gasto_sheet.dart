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
      context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _fechaController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectFechaInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context, 
      initialDate: _selectedFechaInicio ?? _selectedDate, 
      firstDate: DateTime(2000), 
      lastDate: DateTime(2101)
    );
    if (picked != null) {
      setState(() {
        _selectedFechaInicio = picked;
        _fechaInicioController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectFechaFin(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context, 
      initialDate: _selectedFechaFin ?? _selectedDate.add(const Duration(days: 30)), 
      firstDate: DateTime(2000), 
      lastDate: DateTime(2101)
    );
    if (picked != null) {
      setState(() {
        _selectedFechaFin = picked;
        _fechaFinController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar "${widget.gasto?.descripcion}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<GastoBloc>().add(DeleteGasto(widget.gasto!.id));
      Navigator.pop(context);
    }
  }

  Future<void> _saveGasto() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoria == null) {
        _showSnackBar('Seleccione una categoría.', Colors.red);
        return;
      }

      final cleanMonto = _montoController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final double? monto = double.tryParse(cleanMonto);
      
      if (monto == null || monto <= 0) {
        _showSnackBar('Monto inválido.', Colors.red);
        return;
      }

      try {
        if (widget.gasto == null) {
          if (_esFijo) {
            if (_selectedFechaInicio == null || _selectedFechaFin == null) {
              _showSnackBar('Seleccione rango de fechas.', Colors.red);
              return;
            }
            if (_selectedFechaFin!.isBefore(_selectedFechaInicio!)) {
              _showSnackBar('La fecha de fin debe ser posterior a la de inicio.', Colors.red);
              return;
            }

            // Flujo corregido para evitar n registros por mes
            final DateTime fechaDesdeCapturada = _selectedFechaInicio!; // Captura de Fecha Inicial
            DateTime fechaProceso = _selectedFechaFin!; 

            // Normalizamos a medianoche para evitar errores de comparación por milisegundos
            DateTime limite = DateTime(fechaDesdeCapturada.year, fechaDesdeCapturada.month, fechaDesdeCapturada.day);

            while (!fechaProceso.isBefore(limite)) {
              // Crear el objeto Gasto con la fechaProceso actual
              final newGasto = Gasto(
                id: 0,
                descripcion: _descripcionController.text,
                monto: monto,
                fecha: fechaProceso,
                activo: true,
                idCategoria: _selectedCategoria!.id,
                esFijo: true,
              );
              
              context.read<GastoBloc>().add(AddGasto(newGasto));

              // RETROCESO MENSUAL: Al procesar de fin a inicio, aseguramos que el último reload sea del mes inicial.
              fechaProceso = DateTime(fechaProceso.year, fechaProceso.month - 1, fechaProceso.day);
            }

            // Preservar Estado: Reforzamos la carga del mes inicial para evitar el salto visual al último mes del rango.
            context.read<GastoBloc>().add(LoadGastos(fechaDesdeCapturada));
          } else {
            final newGasto = Gasto(
              id: 0,
              descripcion: _descripcionController.text,
              monto: monto,
              fecha: _selectedDate,
              activo: true,
              idCategoria: _selectedCategoria!.id,
              esFijo: false,
            );
            context.read<GastoBloc>().add(AddGasto(newGasto));
          }
          
          final prefs = await SharedPreferences.getInstance();
          if (!(prefs.getBool('first_record_done') ?? false)) {
            await prefs.setBool('first_record_done', true);
            if (mounted) {
              Navigator.pop(context);
              _showReminderDialog(context);
              return;
            }
          }
        } else {
          final updatedGasto = Gasto(
            id: widget.gasto!.id,
            descripcion: _descripcionController.text,
            monto: monto,
            fecha: _selectedDate,
            activo: true,
            idCategoria: _selectedCategoria!.id,
            esFijo: _esFijo,
            fechaInicio: _selectedFechaInicio,
            fechaFin: _selectedFechaFin,
          );
          context.read<GastoBloc>().add(UpdateGasto(updatedGasto));
        }
        
        if (mounted) {
          _showSnackBar('Registro guardado correctamente.', Colors.green);
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
        content: const Text('¿Quieres activar avisos para no olvidar registrar tus gastos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('LUEGO')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', true);
              if (context.mounted) {
                Navigator.pop(context);
                _showSnackBar('Recordatorios activados. Ve a Ajustes.', Colors.blue);
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  Text(
                    widget.gasto == null ? 'Nuevo Registro' : 'Editar Registro',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  widget.gasto != null 
                    ? IconButton(onPressed: _confirmDelete, icon: const Icon(Icons.delete_forever, color: Colors.red))
                    : const SizedBox(width: 48),
                ],
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
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('¿Es un gasto fijo?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Switch(
                    value: _esFijo,
                    activeColor: Colors.red.shade700,
                    onChanged: (value) {
                      setState(() {
                        _esFijo = value;
                        if (!_esFijo) {
                          // Resetear fechas al desactivar
                          final now = DateTime.now();
                          _selectedDate = now;
                          _fechaController.text = DateFormat('dd/MM/yyyy').format(now);
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
              const SizedBox(height: 10),

              if (!_esFijo)
                TextFormField(
                  controller: _fechaController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fechaInicioController,
                        readOnly: true,
                        onTap: () => _selectFechaInicio(context),
                        decoration: const InputDecoration(labelText: 'Desde', border: OutlineInputBorder(), prefixIcon: Icon(Icons.date_range)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _fechaFinController,
                        readOnly: true,
                        onTap: () => _selectFechaFin(context),
                        decoration: const InputDecoration(labelText: 'Hasta', border: OutlineInputBorder(), prefixIcon: Icon(Icons.event_available)),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveGasto,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Registro'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriasSelector() {
    return StreamBuilder<List<Categoria>>(
      stream: context.read<CategoriaRepository>().watchAllCategorias(),
      builder: (context, snapshot) {
        final raw = snapshot.data ?? [];
        if (raw.isEmpty && snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final cats = List<Categoria>.from(raw)..sort((a, b) {
          int getPriority(String d) { final s = d.toLowerCase(); if (s == 'sueldo') return 0; if (s == 'crédito' || s == 'credito') return 1; if (s == 'ahorro') return 2; return 3; }
          final pA = getPriority(a.descripcion); final pB = getPriority(b.descripcion); return (pA != pB) ? pA.compareTo(pB) : a.descripcion.toLowerCase().compareTo(b.descripcion.toLowerCase());
        });
        if (_selectedCategoria == null && cats.isNotEmpty) {
          _selectedCategoria = widget.gasto != null ? cats.firstWhere((c) => c.id == widget.gasto!.idCategoria, orElse: () => cats.first) : cats.first;
        }
        return SizedBox(height: 50, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: cats.length + 1, separatorBuilder: (c, i) => const SizedBox(width: 8), itemBuilder: (c, i) {
          if (i == cats.length) return ActionChip(avatar: const Icon(Icons.add, size: 18), label: const Text('Nueva'), onPressed: _showCreateCategoriaDialog);
          final cat = cats[i]; final isSelected = _selectedCategoria?.id == cat.id; final color = Color(cat.colorValue);
          return ChoiceChip(label: Text(cat.descripcion), selected: isSelected, selectedColor: color.withOpacity(0.3), side: isSelected ? BorderSide(color: color, width: 2) : null, onSelected: (s) { if (s) setState(() => _selectedCategoria = cat); });
        }));
      },
    );
  }

  Future<void> _showCreateCategoriaDialog() async {
    final ctrl = TextEditingController(); TipoCategoria t = TipoCategoria.gasto; Color col = Colors.orange;
    final cols = [Colors.green, Colors.red, Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber, Colors.indigo, const Color(0xFF00BFFF)];
    await showDialog(context: context, builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(title: const Text('Nueva Categoría'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nombre'), autofocus: true, textCapitalization: TextCapitalization.sentences),
      const SizedBox(height: 15), const Text('Tipo:'), Row(children: [
        Expanded(child: RadioListTile<TipoCategoria>(title: const Text('Gasto', style: TextStyle(fontSize: 10)), value: TipoCategoria.gasto, groupValue: t, contentPadding: EdgeInsets.zero, onChanged: (v) => setS(() => t = v!))),
        Expanded(child: RadioListTile<TipoCategoria>(title: const Text('Ingreso', style: TextStyle(fontSize: 10)), value: TipoCategoria.ingreso, groupValue: t, contentPadding: EdgeInsets.zero, onChanged: (v) => setS(() => t = v!))),
        Expanded(child: RadioListTile<TipoCategoria>(title: const Text('Ahorro', style: TextStyle(fontSize: 10)), value: TipoCategoria.ahorro, groupValue: t, contentPadding: EdgeInsets.zero, onChanged: (v) => setS(() => t = v!))),
      ]),
      const SizedBox(height: 15), const Text('Color:'), const SizedBox(height: 8),
      SizedBox(height: 40, width: double.maxFinite, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: cols.length, separatorBuilder: (c, i) => const SizedBox(width: 8), itemBuilder: (c, i) {
        final isS = cols[i].value == col.value; return GestureDetector(onTap: () => setS(() => col = cols[i]), child: Container(width: 35, height: 35, decoration: BoxDecoration(color: cols[i], shape: BoxShape.circle, border: isS ? Border.all(color: Colors.black, width: 2) : null), child: isS ? const Icon(Icons.check, color: Colors.white, size: 20) : null));
      })),
    ])), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')), ElevatedButton(onPressed: () async { if (ctrl.text.trim().isNotEmpty) { final cat = Categoria(id: 0, descripcion: ctrl.text.trim(), colorValue: col.value, tipo: t); try { final id = await context.read<CategoriaRepository>().insertCategoria(cat); if (mounted) { setState(() => _selectedCategoria = cat.copyWith(id: id)); Navigator.pop(c); } } catch (e) { _showSnackBar('Error: $e', Colors.red); } } }, child: const Text('Guardar'))])));
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('es_CL');
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue newVal) {
    if (newVal.text.isEmpty) return newVal.copyWith(text: '');
    String t = newVal.text.replaceAll(RegExp(r'[^0-9]'), ''); int? v = int.tryParse(t); if (v == null) return old;
    String ft = _formatter.format(v); return TextEditingValue(text: ft, selection: TextSelection.collapsed(offset: ft.length));
  }
}
