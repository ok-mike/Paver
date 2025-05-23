// Phos/Win32
// This file is part of the Aerosol project.
// The entire project including this file has been released to the public domain
// by its author, Michael Mangelsdorf <mim@ok-schalter.de>.
// It comes with no warranty whatsoever, use at your own risk.
// For more information see https://ok-schalter.de/aerosol.


#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS
#endif


#include "stdafx.h"
#include "Phos.h"

#pragma comment (lib, "opengl32.lib")

#define MAX_LOADSTRING 100

// Global Variables:
HINSTANCE hInst;                                // current instance
WCHAR szTitle[MAX_LOADSTRING];                  // The title bar text
WCHAR szWindowClass[MAX_LOADSTRING];            // the main window class name

HDC ourWindowHandleToDeviceContext;
HGLRC ourOpenGLRenderingContext;

WCHAR wdir[1024]; // Working directory, MAX_PATH is too short
WCHAR path[1024];


mat4_t screenModelMatrix;
mat4_t viewMatrix;
mat4_t projectionMatrix;
mat4_t screenModelViewMatrix;
mat4_t screenModelViewProjectionMatrix;

vec3_t glBGColor;
float viewAspect;
int clientw, clienth;
WINDOWPOS *wp;
RECT rect;
int pause_paint=0;

// Forward declarations of functions included in this code module:
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK    About(HWND, UINT, WPARAM, LPARAM);

///////////////////////////////////////////////////////////////////////////////

LPCWSTR localPath(LPCWSTR relPath)
{
	lstrcpyW(path, wdir);
	lstrcatW(path, TEXT("\\") );
	lstrcatW(path, relPath);
	return path;
}

///////////////////////////////////////////////////////////////////////////////

size_t allocTextf(LPCWSTR fname, char** p)
{
	size_t i = 0;
	*p = NULL;

	FILE* f =  _wfopen(fname, TEXT("r"));
	if (!f) return i;

	fseek(f, 0, SEEK_END);
	i = ftell(f) + 1;
	fseek(f, 0, SEEK_SET);

	*p = (char*)calloc(i,1);
	fread(*p, 1, i-1, f);
	fclose(f);

	return i;
}

///////////////////////////////////////////////////////////////////////////////

GLuint compileShaderFromFile(LPCWSTR fpath, GLenum shaderType)
{
	GLuint shaderId;
	char* shaderSrc = NULL;
	size_t charsRead = allocTextf(fpath, &shaderSrc);

	if (!charsRead) {
		MessageBoxW(0, fpath, TEXT("Shader file not found"), 0);
		return 0;
	}
	
	//GLboolean b;
	//glGetBooleanv(GL_SHADER_COMPILER,&b);

	shaderId = glCreateShader(shaderType);
	glShaderSource(shaderId, 1, &shaderSrc, NULL);
	glCompileShader(shaderId);
	GLint shaderStatus;
	glGetShaderiv(shaderId, GL_COMPILE_STATUS, &shaderStatus);

	if (shaderStatus != GL_TRUE)
	{
		GLchar messages[256];
		glGetShaderInfoLog(shaderId, sizeof(messages), 0, &messages[0]);
		MessageBoxA(0, &messages[0], "Shader error", 0);
	}

	free(shaderSrc);
	return shaderId;
}

///////////////////////////////////////////////////////////////////////////////

int toUTF8Str(LPCWSTR str, char* utf8Str)
{
	int size_needed = WideCharToMultiByte(CP_UTF8, 0, str, wcslen(str), NULL, 0, NULL, NULL);
	WideCharToMultiByte(CP_UTF8, 0, str, wcslen(str), utf8Str, size_needed + 1, NULL, NULL);
	utf8Str[size_needed] = '\0';
	return size_needed + 1;
}

///////////////////////////////////////////////////////////////////////////////

GLuint buildTextureFromFile( LPCWSTR filePath, GLuint tUnit)
{
	GLuint tex;
	glGenTextures(1, &tex);
	glActiveTexture(GL_TEXTURE0 + tUnit);
	glBindTexture(GL_TEXTURE_2D, tex);
	
	unsigned char *imageData;
	char temp[1024];
	int w, h, channels;

	toUTF8Str(filePath, temp);
	imageData = stbi_load(temp, &w, &h, &channels, STBI_rgb_alpha);

	// Order matters! glTexImage2d before glTexParameteri (!)
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,
		w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
	free(imageData);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
	glGenerateMipmap(GL_TEXTURE_2D);

	return tex;
}

