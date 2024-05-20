import 'dart:io';

import 'package:flutter_app/src/device_setup_screen.dart';
import 'package:flutter_app/src/disease_api_service.dart';
import 'package:flutter_app/src/gpt_service.dart';
import 'package:flutter_app/src/plant_card.dart';
import 'package:flutter_app/src/plant.dart';
import 'package:flutter_app/src/add_plant_screen.dart';
import 'package:flutter_app/src/plant_info_api_service.dart';
import 'package:flutter_app/src/disease_camera.dart';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:mockito/annotations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'unit_test.mocks.dart';

class FileWrapper extends Mock implements File {}

class DiseaseApi extends Mock implements DiseaseApiService {}

class GPT extends Mock implements GPTService {}

class InfoApi extends Mock implements InfoApiService {}

class FirebaseWrapper {
  Future<FirebaseApp> initializeApp() => Firebase.initializeApp();
}

class FirebaseW extends Mock implements FirebaseWrapper {}

class FirebaseA extends Mock implements FirebaseApp {}

class FirebaseD extends Mock implements FirebaseDatabase {}

class FirebaseAu extends Mock implements FirebaseAuth {}

@GenerateMocks(
    [DiseaseApi, GPT, InfoApi, FileWrapper, FirebaseA, FirebaseD, FirebaseAu, FirebaseW])
void main() async {
  late MockFirebaseA mockFirebaseApp;
  late MockFirebaseD mockFirebaseDatabase;
  late MockFirebaseAu mockFirebaseAuth;

  flutter_test.TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    MockFirebaseW mockFirebaseWrapper = MockFirebaseW();
    when(mockFirebaseWrapper.initializeApp()).thenAnswer((_) => Future.value(MockFirebaseA()));
});

  group('PlantCard Tests', () {
    final plant = Plant(
      plantId: 1,
      moistureValue: 0,
      plantName: 'Test Plant',
      userUid: 'Test User',
      plantSpecies: 'Test Species',
    );
    test('PlantCard should be created', () {
      final plantCard = PlantCard(plant);
      expect(plantCard, isNotNull);
    });
    test(
        'getMoistureMessage should return correct message for different moisture percentages',
        () {
      final plantCard = PlantCardState();

      // Test for moisturePercentage = 0
      expect(plantCard.getMoistureMessage(0), 'Very Dry');

      // Test for moisturePercentage = 50%
      expect(plantCard.getMoistureMessage(0.5), 'Moderately Dry');

      // Test for moisturePercentage = 100%
      expect(plantCard.getMoistureMessage(1), 'Fully Hydrated');

      // Test for moisturePercentage = -5%
      expect(plantCard.getMoistureMessage(-0.05), 'Very Dry');

      // Test for moisturePercentage = 105%
      expect(plantCard.getMoistureMessage(1.05), 'Fully Hydrated');
    });
  });
  group('Add Plant tests', () {
    late PlantFormState addPlant;
    late MockInfoApi mockInfoApi;
    setUp(() async {
      mockFirebaseApp = MockFirebaseA();
      mockFirebaseDatabase = MockFirebaseD();
      mockFirebaseAuth = MockFirebaseAu();
      when(Firebase.app()).thenReturn(mockFirebaseApp);
      when(Firebase.initializeApp())
          .thenAnswer((_) => Future.value(mockFirebaseApp));
      when(FirebaseDatabase.instance).thenReturn(mockFirebaseDatabase);
      when(FirebaseAuth.instance).thenReturn(mockFirebaseAuth);
      mockInfoApi = MockInfoApi();
      addPlant = PlantFormState(FirebaseDatabase.instance.ref());
      addPlant.apiService = mockInfoApi;
    });
    test('getSpeciesList returns a list of species', () async {
      when(mockInfoApi.getPlantList(any))
          .thenAnswer((_) async => ['species1', 'species2', 'species3']);

      var result = await addPlant.getSpeciesList('query');

      expect(result, ['species1', 'species2', 'species3']);
      verify(mockInfoApi.getPlantList('query')).called(1);
    });
  });
  group('DisplayPictureScreenState', () {
    test('detectDisease should update detecting and precautionLoading',
        () async {
      final mockApiService = MockDiseaseApi();
      final mockGptService = MockGPT();
      var state = DisplayPictureScreenState();

      state.apiService = mockApiService;
      state.gptService = mockGptService;
      state.selectedImage = File('test-plant.jpg');
      when(mockApiService.sendImageToPlantId(image: anyNamed('image')))
          .thenAnswer((_) async => 'Test Disease');
      when(mockGptService.sendMessageGPT(diseaseName: anyNamed('diseaseName')))
          .thenAnswer((_) async => 'Test Precaution');
      await state.detectDisease();

      expect(state.detecting, isTrue);
      expect(state.precautionLoading, isTrue);
      expect(state.diseaseName, equals('Test Disease'));
    });
  });
}
