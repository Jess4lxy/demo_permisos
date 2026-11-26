import 'package:flutter/material.dart';

import 'notifications_page.dart';
import 'reminders_page.dart';
import 'bluetooth_page.dart';

void main() => runApp(const DemoPermisosApp());

class DemoPermisosApp extends StatelessWidget {
  const DemoPermisosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permisos en Flutter - Equipo 5',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget page;
  const _MenuItem(this.title, this.icon, this.page);
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem('1.7 Reminders', Icons.phone, const RemindersPage()),
      _MenuItem('1.13 Notificaciones', Icons.alarm, const NotificationsPage()),
      _MenuItem('1.14 Bluetooth', Icons.sensors, const BluetoothPage()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Permisos - Equipo 5')),
      body: ListView(
        children: [
          for (final item in items)
            ListTile(
              leading: Icon(item.icon),
              title: Text(item.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.page),
              ),
            ),
        ],
      ),
    );
  }
}