///////////////////////////////////////////////////////////////////////////////

void buildScreenVao(void)
{
	// The "screen" is a parabolic mesh that is created using instancing.
	// Each character cell is derived at the appropriate coordinates from
	// a single base quad. The shader gets a character and a color value for
	// each instance.

	// Set up a vertex buffer array

	glGenVertexArrays(1, &glid_screen.buf_vao);
	glBindVertexArray(glid_screen.buf_vao);

	// Set up the buffer containing the vertices of the base quad

	GLuint vertexBuffer;
	glGenBuffers(1, &vertexBuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);

	GLfloat vertexData[6 * 8] =   // 3 vertex offset, 2 tex coordinates
	{
		0.0, 0.0, 0.0,  0.0, 1.0,
		0.0, 0.0, 0.0,  0.0, 1.0, // Degenerate vertex
		0.0, 1.0, 1.0,  0.0, 0.0,
		1.0, 0.0, 0.0,  1.0, 1.0,
		1.0, 1.0, 1.0,  1.0, 0.0,
		1.0, 1.0, 1.0,  1.0, 0.0, // Degenerate vertex
	};

	glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData),
		vertexData, GL_STATIC_DRAW);

	glVertexAttribPointer(glid_screen.attr_vertexOffs, 3, GL_FLOAT, GL_FALSE,
		5 * sizeof(GLfloat), (void *)0);
	glEnableVertexAttribArray(glid_screen.attr_vertexOffs);

	glVertexAttribPointer(glid_screen.attr_uvChar, 2, GL_FLOAT, GL_FALSE,
		5 * sizeof(GLfloat), (void *)12);
	glEnableVertexAttribArray(glid_screen.attr_uvChar);


	// Set up the buffer for screen characters

	glGenBuffers(1, &glid_screen.buf_vboChars);
	glBindBuffer(GL_ARRAY_BUFFER, glid_screen.buf_vboChars);
	glBufferData(GL_ARRAY_BUFFER, sizeof(paver.screenData),
		&paver.screenData,
		GL_STREAM_DRAW);

	glVertexAttribIPointer(glid_screen.attr_charData, 1, GL_UNSIGNED_SHORT,
		1 * sizeof(GL_UNSIGNED_SHORT), (GLvoid*)0);
	glVertexAttribDivisor(glid_screen.attr_charData, 1); // Instanced
	glEnableVertexAttribArray(glid_screen.attr_charData);


	// Set up the buffer for screen colors

	glGenBuffers(1, &glid_screen.buf_vboColors);
	glBindBuffer(GL_ARRAY_BUFFER, glid_screen.buf_vboColors);
	glBufferData(GL_ARRAY_BUFFER, sizeof(paver.screenColor),
		&paver.screenColor,
		GL_STREAM_DRAW);

	glVertexAttribPointer(glid_screen.attr_charColor, 3, GL_FLOAT,
		GL_FALSE, 3 * sizeof(GL_FLOAT), (GLvoid*)0);
	glVertexAttribDivisor(glid_screen.attr_charColor, 1); // Instanced
	glEnableVertexAttribArray(glid_screen.attr_charColor);

	glBindVertexArray(0);
}

///////////////////////////////////////////////////////////////////////////////

uint32_t* subImageRGBA8(
	uint32_t* idata,
	unsigned ix, unsigned iy,
	unsigned x, unsigned y,
	unsigned w, unsigned h) {

	uint32_t* rimage = (uint32_t*) malloc( w * h * sizeof(uint32_t));

	//for (int i = 0; i < w*h; i++) rimage[i] = 0xFFCC77FF;

	for (int i = y; i < y + h; i++)
		for (int j = x; j < x + w; j++)
			rimage[(i - y)*w + (j - x)] = idata[i*ix + j];

	return rimage;
}

///////////////////////////////////////////////////////////////////////////////

