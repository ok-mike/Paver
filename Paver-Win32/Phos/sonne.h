// Sonne emulator header file
// This file is part of the Aerosol project.
// The entire project including this file has been released to the public domain
// by its author, Michael Mangelsdorf <mim@ok-schalter.de>.
// It comes with no warranty whatsoever, use at your own risk.
// For more information see https://ok-schalter.de/aerosol.

#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
// #include <unistd.h>
#include <math.h>
#include <winsock2.h>
#include <glad\glad.h>

extern struct { // State variables for Paverho emulator

	uint16_t scanCodeReady;
	uint16_t keyCode;
	uint16_t idle;
	uint16_t cursorVis;
	uint16_t cursorX, cursorY;
	uint16_t bgCol;
	
	uint32_t txtBase;
	uint32_t gfxBase;
	
	uint16_t gfxH;
	uint16_t gfxV;
	uint16_t quit;

	GLuint screenData[128 * 32 * 2];
	struct { GLfloat r, g, b; } screenColor[128 * 32 * 2];

	unsigned char* gfxRawData;
	unsigned char* bgpicRawData;
	char* pavMacPath;
	uint16_t clipText[32*80];
	uint16_t clipReady;
	HANDLE threadHandle;
	int threadData;

} paver;