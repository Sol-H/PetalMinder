#include <ArduinoBLE.h>

#include "WiFiS3.h"
#include "WiFiSSLClient.h"
#include "IPAddress.h"

BLEService wifiService("12345678-1234-1234-1234-123456789abc");                                              // create GATT service
BLEStringCharacteristic ssidCharacteristic("12345678-1234-1234-1234-123456789abd", BLERead | BLEWrite, 20);  // create GATT characteristics
BLEStringCharacteristic passwordCharacteristic("12345678-1234-1234-1234-123456789abe", BLERead | BLEWrite, 20);
BLEStringCharacteristic userCharacteristic1("12345678-1234-1234-1234-123456789abf", BLERead | BLEWrite, 20);
BLEStringCharacteristic userCharacteristic2("12345678-1234-1234-1234-123456789ac1", BLERead | BLEWrite, 20);
BLEStringCharacteristic connectedCharacteristic("12345678-1234-1234-1234-123456789ac0", BLERead | BLEWrite, 20);
BLEStringCharacteristic plantIdCharacteristic("12345678-1234-1234-1234-123456789ac2", BLERead | BLEWrite, 20);

int sensorPin = A0;     // the input pin for the moisture sensor
int moistureLevel = 0;  // variable to store the value coming from the sensor

int oldMoistureLevel = 0;  // last moisture level reading from analog input
long previousMillis = 0;   // last time the moisture level was checked, in ms

bool wasConnected = false;
bool wasDisconnected = false;  // manages bluetooth connections in loop - for debugging

char serverAddress[] = SECRET_SERVER_ADDRESS;

WiFiSSLClient client;

String useruid = "";
String plantId = "1";

void setup() {
  Serial.begin(115200);

  if (!BLE.begin()) {
    Serial.println("starting BLE failed!");
    while (1)
      ;
  }

  BLE.setLocalName("MoistureMonitor");                // Set name for connection
  BLE.setAdvertisedService(wifiService);              // Advertise service
  wifiService.addCharacteristic(ssidCharacteristic);  // Add characteristics to service
  wifiService.addCharacteristic(passwordCharacteristic);
  wifiService.addCharacteristic(userCharacteristic1);
  wifiService.addCharacteristic(userCharacteristic2);
  wifiService.addCharacteristic(connectedCharacteristic);
  wifiService.addCharacteristic(plantIdCharacteristic);
  BLE.addService(wifiService);            // Add service
  ssidCharacteristic.writeValue("ssid");  // Set initial value for characteristics
  passwordCharacteristic.writeValue("password");
  userCharacteristic1.writeValue("userp1");
  userCharacteristic2.writeValue("userp2");
  connectedCharacteristic.writeValue("disconnected");
  plantIdCharacteristic.writeValue("1");

  BLE.advertise();  // Start advertising
  Serial.println("Bluetooth device active, waiting for connections...");
}

void loop() {
  BLEDevice central = BLE.central();

  if (central) {
    handleConnection(central);
    while (central.connected() && WiFi.status() != WL_CONNECTED) {
      connectToWifiIfCredentialsWritten();
    }
  } else {
    handleDisconnection(central);
  }

  checkMoistureLevel();
  if (WiFi.status() == WL_CONNECTED) {
    sendData(moistureLevel);
  }
}

void handleConnection(BLEDevice central) {
  if (!wasConnected) {
    Serial.print("Connected to central: ");
    Serial.println(central.address());
    wasConnected = true;
    wasDisconnected = false;
  }
}

void handleDisconnection(BLEDevice central) {
  if (!wasDisconnected) {
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
    wasDisconnected = true;
    wasConnected = false;
  }
}

void connectToWifiIfCredentialsWritten() {
  String ssid = ssidCharacteristic.value();
  Serial.println(ssidCharacteristic.value());
  String password = passwordCharacteristic.value();
  useruid = userCharacteristic1.value() + userCharacteristic2.value();  // Concatenate the chunks
  plantId = plantIdCharacteristic.value();
  if (ssidCharacteristic.written() && passwordCharacteristic.written()) {
    Serial.println("SSID and password characteristics have been written to.");
    if (ssid != "" && password != "" && useruid != "") {
      Serial.println("Plant ID:" + plantId);
      connectToWifi(ssid, password);
    }
  }
}

