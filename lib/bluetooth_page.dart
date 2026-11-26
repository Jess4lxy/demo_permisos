import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  String status = 'Comprobando Bluetooth...';

  List<ScanResult> devices = [];

  StreamSubscription<BluetoothAdapterState>? adapterSubscription;
  StreamSubscription<List<ScanResult>>? scanSubscription;

  bool bluetoothOn = false;
  bool supported = true;

  @override
  void initState() {
    super.initState();

    checkBluetooth();

    adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) return;

      setState(() {
        bluetoothOn = state == BluetoothAdapterState.on;

        if (state == BluetoothAdapterState.on) {
          status = 'Bluetooth activado. Ya puedes buscar dispositivos.';
        } else if (state == BluetoothAdapterState.off) {
          status = 'Bluetooth desactivado. Actívalo para continuar.';
          devices.clear();
        } else if (state == BluetoothAdapterState.turningOn) {
          status = 'Activando Bluetooth...';
        } else if (state == BluetoothAdapterState.turningOff) {
          status = 'Desactivando Bluetooth...';
        } else if (state == BluetoothAdapterState.unauthorized) {
          status = 'No hay autorización para acceder al Bluetooth.';
        } else if (state == BluetoothAdapterState.unavailable) {
          status = 'Bluetooth no está disponible.';
        }
      });
    });

    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;

      setState(() {
        devices = results;
        status = results.isEmpty
            ? 'Buscando dispositivos Bluetooth...'
            : 'Dispositivos encontrados: ${results.length}';
      });
    });
  }

  Future<void> checkBluetooth() async {
    try {
      supported = await FlutterBluePlus.isSupported;

      if (!supported) {
        setState(() {
          status = 'Este dispositivo no es compatible con Bluetooth.';
        });
        return;
      }

      final state = await FlutterBluePlus.adapterState.first;

      if (!mounted) return;

      setState(() {
        bluetoothOn = state == BluetoothAdapterState.on;
        status = bluetoothOn
            ? 'Bluetooth activado. Ya puedes buscar dispositivos.'
            : 'Bluetooth desactivado. Actívalo para continuar.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status = 'No se pudo comprobar el estado del Bluetooth.';
      });
    }
  }

  Future<bool> requestBluetoothPermissions() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();

    if (scan.isGranted && connect.isGranted) {
      if (!mounted) return false;

      setState(() {
        status = 'Permisos Bluetooth concedidos.';
      });

      return true;
    }

    if (!mounted) return false;

    setState(() {
      status = 'Debes conceder los permisos Bluetooth.';
    });

    if (scan.isPermanentlyDenied || connect.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  Future<void> activateBluetooth() async {
    final granted = await requestBluetoothPermissions();

    if (!granted) return;

    try {
      if (!mounted) return;

      setState(() {
        status = 'Esperando confirmación para activar Bluetooth...';
      });

      // Solicita al sistema Android activar Bluetooth.
      await FlutterBluePlus.turnOn();

      // Comprueba si realmente se encendió.
      bool isOn = await FlutterBluePlus.isOn;

      // Si todavía está apagado, espera el cambio de estado.
      if (!isOn) {
        try {
          await FlutterBluePlus.adapterState
              .firstWhere((state) => state == BluetoothAdapterState.on)
              .timeout(const Duration(seconds: 15));

          isOn = await FlutterBluePlus.isOn;
        } on TimeoutException {
          isOn = await FlutterBluePlus.isOn;
        }
      }

      if (!mounted) return;

      setState(() {
        bluetoothOn = isOn;
        status = isOn
            ? '¡Bluetooth activado correctamente!'
            : 'Bluetooth sigue desactivado. Puedes activarlo desde los ajustes del celular.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            'No se pudo activar Bluetooth. Inténtalo desde los ajustes del celular.';
      });
    }
  }

  Future<void> startScan() async {
    final granted = await requestBluetoothPermissions();

    if (!granted) return;

    try {
      if (!supported) {
        setState(() {
          status = 'Bluetooth no es compatible con este dispositivo.';
        });
        return;
      }

      final isOn = await FlutterBluePlus.isOn;

      if (!isOn) {
        setState(() {
          bluetoothOn = false;
          status = 'Bluetooth está apagado. Pulsa "Activar Bluetooth".';
        });
        return;
      }

      setState(() {
        devices.clear();
        status = 'Buscando dispositivos Bluetooth...';
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            'No se pudo iniciar la búsqueda. Comprueba Bluetooth y los permisos.';
      });
    }
  }

  @override
  void dispose() {
    adapterSubscription?.cancel();
    scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1.14 Bluetooth'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              bluetoothOn
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              size: 90,
              color: bluetoothOn ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 15),
            const Text(
              'Permisos Bluetooth',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              status,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: requestBluetoothPermissions,
              icon: const Icon(Icons.security),
              label: const Text('Solicitar permisos'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: activateBluetooth,
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Activar Bluetooth'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: startScan,
              icon: const Icon(Icons.search),
              label: const Text('Buscar dispositivos'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dispositivos encontrados:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: devices.isEmpty
                  ? const Center(
                      child: Text('No hay dispositivos encontrados.'),
                    )
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];

                        return ListTile(
                          leading: const Icon(Icons.bluetooth_connected),
                          title: Text(
                            device.device.platformName.isNotEmpty
                                ? device.device.platformName
                                : 'Dispositivo desconocido',
                          ),
                          subtitle: Text(
                            device.device.remoteId.toString(),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
