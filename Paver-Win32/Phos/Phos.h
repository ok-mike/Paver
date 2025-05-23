// Phos/Win32 header file
// This file is part of the Aerosol project.
// The entire project including this file has been released to the public domain
// by its author, Michael Mangelsdorf <mim@ok-schalter.de>.
// It comes with no warranty whatsoever, use at your own risk.
// For more information see https://ok-schalter.de/aerosol.

#pragma once

#include "resource.h"
#include <glad\glad.h>
#include <inttypes.h>
#include <math.h>
#include "Windowsx.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define MATH_3D_IMPLEMENTATION
#include "math_3d.h"

// Converts degrees to radians.
#define degreesToRadians(angleDegrees) (angleDegrees * M_PI / 180.0)

// Converts radians to degrees.
#define radiansToDegrees(angleRadians) (angleRadians * 180.0 / M_PI)


GLfloat rdist(GLfloat x, GLfloat y) {
	return sqrt((32.0 - x) * (32.0 - x) + (16.0 - y) * (16.0 - y));
	// range 0 - 35.77
}

struct {
	unsigned char *nx, *ny, *nz, *px, *py, *pz;
} skybox;

extern void run(void);

struct { // State variables for Paverho emulator  WHY IS THIS DUPLICATED HERE INSTEAD OF ONLY IN sonne16.h ??

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

struct { // These are state variables for the scene

	GLfloat xlight, ylight, zlight;
	GLfloat xrot, yrot, zrot;
	GLfloat skybox_yRot;
} scene;

struct { // These are state variables for the screen mesh

	GLfloat xrot, yrot, zrot;
	GLfloat xtransl, ytransl, ztransl;
	GLfloat scale;

	GLfloat* data;

} screen;

struct { // These are OpenGL handles for the screen mesh

		 // Buffers

	GLuint buf_vao;
	GLuint buf_vboChars;
	GLuint buf_vboColors;

	// Shader program

	GLuint prog_shader;

	// Attributes

	GLuint attr_vertexOffs;
	GLuint attr_uvChar;
	GLuint attr_charColor;
	GLuint attr_charData;

	// Uniforms

	GLfloat uni_skyboxYRot;

	GLuint uni_cursorX;
	GLuint uni_cursorY;
	GLuint uni_cursorVis;
	GLuint uni_bgCol;

	GLuint uni_viewMatrix;
	GLuint uni_modelViewMatrix;
	GLuint uni_modelViewProjectionMatrix;

	GLuint uni_diffuseMapSampler;
	GLuint uni_specularMapSampler;
	GLuint uni_normalMapSampler;
	GLuint uni_cubemapSampler;
	GLuint uni_arrayTextureSampler;

	GLuint uni_lightDiffuse;
	GLuint uni_lightSpecular;
	GLuint uni_materialDiffuse;
	GLuint uni_materialSpecular;
	GLuint uni_materialGloss;

	GLuint uni_lightPosition;
	GLuint uni_lightConstantTerm;
	GLuint uni_lightLinearTerm;
	GLuint uni_lightQuadraticTerm;

	// Textures

	GLuint tex_specular;
	GLuint tex_normal;
	GLuint tex_cube;
	GLuint tex_arrayTexture;
	GLuint tex_GFX;

} glid_screen;


struct { // These are OpenGL handles for the skybox

	GLuint buf_vao;

	GLuint prog_shader;

	GLuint attr_pos;

	GLuint uni_skyboxMatrix;
	GLuint uni_cubemapSampler;
	GLfloat uni_hRot;

	GLuint tex_cube;

} glid_skybox;


void frustum(float *m, int offset,
	float left, float right, float bottom, float top,
	float nearz, float farz) {

	float r_width = 1.0f / (right - left);
	float r_height = 1.0f / (top - bottom);
	float r_depth = 1.0f / (farz - nearz);
	float x = 2.0f * (r_width);
	float y = 2.0f * (r_height);
	float z = 2.0f * (r_depth);
	float A = (right + left) * r_width;
	float B = (top + bottom) * r_height;
	float C = (farz + nearz) * r_depth;
	m[offset + 0] = x;
	m[offset + 3] = -A;
	m[offset + 5] = y;
	m[offset + 7] = -B;
	m[offset + 10] = -z;
	m[offset + 11] = -C;
	m[offset + 1] = 0.0f;
	m[offset + 2] = 0.0f;
	m[offset + 4] = 0.0f;
	m[offset + 6] = 0.0f;
	m[offset + 8] = 0.0f;
	m[offset + 9] = 0.0f;
	m[offset + 12] = 0.0f;
	m[offset + 13] = 0.0f;
	m[offset + 14] = 0.0f;
	m[offset + 15] = 1.0f;

}