GLuint arrayTextureFromAtlasfile( LPCWSTR filePath, GLuint tu)
{

	int xstep = 9, ystep = 16, xpos = 0, ypos = 0, chindex = 0;
	
	char temp[1024];
	int w, h, channels;

	toUTF8Str(filePath, temp);
	unsigned char* imageData = stbi_load(temp, &w, &h, &channels, STBI_rgb_alpha);
	
	GLuint arrayTextureId;
	glGenTextures(1, &arrayTextureId);
	glActiveTexture(GL_TEXTURE0 + tu);
	glBindTexture(GL_TEXTURE_2D_ARRAY, arrayTextureId);
	glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MIN_FILTER,
		GL_LINEAR_MIPMAP_NEAREST);
	glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_S,
		GL_CLAMP_TO_BORDER);
	glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_T,
		GL_CLAMP_TO_BORDER);
	glTexImage3D(GL_TEXTURE_2D_ARRAY, 0, GL_RGBA8, xstep, ystep,
		256, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glGenerateMipmap(GL_TEXTURE_2D_ARRAY);

	for (ypos = 0; ypos<16 * ystep; ypos += ystep)
		for (xpos = 0; xpos<16 * xstep; xpos += xstep)
		{
			uint32_t* subImage = subImageRGBA8(	(uint32_t*)imageData, w, h, xpos, ypos, xstep, ystep);
			glTexSubImage3D(GL_TEXTURE_2D_ARRAY, 0, 0, 0, chindex++, xstep, ystep, 1, GL_RGBA, GL_UNSIGNED_BYTE, subImage);
			free(subImage);
		}
	free(imageData);
	return arrayTextureId;
}

///////////////////////////////////////////////////////////////////////////////

void updateMatrices(void)
{
	mat4_t m;
	vec3_t v;

	screenModelMatrix = m4_identity();

	// Rotate model matrix
	//m = m4_rotation_x(screen.xrot);
	//screenModelMatrix = m4_mul(screenModelMatrix, m);

	//m = m4_rotation_y(screen.yrot);
	//screenModelMatrix = m4_mul(screenModelMatrix, m);

	//m = m4_rotation_z(screen.zrot);
	//screenModelMatrix = m4_mul(screenModelMatrix, m);

	// Translate model matrix
	v = vec3(screen.xtransl, screen.ytransl, screen.ztransl - 1);
	m = m4_translation(v);
	screenModelMatrix = m4_mul(screenModelMatrix, m);

	//Scale model matrix
//	v = vec3(screen.scale * viewAspect, screen.scale, screen.scale);
//	m = m4_scaling(v);
//	screenModelMatrix = m4_mul(screenModelMatrix, m);

	viewMatrix = m4_identity();

	screenModelViewMatrix = m4_mul(viewMatrix, screenModelMatrix);
	screenModelViewProjectionMatrix = m4_mul(projectionMatrix, screenModelViewMatrix);
}

///////////////////////////////////////////////////////////////////////////////

