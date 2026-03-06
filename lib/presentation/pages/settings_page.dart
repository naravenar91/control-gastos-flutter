import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../main.dart';
import '../bloc/theme_cubit.dart';
import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_event.dart';
import '../../infrastructure/notification_service.dart';
import '../../infrastructure/app_database.dart';
import '../../core/constants/app_strings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  final List<bool> _selectedDays = List.generate(7, (_) => true);
  final List<String> _dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  String _appVersion = AppStrings.cargando;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      final hour = prefs.getInt('notification_hour') ?? 9;
      final minute = prefs.getInt('notification_minute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
      
      final daysString = prefs.getStringList('notification_days');
      if (daysString != null) {
        for (int i = 0; i < 7; i++) {
          _selectedDays[i] = daysString.contains((i + 1).toString());
        }
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setInt('notification_hour', _notificationTime.hour);
    await prefs.setInt('notification_minute', _notificationTime.minute);
    
    final List<String> daysString = [];
    final List<int> activeDays = [];
    for (int i = 0; i < 7; i++) {
      if (_selectedDays[i]) {
        daysString.add((i + 1).toString());
        activeDays.add(i + 1);
      }
    }
    await prefs.setStringList('notification_days', daysString);

    if (_notificationsEnabled && activeDays.isNotEmpty) {
      await NotificationService().scheduleNotifications(activeDays, _notificationTime.hour, _notificationTime.minute);
    } else {
      await NotificationService().cancelAll();
    }
  }

  Future<void> _generateBackup(BuildContext context) async {
    try {
      final db = context.read<AppDatabase>();
      final jsonData = await db.exportToJson();
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/control_gastos_respaldo.json');
      await file.writeAsString(jsonData);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Mi Control de Gastos - Respaldo de datos',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar respaldo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreData(BuildContext context) async {
    final gastoBloc = context.read<GastoBloc>();
    final db = context.read<AppDatabase>();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      // Validación inmediata tras el await
      if (!mounted) return;

      if (result == null || result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      
      // Importación directa para evitar dependencia de context en diálogos
      await db.importFromJson(jsonString);
      
      // Actualización de UI a través del BLoC capturado localmente
      gastoBloc.add(LoadGastos(DateTime.now()));
      
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Datos restaurados con éxito'), 
          backgroundColor: Colors.green
        ),
      );
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${AppStrings.error}: $e'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  void _showBackupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gestión de Datos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Icon(Icons.backup, color: Colors.white),
              ),
              title: const Text('Generar Respaldo (JSON)'),
              subtitle: const Text('Crea un archivo para compartir o guardar'),
              onTap: () {
                Navigator.pop(context);
                _generateBackup(context);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.restore, color: Colors.white),
              ),
              title: const Text('Restaurar Datos'),
              subtitle: const Text('Carga datos desde un archivo anterior'),
              onTap: () {
                Navigator.pop(context);
                _restoreData(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SECCIÓN APARIENCIA
          _buildSectionTitle('APARIENCIA'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, mode) {
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      value: mode,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('Tema del Sistema')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Modo Claro')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Modo Oscuro')),
                      ],
                      onChanged: (newMode) {
                        if (newMode != null) {
                          context.read<ThemeCubit>().setTheme(newMode);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN NOTIFICACIONES
          _buildSectionTitle('NOTIFICACIONES'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Activar Recordatorios'),
                  subtitle: const Text('Recibe un aviso diario para registrar tus gastos'),
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    setState(() => _notificationsEnabled = value);
                    await _saveSettings();
                  },
                ),
                if (_notificationsEnabled) ...[
                  const Divider(),
                  ListTile(
                    title: const Text('Hora del recordatorio'),
                    trailing: Text(
                      _notificationTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _notificationTime,
                      );
                      if (time != null) {
                        setState(() => _notificationTime = time);
                        await _saveSettings();
                      }
                    },
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Días de la semana', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        ToggleButtons(
                          isSelected: _selectedDays,
                          onPressed: (index) async {
                            setState(() => _selectedDays[index] = !_selectedDays[index]);
                            await _saveSettings();
                          },
                          borderRadius: BorderRadius.circular(8),
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          children: _dayNames.map((day) => Text(day)).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN DATOS Y RESPALDO
          _buildSectionTitle('DATOS Y RESPALDO'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage, color: Colors.blueGrey),
              title: const Text('Gestionar Copias de Seguridad'),
              subtitle: const Text('Exportar o importar tus registros'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showBackupOptions(context),
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN INFORMACIÓN
          _buildSectionTitle('INFORMACIÓN'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blueGrey),
              title: const Text('Acerca de la aplicación'),
              subtitle: const Text('Créditos y versión del proyecto'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAboutAppDialog(context),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gestor de Finanzas Personales',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Versión $_appVersion',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Una herramienta intuitiva para registrar tus movimientos financieros, analizar tus hábitos mediante gráficos y gestionar tus categorías de ahorro de forma eficiente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const Divider(height: 32),
            const Text(
              'Desarrollado por:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const Text(
              'Nicolás Enrique Aravena Riquelme',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Santiago de Chile 🇨🇱',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
