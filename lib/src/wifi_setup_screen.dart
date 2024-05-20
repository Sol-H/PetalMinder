import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WifiSetupScreen extends StatefulWidget {
  final BluetoothDevice device;
  final String plantId;

  const WifiSetupScreen({super.key, required this.device, required this.plantId});

  @override
  _WifiSetupScreenState createState() =>
      _WifiSetupScreenState(selectedDevice: device, selectedPlantId: plantId);
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  late BluetoothDevice selectedDevice;
  late BluetoothService wifiService;
  late final String selectedPlantId;
  final useruid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final storage = const FlutterSecureStorage();
  bool useStoredCredentials = false;

  _WifiSetupScreenState({required this.selectedDevice, required this.selectedPlantId});
  

  @override
  void initState() {
    super.initState();
    getServices(selectedDevice);
  }

  getServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid == Guid("12345678-1234-1234-1234-123456789abc")) {
        wifiService = service;
      }
    }
  }

  loadWifiCredentials() async {
    String? ssid = await storage.read(key: 'ssid');
    String? password = await storage.read(key: 'password');
    if (ssid != null && password != null) {
      await connectToWifi(ssid, password);
    }
  }

  saveWifiCredentials(String ssid, String password) async {
    await storage.write(key: 'ssid', value: ssid);
    await storage.write(key: 'password', value: password);
  }

  Future<void> connectToWifi(String ssid, String password) async {
    // Connect to Wi-Fi
    BluetoothCharacteristic? ssidCharacteristic;
    BluetoothCharacteristic? passwordCharacteristic;
    BluetoothCharacteristic?
        userCharacteristic1; // Have to split in chunks of 20 bytes
    BluetoothCharacteristic? userCharacteristic2;
    BluetoothCharacteristic? plantIdCharacteristic;
    BluetoothCharacteristic? connectedCharacteristic;
    // ensure services are ready
    await getServices(selectedDevice);

    for (BluetoothCharacteristic c in wifiService.characteristics) {
      if (c.uuid == Guid("12345678-1234-1234-1234-123456789abd")) {
        ssidCharacteristic = c;
      } else if (c.uuid == Guid("12345678-1234-1234-1234-123456789abe")) {
        passwordCharacteristic = c;
      } else if (c.uuid == Guid("12345678-1234-1234-1234-123456789abf")) {
        userCharacteristic1 = c;
      } else if (c.uuid == Guid("12345678-1234-1234-1234-123456789ac1")) {
        userCharacteristic2 = c;
      } else if (c.uuid == Guid("12345678-1234-1234-1234-123456789ac2")) {
        plantIdCharacteristic = c;
      } else if (c.uuid == Guid("12345678-1234-1234-1234-123456789ac0")) {
        connectedCharacteristic = c;
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    if (ssidCharacteristic != null &&
        passwordCharacteristic != null &&
        userCharacteristic1 != null &&
        userCharacteristic2 != null &&
        plantIdCharacteristic != null) {
      print(ssid);
      print(password);
      print(useruid);

      List<int> plantIdBytes = utf8.encode(selectedPlantId);
      await plantIdCharacteristic.write(plantIdBytes);

      List<int> ssidBytes = utf8.encode(ssid);
      await ssidCharacteristic.write(ssidBytes);

      List<int> passwordBytes = utf8.encode(password);
      await passwordCharacteristic.write(passwordBytes);

      List<int> userBytes = utf8.encode(useruid);
      var userBytesChunk1 = userBytes.sublist(0, 20);
      var userBytesChunk2 = userBytes.sublist(20, userBytes.length);
      await userCharacteristic1.write(userBytesChunk1);
      await userCharacteristic2.write(userBytesChunk2);

      await Future.delayed(const Duration(seconds: 1));
      List<int> connected = await connectedCharacteristic!.read();
      bool connectedBool = utf8.decode(connected) == 'connected';
      print(connectedBool);

      if (connectedBool) {
        saveWifiCredentials(ssid, password);
        print('credentials saved');
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Connected to WiFi'),
                content: const Text(
                    'Your device is now connected to Wi-Fi. It will appear on the home screen to be edited.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Go Home'),
                    onPressed: () {
                      Navigator.popUntil(context, ModalRoute.withName('/'));
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String? ssid = '';
    String? password = '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wifi Setup'),
      ),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              CheckboxListTile(
                title: const Text('Use stored credentials'),
                value: useStoredCredentials,
                onChanged: (newValue) {
                  setState(() {
                    useStoredCredentials = newValue ?? false;
                  });
                },
                controlAffinity:
                    ListTileControlAffinity.leading, //  <-- leading Checkbox
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'SSID'),
                enabled: !useStoredCredentials,
                onSaved: (value) {
                  ssid = value!;
                },
                validator: (value) {
                  if (!useStoredCredentials && (value?.isEmpty ?? true)) {
                    return 'Please enter SSID';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                enabled: !useStoredCredentials,
                onSaved: (value) {
                  password = value!;
                },
                validator: (value) {
                  if (!useStoredCredentials && (value?.isEmpty ?? true)) {
                    return 'Please enter Password';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    formKey.currentState?.save();
                    if (useStoredCredentials) {
                      ssid = await storage.read(key: 'ssid');
                      password = await storage.read(key: 'password');
                    }
                    await connectToWifi(ssid ?? '', password ?? '');
                  }
                },
                child: const Text('Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
