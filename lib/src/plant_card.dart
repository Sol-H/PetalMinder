import 'package:flutter/material.dart';
import 'plant.dart';
import 'device_setup_screen.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'plant_info_api_service.dart';
import 'edit_plant_screen.dart';

class PlantCard extends StatefulWidget {
  final Plant plant;

  const PlantCard(this.plant, {Key? key}) : super(key: key);

  @override
  PlantCardState createState() => PlantCardState();
}

class PlantCardState extends State<PlantCard> {
  Future _wateringInfoFuture = Future.value('');
  Future _speciesImageFuture = Future.value('');
  Future _speciesInfoFuture = Future.value('');

  @override
  void initState() {
    super.initState();
    _wateringInfoFuture = _getWateringInfo();
    _speciesImageFuture = _getSpeciesImage();
    _speciesInfoFuture = _getSpeciesInfo();
  }

  String _wateringInfo = '';
  int _speciesID = 0;
  String _speciesImage = '';
  Map<String, dynamic> _speciesInfo = {};

  Future<void> _getWateringInfo() async {
    final apiService = InfoApiService();
    final plantSpecies = widget.plant.plantSpecies;
    _speciesID = await apiService.getPlantID(query: plantSpecies);
    final wateringInfo =
        await apiService.getWateringInfo(speciesID: _speciesID);
    setState(() {
      _wateringInfo = wateringInfo;
    });
  }

  Future<void> _getSpeciesImage() async {
    final apiService = InfoApiService();
    final plantSpecies = widget.plant.plantSpecies;
    _speciesID = await apiService.getPlantID(query: plantSpecies);
    final speciesImage = await apiService.getPlantImage(speciesID: _speciesID);
    setState(() {
      _speciesImage = speciesImage;
    });
  }

  Future<void> _getSpeciesInfo() async {
    final apiService = InfoApiService();
    final plantSpecies = widget.plant.plantSpecies;
    _speciesID = await apiService.getPlantID(query: plantSpecies);
    final speciesInfo = await apiService.getPlantInfo(speciesID: _speciesID);
    setState(() {
      _speciesInfo = speciesInfo;
    });
  }

  void navigateToPlantInfoPage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
          appBar: AppBar(
            title: Text("About ${widget.plant.plantSpecies}s"),
          ),
          body: SingleChildScrollView(
              child: Column(children: [
            FutureBuilder(
              future: _speciesImageFuture,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Loading image...');
                } else {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: _speciesImage.isNotEmpty
                          ? Image.network(
                              _speciesImage,
                              height: 200,
                            )
                          : const Text(''),
                    );
                  }
                }
              },
            ),
            FutureBuilder(
                future: _speciesInfoFuture,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Loading species info...');
                  } else {
                    if (snapshot.hasError) {
                      print(snapshot.error);
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Column(
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.local_florist),
                                    Text(
                                      _speciesInfo["growth_rate"],
                                    ),
                                  ])),
                          Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.sunny),
                                    Text(
                                      _speciesInfo["sunlight"],
                                    ),
                                  ])),
                          Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.spa),
                                    Text(
                                      _speciesInfo["care_level"],
                                    ),
                                  ])),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              _speciesInfo["description"],
                            ),
                          ),
                        ],
                      );
                    }
                  }
                }),
          ])));
    }));
  }

  String getMoistureMessage(double moisturePercentage) {
    if (moisturePercentage <= 0.30) return "Very Dry";
    if (moisturePercentage <= 0.60) return "Moderately Dry";
    if (moisturePercentage <= 0.80) return "Moist";
    return "Fully Hydrated";
  }

  void deletePlantDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this plant?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                deletePlant();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void deletePlant() {
    // Delete the plant from the database
    FirebaseDatabase.instance
        .ref()
        .child('plants')
        .child(widget.plant.plantId.toString())
        .remove();
  }

  @override
  Widget build(BuildContext context) {
    int minThreshold = 200;
    int maxThreshold = 550;
    double moisturePercent = 1 -
        ((widget.plant.moistureValue - minThreshold) /
            (maxThreshold-minThreshold)); // Percentage between values 200 and 550
    if (moisturePercent < 0) moisturePercent = 0;
    return Stack(children: <Widget>[
      Card(
        child: ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(widget.plant.plantName),
              ),
              IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                    EditPlantScreen(widget.plant),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit)),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  deletePlantDialog(context);
                },
              ),
            ],
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  widget.plant.plantSpecies,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              widget.plant.moistureValue == 0
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text("No Device connected"),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CircularPercentIndicator(
                        radius: 50.0,
                        lineWidth: 10.0,
                        percent:
                            moisturePercent, // assuming moistureValue is between 0 and 100
                        center: const Icon(Icons.water_drop, size: 30.0),
                        progressColor: Colors.blue,
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: true,
                        animationDuration: 1200,
                      ),
                    ),
              if (widget.plant.moistureValue > 0)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(getMoistureMessage(moisturePercent)),
                ),
              Padding(
                padding: const EdgeInsets.all(0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () {
                        navigateToPlantInfoPage(context);
                      },
                      icon: const Icon(Icons.info),
                      iconSize: 30,
                    ),
                    FutureBuilder(
                      future: _wateringInfoFuture,
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('');
                        } else {
                          if (snapshot.hasError) {
                            print(snapshot.error);
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return TextButton(
                                child: Text(_wateringInfo),
                                onPressed: () {
                                  navigateToPlantInfoPage(context);
                                });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeviceSetupScreen(
                          plantId: widget.plant.plantId.toString(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 34, 85, 36),
                  ),
                  child: const Text(
                    'Configure Device',
                    style: TextStyle(
                      color: Color.fromARGB(255, 249, 255, 232),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}
