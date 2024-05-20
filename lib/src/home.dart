import 'dart:io';

import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_app/src/disease_camera.dart';
import 'plant_card.dart';
import 'add_plant_screen.dart';
import 'plant.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:camera/camera.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final useruid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late List<CameraDescription> cameras;
  late CameraDescription firstCamera;
  late String fcmToken = '';

  @override
  void initState() {
    super.initState();
    initCamera();
    initNotifications();
  }

  Future<void> initNotifications() async {
    if (Platform.isAndroid) {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await Permission.notification.isDenied.then((value) {
        if (value) {
          Permission.notification.request();
        }
      });
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true, 
      );
      fcmToken = (await messaging.getToken())!;
      print('User granted permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    firstCamera = cameras.first;
  }

  @override
  Widget build(BuildContext context) {
    var plantsRef = FirebaseDatabase.instance.ref();
    FocusManager.instance.primaryFocus?.unfocus();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetalMinder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ProfileScreen(
                    appBar: AppBar(
                      title: const Text('User Profile'),
                    ),
                    actions: [
                      SignedOutAction((context) {
                        Navigator.of(context).pop();
                      })
                    ],
                    children: const [
                      Divider(),
                      Padding(
                        padding: EdgeInsets.all(20),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        ],
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: plantsRef
            .child('plants')
            .orderByChild('user_uid')
            .equalTo(useruid)
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData ||
              snapshot.data?.snapshot.value == null) {
            return Center(
                child: Column(children: [
              const Text('No plants found.'),
              ElevatedButton(
                child: const Text(
                  'Add a Plant',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddPlantScreen()),
                  );
                },
              ),
            ]));
          } else {
            var data = snapshot.data!.snapshot.value;
            List<dynamic> plantsData = [];
            if (data is Map) {
              plantsData = data.values.toList();
            } else if (data is List) {
              plantsData = data;
            }
            List<Plant> plants = plantsData
                .where((plantData) => plantData != null)
                .map((plantData) {
              if (plantData != null) {
                String plantId = plantData['plant_id'].toString();
                List<String> notificationTokens = plantData['notification_tokens'] != null 
                  ? List<String>.from(plantData['notification_tokens'])
                  : [];

                if (!notificationTokens.contains(fcmToken)) {
                  notificationTokens.add(fcmToken);
                  plantsRef.child('plants').child(plantId).update({
                    'notification_tokens': notificationTokens,
                  });
                }
                return Plant(
                  plantId: plantData['plant_id'],
                  moistureValue: plantData['moisture_value'],
                  plantName: plantData['plant_name'],
                  userUid: plantData['user_uid'],
                  plantSpecies: plantData['plant_species'],
                );
              } else {
                return Plant(
                  plantId: 0,
                  moistureValue: 0,
                  plantName: 'No name',
                  userUid: 'No user',
                  plantSpecies: 'No species',
                );
              }
            }).toList();

            return Column(
              children: [
                const SizedBox(height: 20),
                CarouselSlider(
                  items: [
                    ...plants.map((plant) {
                      return PlantCard(plant);
                    }).toList(),
                  ],
                  options: CarouselOptions(
                    height: MediaQuery.of(context).size.height * 0.6,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: false,
                    scrollDirection: Axis.horizontal,
                    initialPage: 0,
                  ),
                ),
                const SizedBox(height: 20),
                // 'Add a Plant' button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddPlantScreen()),
                    );
                  },
                  child: const Text(
                    'Add a Plant',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_enhance),
            label: 'Disease Detector',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      const HomeScreen(),
                  transitionDuration: const Duration(seconds: 0),
                ),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      DiseaseCameraScreen(
                    camera: firstCamera,
                  ),
                  transitionDuration: const Duration(seconds: 0),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}