void buildScreenShaderProgram(void)
{
	// Vertex shader, string from textfile
	GLuint  vs = compileShaderFromFile(localPath(TEXT("Shaders\\glassVs.txt")), GL_VERTEX_SHADER);

	// Fragment shader, string from textfile
	GLuint  fs = compileShaderFromFile(localPath(TEXT("Shaders\\glassFs.txt")), GL_FRAGMENT_SHADER);

	glid_screen.prog_shader = glCreateProgram();
	glAttachShader(glid_screen.prog_shader, vs);
	glAttachShader(glid_screen.prog_shader, fs);
	glBindFragDataLocation(glid_screen.prog_shader, 0, "fsFragColor");
	glLinkProgram(glid_screen.prog_shader);

	// Vertex shader attributes

	glid_screen.attr_vertexOffs = glGetAttribLocation(glid_screen.prog_shader,
		"vertexOffs");
	glid_screen.attr_uvChar = glGetAttribLocation(glid_screen.prog_shader,
		"uvChar");
	glid_screen.attr_charColor = glGetAttribLocation(glid_screen.prog_shader,
		"charColor");
	glid_screen.attr_charData = glGetAttribLocation(glid_screen.prog_shader,
		"charData");

	// Vertex shader uniforms

	glid_screen.uni_bgCol =
		glGetUniformLocation(glid_screen.prog_shader, "bgcol");
	glid_screen.uni_cursorX =
		glGetUniformLocation(glid_screen.prog_shader, "cursorx");
	glid_screen.uni_cursorY =
		glGetUniformLocation(glid_screen.prog_shader, "cursory");
	glid_screen.uni_cursorVis =
		glGetUniformLocation(glid_screen.prog_shader, "cursorvis");

	glid_screen.uni_viewMatrix =
		glGetUniformLocation(glid_screen.prog_shader, "viewMatrix");
	glid_screen.uni_modelViewMatrix =
		glGetUniformLocation(glid_screen.prog_shader, "modelViewMatrix");
	glid_screen.uni_modelViewProjectionMatrix =
		glGetUniformLocation(glid_screen.prog_shader,
			"modelViewProjectionMatrix");
	glid_screen.uni_lightPosition =
		glGetUniformLocation(glid_screen.prog_shader, "light_position");

	// Fragment shader uniforms

	// Samplers
	glid_screen.uni_diffuseMapSampler =
		glGetUniformLocation(glid_screen.prog_shader, "diffuse_map");
	glid_screen.uni_cubemapSampler =
		glGetUniformLocation(glid_screen.prog_shader, "cubemapSampler");
	glid_screen.uni_normalMapSampler =
		glGetUniformLocation(glid_screen.prog_shader, "normal_map");
	glid_screen.uni_arrayTextureSampler =
		glGetUniformLocation(glid_screen.prog_shader, "arrayTextureSampler");

	glid_screen.uni_skyboxYRot =
		glGetUniformLocation(glid_screen.prog_shader, "skyboxYRot");

	glid_screen.uni_lightDiffuse =
		glGetUniformLocation(glid_screen.prog_shader, "light_diffuse");
	glid_screen.uni_lightSpecular =
		glGetUniformLocation(glid_screen.prog_shader, "light_specular");
	glid_screen.uni_materialDiffuse =
		glGetUniformLocation(glid_screen.prog_shader, "material_diffuse");
	glid_screen.uni_materialSpecular =
		glGetUniformLocation(glid_screen.prog_shader, "material_specular");
	glid_screen.uni_materialGloss =
		glGetUniformLocation(glid_screen.prog_shader, "material_gloss");

	glDeleteShader(vs);
	glDeleteShader(fs);
}

///////////////////////////////////////////////////////////////////////////////

GLuint getCubeTextureId(GLuint textureUnit)
{
	GLuint textureId;
	glActiveTexture(GL_TEXTURE0 + textureUnit);
	glGenTextures(1, &textureId);
	glBindTexture(GL_TEXTURE_CUBE_MAP, textureId);

	glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL_RGBA, 2048, 2048, 0,
		GL_RGBA,
		GL_UNSIGNED_BYTE,skybox.nz);

	glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL_RGBA, 2048, 2048, 0,
		GL_RGBA,
		GL_UNSIGNED_BYTE, skybox.pz);

	glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL_RGBA, 2048, 2048, 0,
		GL_RGBA,
		GL_UNSIGNED_BYTE, skybox.py);

	glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL_RGBA, 2048, 2048, 0,
		GL_RGBA,
		GL_UNSIGNED_BYTE, skybox.ny);

	glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL_RGBA, 2048, 2048, 0,
		GL_RGBA,
		GL_UNSIGNED_BYTE, skybox.nx);

	glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL_RGBA, 2048, 2048, 0,
		GL_RGBA,
		GL_UNSIGNED_BYTE, skybox.px);

	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	return textureId;
}

///////////////////////////////////////////////////////////////////////////////

void initSkyBox(void)
{
	char temp[1024];
	int w, h, channels;

	localPath(TEXT("Images\\Skybox\\nx.png"));
	toUTF8Str(path, temp);
	skybox.nx = stbi_load(temp, &w, &h, &channels, STBI_rgb_alpha);

	localPath(TEXT("Images\\Skybox\\ny.png"));
	toUTF8Str(path, temp);
	skybox.ny = stbi_load(temp, &w, &h, &channels, STBI_rgb_alpha);

	localPath(TEXT("Images\\Skybox\\nz.png"));
	toUTF8Str(path, temp);
	skybox.nz = stbi_load(temp, &w, &h, &channels, STBI_rgb_alpha);

	localPath(TEXT("Images\\Skybox\\px.png"));
	toUTF8Str(path, temp);
	skybox.px = stbi_load(temp, &w, &h, &channels, STBI_rgb_alpha);
	
	localPath(TEXT("Images\\Skybox\\py.png"));
	toUTF8Str(path, temp);
	skybox.py = stbi_load(temp, &w, &h, &channels, STBI_rgb_alpha);
	
	localPath(TEXT("Images\\Skybox\\pz.png"));
	toUTF8Str(path, temp);
	skybox.pz = stbi_load(temp, &w, &h, &channels, STBI_rgb_alpha);
}

