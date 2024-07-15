////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  
//  Author: Aleksandar Zdravkov
//  
//  This file contains the main program for the Arduino Nano MCU found on the Battery Monitoring Board. The program initializes all
//  sesning hardware and continously retrieves new data from sensors as fast as their spec sheets allow. The serial interface is meanwhile
//  monitored for data requests from the PC application, and responds with the latest available data when a request comes in.
//  A 5s timeout is implemented that puts the MAX14921 battery monitoring IC into low power mode if no data requests have come in to save power.
//  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include <math.h>
#include "VoltageAcquisition.h"
#include "TemperatureAcquisition.h"

#define LOW_POWER_TIMEOUT 5000
#define TEMP_DEVICES_SIZE sizeof(tempSensorIDs)/sizeof(unsigned long long int)
#define CURRENT_SENSE_PIN A0

// Enum for the different requests/commands from PC
enum SerialRequestType : unsigned char{
  IDLE, ELECTRICAL, TEMP, CONFIG
};

// List of DS18B20 temp sensor IDs, matched to their correct cell position
unsigned long long int tempSensorIDs[] = 
{
  0x281E43CC0D0000CA, // Cell 1, BT1
  0x289228CD0D0000B3, // Cell 2, BT1
  0x285845CC0D000091, // Cell 3, BT1
  0x287AD7CC0D00007D, // Cell 4, BT1
  0x2805BCCE0D0000A7, // Cell 5, BT1
  0x28DA8CCE0D0000C3, // Cell 6, BT1
  0x283145CC0D0000C4, // Cell 7, BT1
  0x28713DCC0D0000E2, // Cell 8, BT1
  0x28EC08CD0D0000C0, // Cell 1, BT2
  0x28EA6DCC0D00003E, // Cell 2, BT2
  0x284EE8CD0D000028, // Cell 3, BT2
  0x288F3ECE0D0000CA, // Cell 4, BT2
  0x28C090CE0D00000A, // Cell 5, BT2
  0x280FAACE0D000088, // Cell 6, BT2
  0x28C2B6CE0D000000, // Cell 7, BT2
  0x2831BDCD0D0000D3  // Cell 8, BT2
};

unsigned short int electricalData[18] = {0};
unsigned short int tempData[32] = {0};
unsigned short int* batmonData = 0;
unsigned char cellsToSample = 0;
bool sampleRunning = true;
long long int lastComs = 0;
unsigned char* bytesDataE;
unsigned char* bytesDataT;

void setup() {
  digitalWrite(MAX14921_EN, HIGH);
  SetSPISpeed(2000000);
  EnableSPI();
  SetLowPowerMode(false);
  Serial.begin(115200);
  SetDeviceIDs(tempSensorIDs, TEMP_DEVICES_SIZE);
  SetDeviceResolution(2); // 11-bit resolution
  bytesDataE = (unsigned char*)(&electricalData);
  bytesDataT = (unsigned char*)(&tempData);
}

void loop() {
  // MAX14921 Battery Monitoring IC control
  if (sampleRunning){
    if (SampleVoltagesAsync(batmonData, cellsToSample)){
      electricalData[cellsToSample] = batmonData[0];
      memcpy(electricalData, batmonData + 1, cellsToSample * sizeof(unsigned short int));
    }
  }

   /*
   // Print SPI feedback from MAX14921
   for (int i = 0; i < 24; i++){
    Serial.print(GetMonitoringBits()[i]);
   }
   Serial.println();
   */

  // Current sensor measurement
  electricalData[cellsToSample + 1] = analogRead(CURRENT_SENSE_PIN);
  //Serial.println(electricalData[cellsToSample + 1]);

  // Temp sensor measurements
  if (sampleRunning){
    if (SampleTemperaturesAsync(batmonData)){
      memcpy(tempData, batmonData, TEMP_DEVICES_SIZE * sizeof(unsigned short int));
    }
  }
   
  // Serial interface process
  if (Serial.available() > 0){
    // Read incoming request code
    unsigned char serialDataRx = Serial.read();
    // Flush incoming Serial buffer
    while(Serial.available() > 0) {
      char t = Serial.read();
    }
    // Decode request code
    SerialRequestType rx = 0x0F & serialDataRx;
    // Reset timeout counter
    lastComs = millis();
    // Choose response and/or execute task
    switch (rx){
      case IDLE:
        // Put MAX14921 into low power mode and stop sampling loop
        sampleRunning = false;
        SetLowPowerMode(true);
        break;
      case ELECTRICAL:
        // Check if sampling loop is running and (re)start it if is not
        if (!sampleRunning){
          sampleRunning = true;
          SetLowPowerMode(false);
        }
        // Send latest available electrical data to PC
        Serial.write(bytesDataE, sizeof(unsigned short int) * (cellsToSample + 2));
        Serial.write("\r");
        break;
      case TEMP:
        // Check if sampling loop is running and (re)start it if is not
        if (!sampleRunning){
          sampleRunning = true;
          SetLowPowerMode(false);
        }
        // Send latest available temperature data to PC
        Serial.write(bytesDataT, sizeof(unsigned short int) * (cellsToSample * 2));
        Serial.write("\r");
        break;
      case CONFIG:
        // Configure the cell count to the number received from PC
        cellsToSample = (serialDataRx >> 4) + 1;
        // And put system in run mode
        sampleRunning = true;
        SetLowPowerMode(false);
        break;
      default:
        break;
    }
  }
  
  // Inactivity watchdog
  // If no data requests have come in from PC within the specified time (default = 5s)
  // Put MAX14921 to sleep and stop all sensor sampling
  if (millis() - lastComs > LOW_POWER_TIMEOUT){
    if (sampleRunning){
      SetLowPowerMode(true);
    }
    sampleRunning = false;
  }
  
}