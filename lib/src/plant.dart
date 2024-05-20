class Plant {
  int plantId;
  int moistureValue;
  String plantName;
  String plantSpecies;
  String userUid;

  Plant({
    required this.plantId,
    required this.moistureValue,
    required this.plantName,
    required this.userUid,
    required this.plantSpecies,
  });
}
  // Object? toJson(
  //     {bool includePlantSpecies = false, bool includeUserUid = false}) {
  //   Map<String, dynamic> json = {
  //     'plant_id': plantId,
  //     'moisture_value': moistureValue,
  //     'plant_name': plantName,
  //   };
  //   if (includePlantSpecies) {
  //     json['plant_species'] = plantSpecies;
  //   }
  //   if (includeUserUid) {
  //     json['user_uid'] = userUid;
  //   }
  //   return json;
  // }
//}