///////////////////////////////////////////////////////////////////////////////

void initScreenModel(void)
{
	char temp[1024];
	int w, h, channels;

	buildScreenShaderProgram();
	buildScreenVao();

	glid_screen.tex_arrayTexture = arrayTextureFromAtlasfile(localPath(TEXT("Images\\VGA9x16.png")), 3);

	localPath(TEXT("Images\\poppy.png"));
	toUTF8Str(path, temp);
	paver.gfxRawData = stbi_load(temp, &w, &h, &channels, STBI_rgb_alpha);
	localPath(TEXT("Images\\leaftex1.png"));
	toUTF8Str(path, temp);
	paver.bgpicRawData = stbi_load(temp, &w, &h, &channels, STBI_rgb_alpha);

	glid_screen.tex_GFX = buildTextureFromFile(localPath(TEXT("Images\\leaftex1.png")), 0);
	glid_screen.tex_normal = buildTextureFromFile(localPath(TEXT("Images\\leaftex1_NRM.png")), 2);
	
	glid_screen.tex_cube = getCubeTextureId(1);
}

///////////////////////////////////////////////////////////////////////////////


void renderScreen(void)
{
	glUseProgram(glid_screen.prog_shader);

	glUniform1i(glid_screen.uni_diffuseMapSampler, 0);
	glUniform1i(glid_screen.uni_cubemapSampler, 1);
	glUniform1i(glid_screen.uni_normalMapSampler, 2);
	glUniform1i(glid_screen.uni_arrayTextureSampler, 3);

	glUniform3f(glid_screen.uni_bgCol, glBGColor.x, glBGColor.y, glBGColor.z);

	glUniform1f(glid_screen.uni_cursorX, paver.cursorX);
	glUniform1f(glid_screen.uni_cursorY, paver.cursorY);
	glUniform1f(glid_screen.uni_cursorVis, paver.cursorVis);

	glUniform1f(glid_screen.uni_skyboxYRot, scene.skybox_yRot);

	glUniformMatrix4fv(glid_screen.uni_viewMatrix, 1, GL_FALSE,
		(const GLfloat*) &viewMatrix);
	glUniformMatrix4fv(glid_screen.uni_modelViewMatrix, 1, GL_FALSE,
		(const GLfloat*) &screenModelViewMatrix);
	glUniformMatrix4fv(glid_screen.uni_modelViewProjectionMatrix, 1, GL_FALSE,
		(const GLfloat*) &screenModelViewProjectionMatrix);

	glUniform4f(glid_screen.uni_lightPosition,
		scene.xlight, scene.ylight, scene.zlight + 2, 1.0);

	glUniform4f(glid_screen.uni_lightDiffuse, 1.0, 1.0, 1.0, 1.0);
	glUniform4f(glid_screen.uni_materialDiffuse, 1.0, 1.0, 1.0, 1.0);
	glUniform4f(glid_screen.uni_lightSpecular, 0.9, 0.9, 0.9, 1.0);
	glUniform4f(glid_screen.uni_materialSpecular, 0.9, 0.9, 0.9, 1.0);
	glUniform1f(glid_screen.uni_materialGloss, 32.0);

	glBindVertexArray(glid_screen.buf_vao);

	// Bind gfx/diffuse map to texture unit 0
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, glid_screen.tex_GFX);

	// Bind cube map to unit 1
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_CUBE_MAP, glid_screen.tex_cube);

	// Bind normal map to unit 2
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, glid_screen.tex_normal);

	// Bind array texture to unit 3
	glActiveTexture(GL_TEXTURE3);
	glBindTexture(GL_TEXTURE_2D_ARRAY, glid_screen.tex_arrayTexture);

	glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 6, 128 * 32);
}


