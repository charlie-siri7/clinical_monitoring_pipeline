/* Button functions: 
   next to blue LED: select new device name
   Between blue and red LEDs: turn thermostat on and off (whether or not you are reading data) 
*/

#include "DHT.h"
#include <ArduinoJson.h>
#include <WiFi.h>
#include <HTTPClient.h>

const char* ssid = "";
const char* password = "";
const char* serverURL = "";

#define DHTPIN 14 // I/O Pin connected to DHT11 sensor
#define DHTTYPE DHT11

DHT dht(DHTPIN, DHTTYPE);
String device_id;
int counter = 0;
// variables for pins
const int ledPinRed = 26;
const int ledPinGreen = 25;
const int ledPinBlue = 27;
const int toggleButtonPin = 12;
const int renameButtonPin = 13;
// variables different states
bool deviceOn = false;
bool renaming = true;
int toggleState = 0;
int renameState = 0;
// json object to store read in data
StaticJsonDocument<200> doc;

// Function prototypes
int rename();
void sendData(String payload);

void setup() {
  // Initialize LEDs
  pinMode(ledPinRed, OUTPUT);
  pinMode(ledPinGreen, OUTPUT);
  pinMode(ledPinBlue, OUTPUT);
  // Initialize buttons
  pinMode(toggleButtonPin, INPUT);
  pinMode(renameButtonPin, INPUT);
  // Set blue LED to high since you have to rename at the start
  digitalWrite(ledPinBlue, HIGH);
  Serial.begin(9600);

  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);

  int timeElapsed = 0;
  while (WiFi.status() != WL_CONNECTED && timeElapsed < 20) {
    delay(500);
    Serial.print(".");
    timeElapsed++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi successfully connected");
  } else {
    Serial.println("WiFi failed to connect");
  }

  delay(5000);
  rename();
  dht.begin();
}

void loop() {
  delay(500);
  // Recheck states for thermostat toggle and rename
  toggleState = digitalRead(toggleButtonPin);
  renameState = digitalRead(renameButtonPin) && !deviceOn;
  // Set variables based on the above states
  if (toggleState == HIGH) {
    deviceOn = !deviceOn;
  }
  if (renameState == HIGH) {
    renaming = !renaming;
  }
  // Set red/green LEDs based on if the thermostat is active
  if (deviceOn) {
    digitalWrite(ledPinRed, LOW);
    digitalWrite(ledPinGreen, HIGH);
  } else {
    digitalWrite(ledPinRed, HIGH);
    digitalWrite(ledPinGreen, LOW);
  }
  // Set blue LED based off if renaming, and call function if needed
  if (renaming) {
    digitalWrite(ledPinBlue, HIGH);
    rename();
  } else {
    digitalWrite(ledPinBlue, LOW);
  }
  // Every 2 seconds (4 * 0.5 seconds), read data if thermostat is on
  if (counter % 4 == 0 && deviceOn) {
    // Read humidity and temperature
    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();
    // If reading fails, notify user and break out of current iteration
    if (isnan(humidity) || isnan(temperature)) {
      Serial.println("Failed to read from DHT sensor");
      return;
    }
    // Set json data
    doc["device_id"] = device_id;
    doc["humidity"] = humidity;
    doc["temperature"] = temperature;
    // Make string from json data and print it
    String jsonString;
    serializeJson(doc, jsonString);
    jsonString.replace("\\n", "");
    Serial.println(jsonString);

    if (WiFi.status() == WL_CONNECTED) {
      sendData(jsonString);
    } else {
      Serial.println("WiFi not connected, can't send data");
    }
  }
  // Increment counter
  counter++;
}

int rename() {
  // Print prompt and wait for user
  Serial.println("Enter device ID: ");
  while (Serial.available() == 0) {}
  // Get string from user, set renaming variable, return
  device_id = Serial.readString();
  device_id.trim();
  renaming = false;
  return 0;
}

void sendData(String payload) {
  HTTPClient client;
  client.begin(serverURL);
  client.addHeader("Content-Type", "application/json");
  int responseCode = client.POST(payload);
  if (responseCode > 0) {
    String response = client.getString();
    Serial.print("Server response code: ");
  } else {
    Serial.print("Error sending POST: ");
  }
  Serial.println(responseCode);
  client.end();
}