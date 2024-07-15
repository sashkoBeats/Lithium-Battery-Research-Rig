#include <OneWire.h>
#include <DallasTemperature.h>

// This program reads the unique device IDs of all temperature sensors attached to the board
// and continously prints them with their corresponding temperature reading on the Serial Monitor.
// The program is needed to identify and map which temp sensor corresponds to which battery cell.
// The program was made by ChatGPT 4 and surprisingly, it works with no edits.

// Pin where the DS18B20 is connected
#define ONE_WIRE_BUS 6

OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

// Maximum number of devices we expect to find
#define MAX_DEVICES 64

DeviceAddress deviceAddress[MAX_DEVICES];
int numberOfDevices = 0;

void setup() {
  // Start the Serial Monitor
  Serial.begin(9600);
  Serial.println("DS18B20 Unique Device ID and Temperature Reader");

  // Start up the library
  sensors.begin();

  // Look for devices on the bus and count them
  while (oneWire.search(deviceAddress[numberOfDevices])) {
    if (OneWire::crc8(deviceAddress[numberOfDevices], 7) != deviceAddress[numberOfDevices][7]) {
      Serial.println("CRC is not valid!");
      return;
    }
    numberOfDevices++;
    if (numberOfDevices >= MAX_DEVICES) break;
  }

  // Reset the search
  oneWire.reset_search();

  if (numberOfDevices == 0) {
    Serial.println("No DS18B20 devices found");
  } else {
    Serial.print("Found ");
    Serial.print(numberOfDevices);
    Serial.println(" device(s).");
    for (int i = 0; i < numberOfDevices; i++) {
      Serial.print("Device ");
      Serial.print(i + 1);
      Serial.print(" address: ");
      printAddress(deviceAddress[i]);
      Serial.println();
    }
  }
}

void loop() {
  // Request temperature readings
  sensors.requestTemperatures();

  // Print the temperature of each device
  for (int i = 0; i < numberOfDevices; i++) {
    float temperatureC = sensors.getTempC(deviceAddress[i]);
    Serial.print("Device ID ");
    printAddress(deviceAddress[i]);
    Serial.print(": ");
    Serial.print(temperatureC);
    Serial.println(" °C");
  }

  // Wait a bit before taking the next reading
  delay(1000);
}

void printAddress(byte addr[]) {
  for (byte i = 0; i < 8; i++) {
    if (addr[i] < 16) Serial.print("0");
    Serial.print(addr[i], HEX);
  }
}