///////////////////////////////////////////////////////////////////////////////

char* getClipText()
{
	int i;
	if (OpenClipboard(NULL))
	{
		for (i = 0; i<32*80; i++) paver.clipText[i] = 32;
		HANDLE hClipboardData = GetClipboardData(CF_TEXT);
		char* clipText = (char*)GlobalLock(hClipboardData);
		unsigned strl = strlen(clipText);
		for (i = 0; i < strl; i++) {
			if (clipText[i] == '\t') clipText[i] = ' ';
			if (clipText[i] != '\r')
				if (i<32*80)	paver.clipText[i] = clipText[i];
		}
		while (i<32*80) paver.clipText[i++] = 32;
		GlobalUnlock(hClipboardData);
		CloseClipboard();
	}
}

///////////////////////////////////////////////////////////////////////////////

// Thread func signature
DWORD WINAPI startSonne16(LPVOID lpParam)
{
	char* temp[1024];
	localPath(TEXT("card.8T3"));
	toUTF8Str(path, temp);
	setCardFileName(temp);
	xferboot(temp);
	paver.pavMacPath = ".";
	run();
}

///////////////////////////////////////////////////////////////////////////////

int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPWSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    // TODO: Place code here.

    // Initialize global strings
    LoadStringW(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
    LoadStringW(hInstance, IDC_PHOS, szWindowClass, MAX_LOADSTRING);
    MyRegisterClass(hInstance);

    // Perform application initialization:
    if (!InitInstance (hInstance, nCmdShow))
    {
        return FALSE;
    }

    HACCEL hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_PHOS));
    MSG msg;

    // Main message loop:
    while (GetMessage(&msg, NULL, 0, 0))
    {
        if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return (int) msg.wParam;
}

///////////////////////////////////////////////////////////////////////////////

//
//  FUNCTION: MyRegisterClass()
//
//  PURPOSE: Registers the window class.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
    WNDCLASSEXW wcex;

    wcex.cbSize = sizeof(WNDCLASSEX);

    wcex.style          = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    wcex.lpfnWndProc    = WndProc;
    wcex.cbClsExtra     = 0;
    wcex.cbWndExtra     = 0;
    wcex.hInstance      = hInstance;
    wcex.hIcon          = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_PHOS));
    wcex.hCursor        = LoadCursor(NULL, IDC_ARROW);
    wcex.hbrBackground  = (HBRUSH)(COLOR_WINDOW+1);
    wcex.lpszMenuName   = MAKEINTRESOURCEW(IDC_PHOS);
    wcex.lpszClassName  = szWindowClass;
    wcex.hIconSm        = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));

    return RegisterClassExW(&wcex);
}

///////////////////////////////////////////////////////////////////////////////

void SetClientSize(HWND hwnd, int clientWidth, int clientHeight)
{
	if (IsWindow(hwnd))
	{

		DWORD dwStyle = GetWindowLongPtr(hwnd, GWL_STYLE);
		DWORD dwExStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
		HMENU menu = GetMenu(hwnd);

		RECT rc = { 0, 0, clientWidth, clientHeight };

		AdjustWindowRectEx(&rc, dwStyle, menu ? TRUE : FALSE, dwExStyle);

		SetWindowPos(hwnd, NULL, 0, 0, rc.right - rc.left, rc.bottom - rc.top,
			SWP_NOZORDER | SWP_NOMOVE);
	}
}

///////////////////////////////////////////////////////////////////////////////

BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   hInst = hInstance; // Store instance handle in our global variable
   
   HWND hWnd = CreateWindowW(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW, // | WS_MINIMIZEBOX | WS_SYSMENU,
      CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, NULL, NULL, hInstance, NULL);

   if (!hWnd)
   {
      return FALSE;
   }
 
   viewAspect = 2.0; // Should be 2.25 = 9*128/512
   clienth = 712;
   clientw = clienth * viewAspect;
   SetClientSize(hWnd, clientw, clienth);
   glViewport(0, 0, clientw, clienth);
   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);
   return TRUE;
}

///////////////////////////////////////////////////////////////////////////////

LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
	{
		case WM_CHAR:
		paver.keyCode = wParam;
		switch (wParam)
		{
		case VK_BACK:   paver.keyCode = 8; break;
		case VK_RETURN: paver.keyCode = 10; break;
		case VK_ESCAPE: paver.keyCode = 27; break;
		}
		paver.scanCodeReady = 1;
		paver.idle = 0;
		break;

	case WM_KEYDOWN:
		switch (wParam) // Map these to Verilog PS/2 module
			{
				case VK_INSERT: paver.keyCode = 1; break;
				case VK_DELETE:
					if (GetKeyState(VK_SHIFT) & 0x8000) // If the high - order bit is 1, the key is down
						paver.keyCode = 29;
					else paver.keyCode = 127;
					break;
				case VK_UP:     paver.keyCode = 6; break;
				case VK_DOWN:   paver.keyCode = 11; break;
				case VK_RIGHT:  paver.keyCode = 14; break;
				case VK_LEFT:   paver.keyCode = 12; break;
				case VK_HOME:   paver.keyCode = 2; break;
				case VK_F1:		paver.keyCode = 16; break;
				case VK_F2:		paver.keyCode = 17; break;
				case VK_F3:		paver.keyCode = 18; break;
				case VK_F4:		paver.keyCode = 19; break;
				case VK_F5:		paver.keyCode = 20; break;
				case VK_F6:		paver.keyCode = 21; break;
				case VK_F12:    paver.keyCode = 28; break;
				
				case VK_END:
					getClipText();
					paver.clipReady = 1;
					paver.keyCode = 3;
					break;

				case VK_PRIOR:   paver.keyCode = 4; break; // PgUP
				case VK_NEXT:    paver.keyCode = 5; break; // PgDN
		}
			if ( (wParam != VK_SHIFT) || (paver.keyCode == 29)) {
				paver.scanCodeReady = 1;
				paver.idle = 0;
			}
		break;

	case WM_WINDOWPOSCHANGING:
		//wp = (WINDOWPOS*) lParam;
		//SetCursorPos(wp->x + wp->cx, wp->y + wp->cy);
		//return 0;
		break;

	case WM_WINDOWPOSCHANGED:
			GetClientRect(hWnd, &rect);
			if (IsZoomed(hWnd)) SystemParametersInfoA(SPI_GETWORKAREA, NULL, &rect, NULL);
			int recth = rect.bottom - rect.top;
			int rectw = rect.right - rect.left;
			if (IsZoomed(hWnd)) {
				GetClientRect(hWnd, &rect);
				glViewport(0, 0, rectw, recth);
			}
			else {
				SetClientSize(hWnd, viewAspect * recth, recth);
				glViewport(0, 0, viewAspect * recth, recth);
			}
			ShowWindow(hWnd, SW_SHOW);
		return 0;
		break;

	case WM_CREATE:
		{
			_wgetcwd(wdir, 1024);

			PIXELFORMATDESCRIPTOR pfd =
			{
				sizeof(PIXELFORMATDESCRIPTOR),
				1,
				PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,    //Flags
				PFD_TYPE_RGBA,        // The kind of framebuffer. RGBA or palette.
				32,                   // Colordepth of the framebuffer.
				0, 0, 0, 0, 0, 0,
				0,
				0,
				0,
				0, 0, 0, 0,
				24,                   // Number of bits for the depthbuffer
				8,                    // Number of bits for the stencilbuffer
				0,                    // Number of Aux buffers in the framebuffer.
				PFD_MAIN_PLANE,
				0,
				0, 0, 0
			};

			ourWindowHandleToDeviceContext = GetDC(hWnd);

			int  letWindowsChooseThisPixelFormat;
			letWindowsChooseThisPixelFormat = ChoosePixelFormat(ourWindowHandleToDeviceContext, &pfd);
			SetPixelFormat(ourWindowHandleToDeviceContext, letWindowsChooseThisPixelFormat, &pfd);

			ourOpenGLRenderingContext = wglCreateContext(ourWindowHandleToDeviceContext);
			wglMakeCurrent(ourWindowHandleToDeviceContext, ourOpenGLRenderingContext);
						
			if (!gladLoadGL()) {
				MessageBoxA(0, (char*)glGetString(GL_VERSION), "Glad failed", 0);
				exit(-1);
			}

			initSkyBox();
			initScreenModel();

			paver.gfxH = 720;
			paver.gfxV = 64;
			screen.scale = 1.0;

			paver.threadHandle = CreateThread(NULL, 0, startSonne16, (LPVOID) &paver.threadData, 0, NULL);
			
			viewMatrix = m4_identity();
			//setProjectionMatrix();

			glOrtho( - clientw / 2.0f, clientw / 2.0f, - clienth / 2.0f, clienth / 2.0f, -1, 1);

			glEnable(GL_BLEND);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			glEnable(GL_DEPTH_TEST);
			glDepthFunc(GL_LESS);

			// Create a timer n milliseconds
			SetTimer(hWnd, 101, 15, NULL);
		}
		break;
    case WM_COMMAND:
        {
            int wmId = LOWORD(wParam);
            // Parse the menu selections:
            switch (wmId)
            {
            case IDM_ABOUT:
                DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
                break;
            case IDM_EXIT:
                DestroyWindow(hWnd);
                break;
            default:
                return DefWindowProc(hWnd, message, wParam, lParam);
            }
        }
        break;
	case WM_TIMER:
	{
		glBGColor = vec3(
			(double)((paver.bgCol >> 11) / 32.0),
			(double)((paver.bgCol >> 5) & 63) / 64.0,
			(float)((paver.bgCol & 31) / 32.0)
		);

		glBindBuffer(GL_ARRAY_BUFFER, glid_screen.buf_vboChars);
		glBufferSubData(GL_ARRAY_BUFFER, 0, 4096 * 4, &paver.screenData[paver.txtBase]);

		glBindBuffer(GL_ARRAY_BUFFER, glid_screen.buf_vboColors);
		glBufferSubData(GL_ARRAY_BUFFER, 0, 4096 * 12, &paver.screenColor[paver.txtBase]);

		// Blend the gfx inlay with the bg picture and send to graphics card
		int startx = paver.gfxH % (clientw - 256);
		int starty = paver.gfxV % (clienth - 256);
		for (int y = 0; y < 256; y++)
			for (int x = 0; x < 256; x++) {
				uint32_t bgpix = ((uint32_t*)paver.bgpicRawData)[(startx + x)*256 + (starty + y)];  
#define pix ((uint32_t*)paver.gfxRawData)[(paver.gfxBase & (128 * 1024 - 1)) + (x*256)+y]
				uint32_t inlaypix = pix & 0xFFF;
				if (inlaypix==0) pix = bgpix;
			}
		glActiveTexture(GL_TEXTURE0 + 0); // GFX/diffuse texture
		glBindTexture(GL_TEXTURE_2D, glid_screen.tex_GFX);
		glTexSubImage2D(GL_TEXTURE_2D, 0, startx, starty,
				256, 256, GL_RGBA,
				GL_UNSIGNED_BYTE, &paver.gfxRawData[4 * (paver.gfxBase & (128 * 1024 - 1))]);

		updateMatrices();
		scene.skybox_yRot += 0.000003; // 0.0001;
		InvalidateRect(hWnd, NULL, FALSE);
	}
	break;
    case WM_PAINT:
		{
			PAINTSTRUCT ps;
			HDC hdc = BeginPaint(hWnd, &ps);
				glClearColor(0.5*glBGColor.x, 0.5*glBGColor.y, 0.5*glBGColor.z, 1.0);
				glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
				renderScreen();

				//Flushbuffer?
				SwapBuffers(hdc);
				ValidateRect(hWnd, NULL);
			EndPaint(hWnd, &ps);
		}
        break;
    case WM_DESTROY:
		wglDeleteContext(ourOpenGLRenderingContext);
        PostQuitMessage(0);
        break;
    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

///////////////////////////////////////////////////////////////////////////////

// Message handler for about box.
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    UNREFERENCED_PARAMETER(lParam);
    switch (message)
    {
    case WM_INITDIALOG:
        return (INT_PTR)TRUE;

    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
        {
            EndDialog(hDlg, LOWORD(wParam));
            return (INT_PTR)TRUE;
        }
        break;
    }
    return (INT_PTR)FALSE;
}




//char str[4096];
//sprintf_s(str, "%s", "sdjhfdj");
//MessageBoxA(0, str, "Glad failed", 0);
//OutputDebugStringW(L"My output string.");