# PetalMinder: An IoT-Integrated Mobile App for Enhanced Home Plant Wellness

PetalMinder is a Flutter-based mobile application designed to help you take better care of your home plants. Integrated with IoT, it provides real-time data about your plants' health and offers personalized care tips.

## Arduino Setup

To use the soil moisture sensor with the Arduino board, follow these steps:

### Hardware Requirements

* Arduino Uno Wifi R4 board
* Capacitive soil moisture sensor

1. Connect the soil moisture sensor to the Arduino board on the A0 pin.
2. Connect the Arduino board to your computer using a USB cable.
3. Upload the Arduino code from the Arduino/main folder to the Arduino board.

## How to Run

1. Clone the repository to your local machine.
2. Open the project in your preferred IDE (we recommend Visual Studio Code).
3. Ensure you have Flutter and Dart SDKs installed.
4. In lib/src/ add a file named ``api_constants.dart`` and add the following code:

```dart
String OPENAI_BASE_URL = "your key";
String OPENAI_API_KEY = "your key";
String PLANTID_API_KEY = "your key";
String PERENUAL_API_KEY = "your key";
```

5. Run ``flutter pub get`` to fetch the project dependencies.
6. Connect your mobile device.
7. Run ``flutter run`` to start the application.
