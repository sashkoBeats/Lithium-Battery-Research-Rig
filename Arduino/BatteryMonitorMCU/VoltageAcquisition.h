#ifndef VOLTAGE_ACQUISITION_INCLUDED
#define VOLTAGE_ACQUISITION_INCLUDED

#include <SPI.h>

// For Nano
#define SCLK 13 // SCLK pin
#define MISO 12 // MISO pin
#define MOSI 11 // MOSI pin

#define    MAX14921_CS 10 // MAX14921 Chip-select pin
#define    MAX14921_EN  9 // MAX14921 Enable      pin 
#define MAX14921_SAMPL  8 // MAX14921 Sample      pin
#define MAX11161_CNVST  7 // MAX11161 Conversion  pin
#define    MAX11161_CS  5 // MAX11161 Chip-select pin

#define             ECS 0x00010000
#define    SAMPLE_BIT_N 0x00200000
#define  LOW_POWER_MODE 0x00800000
#define AVERAGE_VOLTAGE 0x00180000

void SetSPISpeed(unsigned long int frequency);
void EnableSPI();
void DisableSPI();
void SetLowPowerMode(bool lowPowerModeOn);
unsigned long int TransactMAX14921(unsigned long int input);
unsigned short int TransactMAX11163();
unsigned short int SampleVoltage(unsigned char cell);
bool* GetMonitoringBits();
void Sample();
unsigned short int* SampleVoltages(unsigned char cellAmount);
bool SampleAsync();
bool SampleVoltagesAsync(unsigned short int*& result, unsigned char cellAmount);

#endif