import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final _titleController = TextEditingController(text: 'Entregar Actividad 12');
  DateTime _when = DateTime.now().add(const Duration(hours: 1));
  String _statusText = 'sin solicitar';

  Permission get _permission => defaultTargetPlatform == TargetPlatform.iOS
      ? Permission.reminders
      : Permission.calendarFullAccess;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (time == null) return;

    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _gcal(DateTime d) {
    final u = d.toUtc();
    String t(int n, [int w = 2]) => n.toString().padLeft(w, '0');
    return '${t(u.year, 4)}${t(u.month)}${t(u.day)}'
        'T${t(u.hour)}${t(u.minute)}${t(u.second)}Z';
  }

  Future<void> _saveReminder() async {
    final title = _titleController.text.trim();
    final end = _when.add(const Duration(minutes: 30));

    if (kIsWeb) {
      final uri = Uri.https('calendar.google.com', '/calendar/render', {
        'action': 'TEMPLATE',
        'text': title,
        'dates': '${_gcal(_when)}/${_gcal(end)}',
        'details': 'Recordatorio creado desde Flutter',
        'location': 'Aula IDGS',
      });
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      setState(() => _statusText = 'no aplica en navegador');
      _showMessage(ok ? 'Abriendo Google Calendar' : 'No se pudo abrir');
      return;
    }

    final status = await _permission.request();
    if (!mounted) return;
    setState(() => _statusText = status.name);

    if (!status.isGranted) {
      _showMessage('Permiso denegado');
      if (status.isPermanentlyDenied) await openAppSettings();
      return;
    }

    final event = Event(
      title: title,
      description: 'Recordatorio creado desde Flutter',
      location: 'Aula IDGS',
      startDate: _when,
      endDate: end,
      iosParams: const IOSParams(reminder: Duration(minutes: 10)),
      androidParams: const AndroidParams(),
    );

    final added = await Add2Calendar.addEvent2Cal(event);
    if (!mounted) return;
    _showMessage(added ? 'Recordatorio enviado al calendario' : 'No se agregó');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('1.7 Reminders')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título del recordatorio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_when.toString().substring(0, 16)),
              subtitle: const Text('Fecha y hora'),
              onTap: _pickDateTime,
            ),
            Text('Estado del permiso: $_statusText'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saveReminder,
              icon: const Icon(Icons.alarm_add),
              label: const Text('Crear recordatorio'),
            ),
          ],
        ),
      ),
    );
  }
}
