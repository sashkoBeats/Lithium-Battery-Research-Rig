////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  
//  Author: Indra Erkens
//  
//  This file contains multiple functions to help communicate with the DS18B20 temp sensors to acquire temperature values. Start by
//  calling SetDeviceIDs to find all available sensors connected to the data pin that's connected to all the individual temperature
//  sensors. After this, SetDeviceResolution should be called to disable the alarm functionality and set the desired resolution
//  on all found devices. Finally, SampleTemperaturesAsync can be called to retrieve temperature data in a non-blocking way. 
//  All data returned will be the raw data received from the sensors.
//  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "TemperatureAcquisition.h"

OneWire oneWire = OneWire(TEMPERATURE_SENSORS_PIN);
DeviceID deviceIDs[0x40];
unsigned char deviceAmount = 0;
bool devicesFound[0x40] = { false };
unsigned char deviceResolution = 0;
unsigned short int temperatures[0x40];

void SetDeviceIDs(unsigned long long int* temperatureDeviceIDs, unsigned char temperatureDeviceAmount)
{
	// Convert all input IDs to byte arrays
	for (unsigned char i = 0; i < temperatureDeviceAmount; i++)
	{
		for (unsigned char j = 0; j < 8; j++)
		{
			(deviceIDs[i])[j] = (unsigned char)(temperatureDeviceIDs[i] >> (8 * (7 - j)));
		}
	}
	deviceAmount = temperatureDeviceAmount;
	DeviceID deviceID;
	// Set found devices to none
	for (unsigned char i = 0; i < temperatureDeviceAmount; i++)
	{
		devicesFound[i] = false;
	}
	// If entered, a previously unseen device has been detected
	while (oneWire.search(deviceID))
	{
		// Convert byte array to 64-bit unsigned integer
		unsigned long long int deviceIDInteger = 0;
		for (unsigned char i = 0; i < 8; i++)
		{
			deviceIDInteger <<= 8;
			deviceIDInteger |= deviceID[i];
		}
		// Check found device's ID against all input IDs
		for (unsigned char i = 0; i < deviceAmount; i++)
		{
			if (temperatureDeviceIDs[i] == deviceIDInteger)
			{
				// Register that one of the devices from the provided IDs has been found
				devicesFound[i] = true;
				break;
			}
		}
	}
}

void SetDeviceResolution(unsigned char resolution)
{
	// Make sure the resolution is a valid value
	if (resolution >= 4)
	{
		return;
	}
	// Loop through all found devices that correspond to one of the provided IDs when setting device IDs
	for (unsigned char i = 0; i < deviceAmount; i++)
	{
		if (devicesFound[i])
		{
			oneWire.reset();
			oneWire.select(deviceIDs[i]);
			// Write to scratchpad
			oneWire.write(0x4E, 1);
			// Set lowest and highest allowed temperature to the lowest and highest 8-bit signed integer respectively, to
			// disable the alarm functionality
			oneWire.write(0x80, 1);
			oneWire.write(0x7F, 1);
			// Set resolution bits
			oneWire.write(0x1F | (resolution << 5), 1);
		}
	}
	deviceResolution = resolution;
}

bool ConvertTemperaturesAsync()
{
	static unsigned short int currentTime = 0;
	static bool converting = false;
	if (!converting)
	{
		// Loop through all found devices that correspond to one of the provided IDs when setting device IDs
		for (unsigned char i = 0; i < deviceAmount; i++)
		{
			if (devicesFound[i])
			{
				oneWire.reset();
				oneWire.select(deviceIDs[i]);
				// Start conversion
				oneWire.write(0x44, 1);
			}
		}
		converting = true;
		currentTime = millis();
	}
	// Check if conversion has been taken place for at least the maximum conversion time for the currently used resolution
	if (converting && (unsigned short int)millis() - currentTime > MAXIMUM_CONVERSION_TIME << deviceResolution)
	{
		converting = false;
		// Return true only when conversion has just finished
		return true;
	}
	return false;
}

bool SampleTemperaturesAsync(unsigned short int*& result)
{
	if (ConvertTemperaturesAsync())
	{
		// Loop through all found devices that correspond to one of the provided IDs when setting device IDs
		for (unsigned char i = 0; i < deviceAmount; i++)
		{
			if (devicesFound[i])
			{
				oneWire.reset();
				oneWire.select(deviceIDs[i]);
				// Read from scratchpad
				oneWire.write(0xBE, 1);
				// Acquire temperature from the first 2 bytes of the scratchpad
				unsigned short int temperature = 0x0000;
				temperature |= oneWire.read();
				temperature |= (unsigned short int)oneWire.read() << 8;
				// Finish reading the remaining scratchpad bytes
				for (unsigned char j = 0; j < 7; j++)
				{
					oneWire.read();
				}
				temperatures[i] = temperature;
			}
			else
			{
				temperatures[i] = 0xFFFF;
			}
		}
		result = temperatures;
		// Only return true when the result has new values
		return true;
	}
	return false;
}