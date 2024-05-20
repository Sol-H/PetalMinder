import 'dart:async';
import 'dart:io';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'gpt_service.dart';
import 'disease_api_service.dart';

class DiseaseCameraScreen extends StatefulWidget {
  const DiseaseCameraScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  DiseaseCameraScreenState createState() => DiseaseCameraScreenState();
}

class DiseaseCameraScreenState extends State<DiseaseCameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();

            if (!context.mounted) return;

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  imagePath: image.path,
                ),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
          }
        },
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayPictureScreen({Key? key, required this.imagePath})
      : super(key: key);

  @override
  DisplayPictureScreenState createState() => DisplayPictureScreenState();
}

class DisplayPictureScreenState extends State<DisplayPictureScreen> {
  late var apiService = DiseaseApiService();
  var gptService = GPTService();
  String diseaseName = '';
  String diseasePrecautions = '';
  bool detecting = false;
  bool precautionLoading = false;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
  }

  detectDisease() async {
    setState(() {
      detecting = true;
      precautionLoading = true;
    });

    try {
      diseaseName = await apiService.sendImageToPlantId(image: selectedImage!);
      print(diseaseName);
    } catch (error) {
      print(error);
    } finally {
      setState(() {
        detecting = false;
      });
    }
  }

  getPrecautions() async {
    setState(() {
      precautionLoading = true;
    });
    try {
      if (diseasePrecautions == '') {
        diseasePrecautions =
            await gptService.sendMessageGPT(diseaseName: diseaseName);
      }
    } catch (error) {
      print(error);
    } finally {
      setState(() {
        precautionLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disease Detector')),
      body: detecting || precautionLoading
          ? const Center(child: CircularProgressIndicator())
          : diseaseName == ''
              ? Column(children: [
                  Image.file(File(widget.imagePath)),
                  ElevatedButton(
                    onPressed: () async {
                      selectedImage = File(widget.imagePath);
                      detectDisease();
                      if (diseaseName != 'No disease detected.' &&
                          diseaseName !=
                              'No plant recognised, please try again.') {
                        getPrecautions();
                      }
                    },
                    child: const Text('Scan Image'),
                  ),
                ])
              : Column(
                  children: diseaseName != 'No disease detected.' &&
                          diseaseName !=
                              'No plant recognised, please try again.'
                      ? [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: Image.file(File(widget.imagePath)),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'Disease Detected:',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(diseaseName),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'Precautions:',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(
                              child: Column(
                                children: diseasePrecautions
                                    .split('- ')
                                    .skip(1)
                                    .map((precaution) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check_circle,
                                            size: 12),
                                        const SizedBox(width: 4),
                                        Expanded(
                                            child: Text(precaution.trim())),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ]
                      : [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: Image.file(File(widget.imagePath)),
                          ),
                          Text(diseaseName),
                        ]),
    );
  }
}
