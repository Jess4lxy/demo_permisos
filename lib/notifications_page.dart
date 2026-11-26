import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  String status = 'Esperando acción del usuario...';

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  Future<void> initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await notifications.initialize(settings);

    if (!mounted) return;

    setState(() {
      status = 'Servicio de notificaciones inicializado.';
    });
  }

  Future<void> requestPermission() async {
    final android = notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final granted = await android?.requestNotificationsPermission();

    if (!mounted) return;

    setState(() {
      status = granted == true
          ? 'Permiso de notificaciones concedido.'
          : 'Permiso denegado o no disponible.';
    });
  }

  Future<void> showNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'demo_channel',
        'Notificaciones de prueba',
        channelDescription: 'Canal de notificaciones de demostración',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await notifications.show(
      1,
      '¡Hola!',
      'Esta es una notificación de prueba en Flutter.',
      details,
    );

    if (!mounted) return;

    setState(() {
      status = 'Notificación enviada correctamente.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1.13 Notificaciones'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 90,
                color: Colors.indigo,
              ),
              const SizedBox(height: 20),
              const Text(
                'Permisos de notificaciones',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                status,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: requestPermission,
                icon: const Icon(Icons.security),
                label: const Text('Solicitar permiso'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: showNotification,
                icon: const Icon(Icons.send),
                label: const Text('Enviar notificación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