void checkMoistureLevel() {
  moistureLevel = analogRead(sensorPin);
  long currentMillis = millis();
  if (currentMillis - previousMillis >= 3000) {
    previousMillis = currentMillis;
    moistureLevel = analogRead(sensorPin);
    Serial.print("Moisture Level: ");
    Serial.println(moistureLevel);
  }
}

void connectToWifi(String ssid, String password) {
  BLEDevice central = BLE.central();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  Serial.println(password);

  WiFi.begin(ssid.c_str(), password.c_str());

  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print("WiFi status: ");
    Serial.println(WiFi.status());
    connectedCharacteristic.writeValue("disconnected");
    WiFi.begin(ssid.c_str(), password.c_str());
  }

  Serial.println("Connected to WiFi");
  connectedCharacteristic.writeValue("connected");
  delay(500);
  Serial.print("User ID: ");
  Serial.println(useruid);
}

void sendData(int moistureLevel) {
  String contentType = "application/json";

  BLEDevice central = BLE.central();
  if (central.connected()) {
    Serial.println("Bluetooth is connected");
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi is connected");
  }

  Serial.println("Sending moisture data");
  putMoistureData(String(moistureLevel));
  Serial.println("Sending user data");
  putUserData(useruid);
}

void putMoistureData(String body) {
  if (WiFi.status() == WL_CONNECTED) {  //Check WiFi connection status
    if (client.connect(serverAddress, 443)) {
      //client.println("PUT /plants/" + sensorNumber + location + " HTTP/1.1");
      client.print("PUT /plants/");
      client.print(plantId);
      client.println("/moisture_value.json HTTP/1.1");
      client.print("Host: ");
        client.println(serverAddress);
        client.println("Content-type: application/json");
        client.println("Accept: */*");
        client.println("Cache-Control: no-cache");
        client.print("Host: ");
        client.println(serverAddress);
        client.print("Content-Length: ");
        client.println(String(body.length()));
        client.println("Connection: close");
        client.println();
        client.println(body);

      uint32_t received_data_num = 0;
      while (client.available()) {
        /* actual data reception */
        char c = client.read();
        /* print data to serial port */
        Serial.print(c);
        /* wrap data to 80 columns*/
        received_data_num++;
        if (received_data_num % 100 == 0) {
          Serial.println();
        }
      }
      client.stop();
      delay(30000);
    } else {
      Serial.println("Error connecting to server");
      client.stop();
    }
  }
}

void putUserData(String body) {
  body = "\"" + body + "\"";
  if (WiFi.status() == WL_CONNECTED) {  //Check WiFi connection status
    if (client.connect(serverAddress, 443)) {
      //client.println("PUT /plants/" + sensorNumber + location + " HTTP/1.1");
      client.print("PUT /plants/");
      client.print(plantId);
      client.println("/user_uid.json HTTP/1.1");
      client.print("Host: ");
        client.println(serverAddress);
        client.println("Content-type: application/json");
        client.println("Accept: */*");
        client.println("Cache-Control: no-cache");
        client.print("Host: ");
        client.println(serverAddress);
        client.print("Content-Length: ");
        client.println(String(body.length()));
        client.println("Connection: close");
        client.println();
        client.println(body);

      uint32_t received_data_num = 0;
      while (client.available()) {
        /* actual data reception */
        char c = client.read();
        /* print data to serial port */
        Serial.print(c);
        /* wrap data to 80 columns*/
        received_data_num++;
        if (received_data_num % 100 == 0) {
          Serial.println();
        }
      }
      client.stop();
      delay(30000);
    } else {
      Serial.println("Error connecting to server");
      client.stop();
    }
  }
}
