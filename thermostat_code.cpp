#include "DHT.h"
#include <ArduinoJson.h>
#include <WiFi.h>
#include <HTTPClient.h>

#define DHTPIN 14
#define DHTTYPE DHT11

DHT dht(DHTPIN, DHTTYPE);
String device_id;
int counter = 0;
const int ledPinRed = 26;
const int ledPinGreen = 25;
const int ledPinBlue = 27;
const int toggleButtonPin = 12;
const int renameButtonPin = 13;
bool deviceOn = false;
bool renaming = true;
int togglenState = 0;
int renameState = 0;
StaticJsonDocument<200> doc;
JsonObject object = doc.to<JsonObject>();

void setup() {
  pinMode(ledPinRed, OUTPUT);
  pinMode(ledPinGreen, OUTPUT);
  pinMode(ledPinBlue, OUTPUT);
  pinMode(toggleButtonPin, INPUT);
  pinMode(renameButtonPin, INPUT);
  digitalWrite(ledPinBlue, HIGH);
  Serial.begin(9600);
  delay(5000);
  rename();
  dht.begin();
}

void loop() {
  delay(500);
  toggleState = digitalRead(toggleButtonPin);
  renameState = digitalRead(renameButtonPin) && !deviceOn;
  if (toggleState == HIGH) {
    deviceOn = !deviceOn;
  }
  if (renameState == HIGH) {
    renaming = !renaming;
  }
  if (deviceOn) {
    digitalWrite(ledPinRed, LOW);
    digitalWrite(ledPinGreen, HIGH);
  } else {
    digitalWrite(ledPinRed, HIGH);
    digitalWrite(ledPinGreen, LOW);
  }
  if (renaming) {
    digitalWrite(ledPinBlue, HIGH);
    rename();
  } else {
    digitalWrite(ledPinBlue, LOW);
  }
  if (counter % 4 == 0 && deviceOn) {
    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();
    if (isnan(humidity) || isnan(temperature)) {
      Serial.println("Failed to read from DHT sensor");
      return;
    }
    doc["device_id"] = device_id;
    doc["humidity"] = humidity;
    doc["temperature"] = temperature;
    String jsonString;
    serializeJson(doc, jsonString);
    jsonString.replace("\\n", "");
    Serial.println(jsonString);
  }
  // Increment counter
  counter++;
}

int rename() {
  Serial.println("Enter device ID: ");
  while (Serial.available() == 0) {}
  device_id = Serial.readString();
  renaming = false;
  return 0;
}