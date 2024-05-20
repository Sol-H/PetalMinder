import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'plant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'plant_info_api_service.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  AddPlantScreenState createState() => AddPlantScreenState();
}

class AddPlantScreenState extends State<AddPlantScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Plant'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: PlantForm(),
      ),
    );
  }
}

class PlantForm extends StatefulWidget {
  const PlantForm({super.key});

  @override
  State<PlantForm> createState() => PlantFormState(FirebaseDatabase.instance.ref());
}

class PlantFormState extends State<PlantForm> {
  String? _searchingWithQuery;
  final _formKey = GlobalKey<FormState>();

  final DatabaseReference _database;
  
  PlantFormState(this._database);
  
  final useruid = FirebaseAuth.instance.currentUser?.uid ?? '';
  var apiService = InfoApiService();

  late Iterable<String> _lastOptions = <String>[];
  late List<String> _speciesList;
  late String _species = '';
  late String _name;

  getSpeciesList(String query) async {
    _speciesList = await apiService.getPlantList(query);
    _speciesList = _speciesList.toSet().toList();
    print('speciesList: $_speciesList');
    return _speciesList;
  }

  void _addPlant() async {
    int newPlantId;
    final snapshot = await _database.child('plants').get();
    print(snapshot);
    if (snapshot.exists && snapshot.value != null) {
      if (snapshot.value is Map) {
        newPlantId = (snapshot.value as Map).length;
      } else if (snapshot.value is List) {
        newPlantId = (snapshot.value as List).length;
      } else {
        newPlantId = 0;
      }
    } else {
      newPlantId = 0;
    }
    _database.child('plants').child(newPlantId.toString()).set({
      'plant_id': newPlantId,
      'plant_name': _name,
      'plant_species': _species,
      'user_uid': useruid,
      'moisture_value': 0,
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  _searchingWithQuery = textEditingValue.text;
                  final Iterable<String> options =
                      await getSpeciesList(_searchingWithQuery!);
                  print('options: $options');
                  if (_searchingWithQuery != textEditingValue.text) {
                    return _lastOptions;
                  }

                  _lastOptions = options;
                  return options;
                },
                onSelected: (String selection) {
                  debugPrint('You just selected $selection');
                  _species = selection;
                },
                fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Species',
                  ),
                  validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please choose a species from the dropdown';
                  }
                  return null;
                },
                );
  },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter the plant name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                child: const Text('Add Plant'),
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _species.isNotEmpty) {
                    _formKey.currentState!.save();
                    _addPlant();
                  }
                  else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please pick a species from the dropdown.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ));
  }
}
