////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  
//  Author: Indra Erkens
//  
//  This file contains multiple functions to help communicate with the MAX14921 and MAX11161 ICs to acquire voltage values. Start
//  with calling enableSPI, setSPISpeed, and SetLowPowerMode to initialize the necessary variables/pins; This allows
//  SampleVoltages or SampleVoltagesAsync to be called to retrieve voltage data. SampleVoltagesAsync is preferred in most cases,
//  since other code can be executed during the 50 millisecond sampling wait time. All data returned will be the raw data
//  received from the chips.
//  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "VoltageAcquisition.h"

unsigned long int SPIFrequency = 1000000;
bool SPIEnabled = false;
bool lowPowerMode = false;
bool monitoringBits[24];
unsigned short int voltages[17];

void SetSPISpeed(unsigned long int frequency)
{
    SPIFrequency = frequency;
}

void EnableSPI()
{
	SPI.begin();
	SPIEnabled = true;
}

void DisableSPI()
{
	SPI.end();
	SPIEnabled = false;
}

void SetLowPowerMode(bool lowPowerModeOn)
{
	// Make sure SPI is enabled
	if (!SPIEnabled)
	{
		return;
    }
	// Make sure the MAX14921 is disabled during low power mode
    digitalWrite(MAX14921_EN, !lowPowerModeOn);
	lowPowerMode = lowPowerModeOn;
	TransactMAX14921(AVERAGE_VOLTAGE | (lowPowerMode ? LOW_POWER_MODE : 0));
}

unsigned long int TransactMAX14921(unsigned long int input)
{
	// Make sure SPI is enabled
    if (!SPIEnabled)
    {
        return 0;
    }
    unsigned long int data = input;
    SPI.beginTransaction(SPISettings(SPIFrequency, LSBFIRST, SPI_MODE0));
    digitalWrite(MAX14921_CS, LOW);
	// Bytes are already in the right order in memory, because of the combination of arduino being little endian and the
	// MAX14921 SPI working with LSBFIRST
    SPI.transfer((unsigned char*)&data, 3);
    digitalWrite(MAX14921_CS, HIGH);
    SPI.endTransaction();
    return data;
}

unsigned short int TransactMAX11161()
{
	// Make sure SPI is enabled
	if (!SPIEnabled)
	{
		return 0;
	}
	unsigned short int data = 0x0000;
	SPI.beginTransaction(SPISettings(SPIFrequency, MSBFIRST, SPI_MODE1));
	digitalWrite(MAX11161_CS, LOW);
	SPI.transfer16(data);
	digitalWrite(MAX11161_CS, HIGH);
	SPI.endTransaction();
	return data;
}

unsigned short int SampleVoltage(unsigned char cell)
{
	// Make sure SPI is enabled and the cell number is within the specified range
	if (!SPIEnabled || cell > 16)
	{
		return 0;
	}
	// Create variable for storing the bits which will be sent via SPI (the bit positions are the same as the bit positions of
	// the SPI control bits in the datasheet)
	unsigned long int MAX14921Parameters;
	// When the cell number is 0, get the average voltage
	if (cell > 0)
	{
		// Enable cell selection (ECS) and put cell number (minus 1) into the cell selection bits (SC)
		MAX14921Parameters = ECS | ((unsigned long int)(cell - 1) << 17);
	}
	else
	{
		// Set the bits for getting the average voltage
		MAX14921Parameters = AVERAGE_VOLTAGE;
	}
	// Assert the low power mode bit if low power mode is enabled
	MAX14921Parameters |= (lowPowerMode ? LOW_POWER_MODE : 0);
	// Execute the SPI transaction with the MAX14921
	unsigned long int monitoringResponse = TransactMAX14921(MAX14921Parameters);
	// Start ADC conversion
	//digitalWrite(MAX11161_CNVST, HIGH);
	// Give the MAX11163 time to finish conversion
	//delay(1);
	// Execute the SPI transaction with the MAX11163
	//unsigned short int result = TransactMAX11161();
  unsigned short int result = analogRead(A7); // temp workaround for non-working ADC
	// Deassert CNVST after finishing SPI transaction
	//digitalWrite(MAX11161_CNVST, LOW);
	// Store the individual bits returned from the MAX14921 SPI transaction into an array for easy access
	for (unsigned char i = 0; i < 24; i++)
	{
		monitoringBits[i] = (monitoringResponse >> i) & 0x00000001;
	}
	return result;
}

bool* GetMonitoringBits()
{
	return monitoringBits;
}

void Sample()
{
	digitalWrite(MAX14921_SAMPL, HIGH);
	delay(50);
	digitalWrite(MAX14921_SAMPL, LOW);
}

unsigned short int* SampleVoltages(unsigned char cellAmount)
{
	Sample();
	for (unsigned char i = 0; i <= cellAmount && i <= 16; i++)
	{
		voltages[i] = SampleVoltage(i);
	}
	return voltages;
}

bool SampleAsync()
{
	static unsigned short int currentTime = 0;
	static bool sampling = false;
	if (!sampling)
	{
		// Start sampling
		digitalWrite(MAX14921_SAMPL, HIGH);
		sampling = true;
		currentTime = millis();
	}
	// Check if sampling has been taken place for at least 50 milliseconds
	if (sampling && (unsigned short int)millis() - currentTime > 50)
	{
		// Stop sampling
		digitalWrite(MAX14921_SAMPL, LOW);
		sampling = false;
		// Return true only when sampling has just finished
		return true;
	}
	return false;
}

bool SampleVoltagesAsync(unsigned short int*& result, unsigned char cellAmount)
{
	if (SampleAsync())
	{
		for (unsigned int i = 0; i <= cellAmount && i <= 16; i++)
		{
			voltages[i] = SampleVoltage(i);
		}
		result = voltages;
		// Only return true when the result has new values
		return true;
	}
	return false;
}