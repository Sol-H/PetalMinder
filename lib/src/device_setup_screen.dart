import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'wifi_setup_screen.dart';

class DeviceSetupScreen extends StatefulWidget {
  final String plantId;
   const DeviceSetupScreen({Key? key, required this.plantId}) : super(key: key);

  @override
  _DeviceSetupScreenState createState() => _DeviceSetupScreenState(selectedPlantId: plantId);
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  late final String selectedPlantId;

  List<BluetoothDevice> devices = [];
  bool _isButtonEnabled = true;

  _DeviceSetupScreenState({required this.selectedPlantId});

  void searchDevices() async {
    if (!_isButtonEnabled) return;
    // Request location & Bluetooth permissions
    await [
      Permission.location,
      Permission.bluetooth,
    ].request();

    // Check if Bluetooth is available
    var scanSubscription = FlutterBluePlus.adapterState
        .listen((BluetoothAdapterState state) async {
      if (state == BluetoothAdapterState.on) {

        // Scan for Bluetooth devices
        FlutterBluePlus.onScanResults.listen(
          (results) async {
            if (results.isNotEmpty) {
              ScanResult r = results.last; // the most recently found device
              setState(() {
                if (!devices.contains(r.device)) {
                  devices.add(r.device);
                }
              });
            }
          },
          onError: (e) => print(e),
        );
      } else {
        // show an error to the user
        //showBluetoothUnavailablePopup();
      }
    });
    // cleanup: cancel subscription when scanning stops
    FlutterBluePlus.cancelWhenScanComplete(scanSubscription);

    // Wait for Bluetooth enabled & permission granted
    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    // Start scanning w/ timeout
    await FlutterBluePlus.startScan(
        withNames: ["MoistureMonitor"], timeout: const Duration(seconds: 15));
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    scanSubscription.cancel();
  }

  void showBluetoothUnavailablePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bluetooth Unavailable'),
          content: const Text('Bluetooth is not available.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void Function() handleTap(BluetoothDevice device) {
    return () async {
      // listen for disconnection
      var subscription =
          device.connectionState.listen((BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.disconnected) {
          await device.connect();
          await device.discoverServices();
        }
      });

      // cleanup: cancel subscription when disconnected
      device.cancelWhenDisconnected(subscription, delayed: true, next: true);

      // Connect to the device
      await device.connect();

      device.connectionState.listen((BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.connected) {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => WifiSetupScreen(device: device, plantId: selectedPlantId)),
          );
        }
      });
    };
  }

  Widget buildDeviceList() {
    return ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          var device = devices[index];
          return Padding(
            padding: const EdgeInsets.all(40.0),
            child: ElevatedButton(
              onPressed: handleTap(device),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sensors, color: Colors.black),
                  Text(
                    devices[index].advName,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Setup Device'),
        ),
        body: Column(children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                    'If you are setting up a new device, or need to reconnect a device, follow these steps:'),
                SizedBox(height: 10),
                Text('1. Have your WiFi details to hand.'),
                SizedBox(height: 10),
                Text(
                    '2. Make sure your Moisture Monitor is turned on, nearby, and inserted into the soil.'),
                SizedBox(height: 10),
                Text(
                    '3. Press the button below to search for devices. Your Moisture Monitor should appear in the list.'),
                SizedBox(height: 10),
                Text('4. Tap on your Moisture Monitor to connect to it.'),
                SizedBox(height: 10),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isButtonEnabled
                ? () {
                    devices.clear();
                    searchDevices();
                    setState(() {
                      _isButtonEnabled = false;
                    });
                    Timer(const Duration(seconds: 14), () {
                      setState(() {
                        _isButtonEnabled = true;
                      });
                    });
                  }
                : null,
            child: const Text('Search for devices'),
          ),
          Expanded(
            child: buildDeviceList(),
          ),
          Container(
            padding: const EdgeInsets.all(40.0),
            child: const Text(
              'Need help? Contact us at support@solh.dev',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 12.0,
              ),
            ),
          ),
        ]));
  }
}
