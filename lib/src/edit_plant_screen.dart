import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'plant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'plant_info_api_service.dart';

class EditPlantScreen extends StatefulWidget {
  final Plant plant;

  const EditPlantScreen(this.plant, {super.key});

  @override
  State<EditPlantScreen> createState() => EditPlantScreenState();
}

class EditPlantScreenState extends State<EditPlantScreen> {
  String? _searchingWithQuery;
  final _formKey = GlobalKey<FormState>();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final useruid = FirebaseAuth.instance.currentUser?.uid ?? '';

  late Iterable<String> _lastOptions = <String>[];
  late List<String> _speciesList;
  late String _species = widget.plant.plantSpecies;
  late String _name = widget.plant.plantName;

  getSpeciesList(String query) async {
    final apiService = InfoApiService();
    _speciesList = await apiService.getPlantList(query);
    _speciesList = _speciesList.toSet().toList();
    print('speciesList: $_speciesList');
    return _speciesList;
  }

  void _editPlant() async {
    final plantId = widget.plant.plantId;
    _database.child('plants').child(plantId.toString()).update({
      'plant_name': _name,
      'plant_species': _species,
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final speciesController = TextEditingController(text: widget.plant.plantSpecies);
    final nameController = TextEditingController(text: widget.plant.plantName);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Plant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
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
                  controller: speciesController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: "Species",
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
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
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
                child: const Text('Save'),
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _species.isNotEmpty) {
                    _formKey.currentState!.save();
                    _editPlant();
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
        )));
  }
}
