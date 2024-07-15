#ifndef TEMPERATURE_ACQUISITION_INCLUDED
#define TEMPERATURE_ACQUISITION_INCLUDED

#include <OneWire.h>

// Digital pin connected to all temperature sensors
#define TEMPERATURE_SENSORS_PIN 6

// Maximum conversion time for resulution 0
#define MAXIMUM_CONVERSION_TIME (unsigned short int)100

typedef unsigned char DeviceID[8];

void SetDeviceIDs(unsigned long long int* temperatureDeviceIDs, unsigned char temperatureDeviceAmount);
void SetDeviceResolution(unsigned char resolution);
bool ConvertTemperaturesAsync();
bool SampleTemperaturesAsync(unsigned short int*& result);

#endif