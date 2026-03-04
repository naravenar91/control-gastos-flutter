import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/theme_cubit.dart';
import '../../infrastructure/notification_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
