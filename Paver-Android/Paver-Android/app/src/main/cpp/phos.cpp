// Android version of a Paverho/Sonne-16 simulator
// Copyr. 2018 Michael Mangelsdorf (mim@ok-schalter.de)

#include <GLES3/gl3.h>

#include <android/log.h>

#include "sonne16.h"

#define MATH_3D_IMPLEMENTATION
#include "math_3d.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"


#define phos_TOUCH_DOWN 1
#define phos_TOUCH_MOVE 2
#define phos_TOUCH_UP 3
#define phos_TOUCH_RESET 4


#define phos_EVENT_TOUCH_RESET 100
#define phos_EVENT_TOUCH_SINGLE_MAKE 101
#define phos_EVENT_TOUCH_SINGLE_BREAK 102
#define phos_EVENT_TOUCH_DOUBLE_MAKE 103
#define phos_EVENT_TOUCH_DOUBLE_BREAK 104
#define phos_EVENT_TOUCH_PINCH 105
#define phos_EVENT_TOUCH_PAN 106

enum Phase {CREATE=0, RESTORE=1, PAUSE=2, SAVE=3, EXIT=4};

struct phos_Touchinfo {
    int id;
    long timestamp, timestamp_old;
    float x, y, x_old, y_old;
};

GLfloat surface_width;
GLfloat surface_height;

vec3_t bgColor;

extern char* getAssetPtr( const char* fname, size_t *length);
extern int phos_runthread(void *(*start_routine) (void *));

static struct phos_Touchinfo phos_TOUCHSTATE[4]; /* Index 2,3 are initial copies of 0,1 */
static struct timeval phos_TIMEVAL_TEMP;
static uint_fast8_t phos_FINGERSDOWN;

double viewaspect = 1.0;
const char* phos_applicationpath = NULL;
char cardFileName[1024];

mat4_t viewMatrix;
mat4_t projectionMatrix;
mat4_t screenModelMatrix;
mat4_t screenModelViewMatrix;
mat4_t screenModelViewProjectionMatrix;


struct { // These are state variables for the scene

    GLfloat xlight, ylight, zlight;
    GLfloat xrot, yrot, zrot;
    GLfloat skybox_yRot,  yrotIncrement;
} scene;

struct { // These are state variables for the screen mesh

    GLfloat xrot, yrot, zrot;
    GLfloat xtransl, ytransl, ztransl;
    GLfloat scale, lastScale;

    GLfloat v_diffuseAlpha;
    GLfloat *data;

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

    GLint uni_v_diffuseAlpha;
    GLint uni_skyboxYRot;

    GLint uni_cursorX;
    GLint uni_cursorY;
    GLint uni_cursorVis;
    GLint uni_bgCol;

    GLint uni_viewMatrix;
    GLint uni_modelViewMatrix;
    GLint uni_modelViewProjectionMatrix;

    GLint uni_diffuseMapSampler;
    GLint uni_inlaySampler;
    GLint uni_specularMapSampler;
    GLint uni_normalMapSampler;
    GLint uni_cubemapSampler;
    GLint uni_arrayTextureSampler;

    GLint uni_lightDiffuse;
    GLint uni_lightSpecular;
    GLint uni_materialDiffuse;
    GLint uni_materialSpecular;
    GLint uni_materialGloss;

    GLint uni_lightPosition;
    GLint uni_lightConstantTerm;
    GLint uni_lightLinearTerm;
    GLint uni_lightQuadraticTerm;

// Textures

    GLint  tex_specular;
    GLint  tex_normal;
    GLuint tex_cube;
    GLint  tex_arrayTexture;
    GLuint tex_diffuse;
    GLuint tex_gfx;

} glid_screen;

struct {

// Buffers

    GLuint buf_vao;
    GLuint buf_vboChars;
    GLuint buf_vboColors;

// Shader program

    GLuint prog_shader;

// Attributes

    GLint attr_vertexOffs;
    GLint attr_uvChar;
    GLint attr_charColor;
    GLint attr_charData;

// Uniforms

    GLfloat uni_skyboxYRot;

    GLint uni_cursorX;
    GLint uni_cursorY;
    GLint uni_cursorVis;
    GLint uni_bgCol;

    GLint uni_viewMatrix;
    GLint uni_modelViewMatrix;
    GLint uni_modelViewProjectionMatrix;

    GLint uni_v_showBg;
    GLint uni_v_pixResX;
    GLint uni_v_pixResY;

    GLint uni_diffuseMapSampler;
    GLint uni_specularMapSampler;
    GLint uni_normalMapSampler;
    GLint uni_cubemapSampler;
    GLint uni_arrayTextureSampler;

    GLint uni_lightDiffuse;
    GLint uni_lightSpecular;
    GLint uni_materialDiffuse;
    GLint uni_materialSpecular;
    GLint uni_materialGloss;

    GLint uni_lightPosition;
    GLint uni_lightConstantTerm;
    GLint uni_lightLinearTerm;
    GLint uni_lightQuadraticTerm;

// Textures

    GLint tex_specular;
    GLint tex_normal;
    GLint tex_cube;
    GLuint tex_arrayTexture;
    GLint tex_GFX;

} glid_console;

struct {
    GLfloat xrot, yrot, zrot;
    GLfloat xtransl, ytransl, ztransl;
    GLfloat scale, lastScale;
    GLfloat showBg;
    GLfloat *data;
    struct { float r, g, b; } screenColor[64 * 32 * 2];
} console;


// Converts degrees to radians.
#define degreesToRadians(angleDegrees) (angleDegrees * M_PI / 180.0)

// Converts radians to degrees.
#define radiansToDegrees(angleRadians) (angleRadians * 180.0 / M_PI)


/*
 * Helper function for the touch handler
 */
float
phos_touchzoom(void)
{
    float dx = abs(phos_TOUCHSTATE[3].x - phos_TOUCHSTATE[2].x);
    float dy = abs(phos_TOUCHSTATE[3].y - phos_TOUCHSTATE[2].y);
    float initlen = sqrt( dx*dx + dy*dy);
    dx = abs(phos_TOUCHSTATE[1].x - phos_TOUCHSTATE[0].x);
    dy = abs(phos_TOUCHSTATE[1].y - phos_TOUCHSTATE[0].y);
    float currlen = sqrt( dx*dx + dy*dy);
    return currlen / initlen;
}


/*
 * Helper function for the touch handler
 */
static void
phos_settouchstate(int index, int id, float x, float y)
{
    phos_TOUCHSTATE[index].id = id;
    phos_TOUCHSTATE[index].x_old = phos_TOUCHSTATE[index].x;
    phos_TOUCHSTATE[index].x = x;
    phos_TOUCHSTATE[index].y_old = phos_TOUCHSTATE[index].y;
    phos_TOUCHSTATE[index].y = y;
    phos_TOUCHSTATE[index].timestamp_old = phos_TOUCHSTATE[index].timestamp_old;
    phos_TOUCHSTATE[index].timestamp = phos_TIMEVAL_TEMP.tv_usec;
};


/*
 * Helper function for the touch handler
 */
static void
phos_copyfinger(uint_fast8_t src, uint_fast8_t dst)
{
    phos_TOUCHSTATE[dst].id = phos_TOUCHSTATE[src].id;
    phos_TOUCHSTATE[dst].x = phos_TOUCHSTATE[src].x;
    phos_TOUCHSTATE[dst].x_old = phos_TOUCHSTATE[src].x_old;
    phos_TOUCHSTATE[dst].y = phos_TOUCHSTATE[src].y;
    phos_TOUCHSTATE[dst].y_old = phos_TOUCHSTATE[src].y_old;
    phos_TOUCHSTATE[dst].timestamp = phos_TOUCHSTATE[src].timestamp;
    phos_TOUCHSTATE[dst].timestamp_old = phos_TOUCHSTATE[src].timestamp_old;
}


/*
 * Called by the glue layer for each touch event
 */
static void
phos_eventh(uint16_t eventid)
{
    switch (eventid){
        case phos_EVENT_TOUCH_RESET:
            break;

        case phos_EVENT_TOUCH_SINGLE_MAKE:
            break;

        case phos_EVENT_TOUCH_SINGLE_BREAK:
            break;

        case phos_EVENT_TOUCH_DOUBLE_MAKE:
            screen.lastScale = screen.scale;
            break;

        case phos_EVENT_TOUCH_DOUBLE_BREAK:
            break;

        case phos_EVENT_TOUCH_PAN:
            break;

        case phos_EVENT_TOUCH_PINCH:
            screen.scale = screen.lastScale * phos_touchzoom();
            if (screen.scale < 0.8) screen.scale = 0.8;
            if (screen.scale > 2.0) screen.scale = 2.0;
            break;

        default: break;
    }
}


/*
 * Helper function signal error state during touch events
 */
static void
phos_toucherror(void)
{
    phos_FINGERSDOWN = 0;
    phos_eventh(phos_EVENT_TOUCH_RESET);
}


/*
 * Helper function, iterate touches delete zombies
 */
static void
phos_expiretouches(void)
{

}


/*
 * Host driven entry point to the touch system
 */
void
phos_cb_touch(int action, int id, float x, float y)
{
    gettimeofday( &phos_TIMEVAL_TEMP, NULL);
    phos_expiretouches();
    switch(action){

        case phos_TOUCH_DOWN:
            switch (phos_FINGERSDOWN) {
                case 0:
                    phos_settouchstate(phos_FINGERSDOWN, id, x, y);
                    phos_FINGERSDOWN++;
                    phos_eventh(phos_EVENT_TOUCH_SINGLE_MAKE);
                    break;
                case 1:
                    /* Sanity check if the new finger is different from the one we got */
                    if (phos_TOUCHSTATE[0].id != id){
                        phos_settouchstate(phos_FINGERSDOWN, id, x, y);
                        phos_FINGERSDOWN++;
                        phos_eventh(phos_EVENT_TOUCH_DOUBLE_MAKE);
                        phos_copyfinger(0,2);
                        phos_copyfinger(1,3);
                    }else
                        phos_toucherror();
                    break;
                default:
                    phos_toucherror();
                    break;
            }
            break;

        case phos_TOUCH_MOVE:
            switch (phos_FINGERSDOWN){
                case 1:
                    /* Sanity check is this the finger we got */
                    if (phos_TOUCHSTATE[0].id == id) {
                        phos_settouchstate(0, id, x, y);
                        phos_eventh(phos_EVENT_TOUCH_PAN);
                    } else
                        phos_toucherror();
                    break;
                case 2:
                    /* Sanity check is this one of the fingers we got */
                    if (phos_TOUCHSTATE[0].id == id){
                        phos_settouchstate(0, id, x, y);
                        phos_eventh(phos_EVENT_TOUCH_PINCH);
                    }else if(phos_TOUCHSTATE[1].id == id){
                        phos_settouchstate(1, id, x, y);
                        phos_eventh(phos_EVENT_TOUCH_PINCH);
                    }else
                        phos_toucherror();
                    break;
                default:
                    /* Moving non-registered finger, lost sync somehow */
                    phos_toucherror();
                    break;
            }
            break;

        case phos_TOUCH_UP:
            switch (phos_FINGERSDOWN){
                case 1:
                    if (phos_TOUCHSTATE[0].id == id){ /* First finger lifted */
                        phos_FINGERSDOWN--;
                        phos_eventh(phos_EVENT_TOUCH_SINGLE_BREAK);
                    } else
                        phos_toucherror();
                    break;
                case 2:
                    if (phos_TOUCHSTATE[0].id == id){ /* First finger lifted */
                        phos_copyfinger(1,0);
                        phos_FINGERSDOWN--;
                        phos_eventh(phos_EVENT_TOUCH_DOUBLE_BREAK);
                    } else if (phos_TOUCHSTATE[1].id == id){ /* Second finger lifted */
                        phos_FINGERSDOWN--;
                        phos_eventh(phos_EVENT_TOUCH_DOUBLE_BREAK);
                    } else
                        phos_toucherror();
                    break;
                default:
                    /* Lifting non-registered finger, lost sync somehow */
                    phos_toucherror();
                    break;
            }
            break;

        case phos_TOUCH_RESET:
            phos_toucherror();
            break;

        default: break;
    }
}


/*
 * Loads an image asset and returns a malloc'd pointer to it
 */
unsigned char*
getImageDataPtr(const char *filePath, int w, int h)
{
    size_t length;
    char* p = getAssetPtr(filePath, &length);
    int channels;
    const stbi_uc* buffer = (stbi_uc*) p;
    unsigned char* imageData =
            stbi_load_from_memory(buffer, (int)length, &w, &h, &channels, STBI_rgb_alpha);
    return imageData;
}


/*
 * Constructs a cubemap from 6 image files
 */
GLuint
getCubeTextureId(GLuint textureUnit)
{
    GLuint textureId;
    glActiveTexture(GL_TEXTURE0 + textureUnit);
    glGenTextures(1, &textureId);
    glBindTexture(GL_TEXTURE_CUBE_MAP, textureId);

    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL_RGBA8, 1024, 1024, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, getImageDataPtr("Skybox/nz.png", 1024, 1024));

    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL_RGBA8, 1024, 1024, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, getImageDataPtr("Skybox/pz.png", 1024, 1024));

    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL_RGBA8, 1024, 1024, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, getImageDataPtr("Skybox/py.png", 1024, 1024));

    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL_RGBA8, 1024, 1024, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, getImageDataPtr("Skybox/ny.png", 1024, 1024));

    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL_RGBA8, 1024, 1024, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, getImageDataPtr("Skybox/nx.png", 1024, 1024));

    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL_RGBA8, 1024, 1024, 0,
                 GL_RGBA,GL_UNSIGNED_BYTE, getImageDataPtr("Skybox/px.png", 1024, 1024));

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    return textureId;
}


/*
 * Compiles an OpenGL shader from a text file
 */
GLuint
compileShaderFromFile(const char *path, GLenum shaderType)
{
    size_t length;
    GLuint shaderId;
    char* p = getAssetPtr(path, &length);
    const char* shaderSrc = p;

    shaderId = glCreateShader(shaderType);
    glShaderSource(shaderId, 1, &shaderSrc, NULL);
    free( (void*) shaderSrc);

    glCompileShader(shaderId);
    GLint shaderStatus;
    glGetShaderiv(shaderId, GL_COMPILE_STATUS, &shaderStatus);
    //if (shaderStatus != GL_TRUE) { }
    return shaderId;
}


/*
 * Helper function for arrayTextureFromAtlasfile()
 */
uint32_t*
subImageRGBA8(
        uint32_t* idata,
        unsigned ix,
        unsigned x, unsigned y,
        unsigned w, unsigned h)
{
    uint32_t* rimage = (uint32_t*) malloc( w * h * sizeof(uint32_t));

    //for (int i = 0; i < w*h; i++) rimage[i] = 0xFFCC77FF;

    for (int i = y; i < y + h; i++)
        for (int j = x; j < x + w; j++)
            rimage[(i - y)*w + (j - x)] = idata[i*ix + j];

    return rimage;
}


/*
 *  Constructs a 3D texture from an image atlas
 */
GLuint
arrayTextureFromAtlasfile(const char *filePath, GLuint tu)
{
    unsigned xstep = 9, ystep = 16, xpos = 0, ypos = 0, chindex = 0;
    unsigned w, h, channels;

    size_t length;
    //char *p = getAssetPtr(filePath, &length);
    char *p = getAssetPtr("VGA9x16.png", &length); // filePath);
    const stbi_uc* buffer = (stbi_uc*) p;
    unsigned char* imageData = stbi_load_from_memory(
            buffer, (int)length, (int*) &w, (int*) &h, (int*) &channels, STBI_rgb_alpha);

    GLuint arrayTextureId;
    glGenTextures(1, &arrayTextureId);
    glActiveTexture(GL_TEXTURE0 + tu);
    glBindTexture(GL_TEXTURE_2D_ARRAY, arrayTextureId);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MIN_FILTER,
                    GL_LINEAR_MIPMAP_NEAREST);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    //glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    glTexImage3D(GL_TEXTURE_2D_ARRAY, 0, GL_RGBA8, xstep, ystep,
                 256, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glGenerateMipmap(GL_TEXTURE_2D_ARRAY);

    for (ypos = 0; ypos<16 * ystep; ypos += ystep)
        for (xpos = 0; xpos<16 * xstep; xpos += xstep)
        {
            uint32_t* subImage = subImageRGBA8(	(uint32_t*)imageData, w, xpos, ypos, xstep, ystep);
            glTexSubImage3D(GL_TEXTURE_2D_ARRAY, 0, 0, 0, chindex++, xstep, ystep,
                            1, GL_RGBA, GL_UNSIGNED_BYTE, subImage);
            free(subImage);
        }
    free(imageData);
    return arrayTextureId;
}


/*
 * Constructs an OpenGL texture from a file
 */
GLuint
buildTextureFromFile(const char *filePath, GLuint tUnit)
{
    GLuint tex;
    glGenTextures(1, &tex);
    glActiveTexture(GL_TEXTURE0 + tUnit);
    glBindTexture(GL_TEXTURE_2D, tex);

    int w, h, channels;

    size_t length;
    char *p = getAssetPtr(filePath, &length);
    const stbi_uc* buffer = (stbi_uc*) p;
    unsigned char* imageData = stbi_load_from_memory(
            buffer, (int)length, &w, &h, &channels, STBI_rgb_alpha);

    // Order matters! glTexImage2d before glTexParameteri (!)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,
                 w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    free(imageData);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    glGenerateMipmap(GL_TEXTURE_2D);

    return tex;
}


/*
 * Called during model updates
 */
void
updateMatrices(void)
{
    mat4_t m;
    vec3_t v;


    GLfloat fixX=0, fixY=0;
    if (screen.scale<1.0) {
        fixX = -(1.0 - screen.scale) + 0.04;
        fixY = -(1.0 - screen.scale) + 0.3;
    } else {
        fixX = (screen.scale - 1.0) + 0.04;
        fixY = (screen.scale - 1.0) + 0.3;
    }

    screenModelMatrix = m4_identity();
    v = vec3(fixX, fixY, 0.0);
    m = m4_translation(v);
    screenModelMatrix = m4_mul(screenModelMatrix, m);
    //screenModelMatrix = GLKMatrix4Translate( _screenModelMatrix, fixX, fixY, 0.0);
    //v = vec3(screen.scale * viewaspect, screen.scale, screen.scale);
    v = vec3(screen.scale, screen.scale, 1.0);
    m = m4_scaling(v);
    screenModelMatrix = m4_mul(screenModelMatrix, m);

    viewMatrix = m4_identity();
    screenModelViewMatrix = m4_mul(viewMatrix, screenModelMatrix);
    screenModelViewProjectionMatrix = m4_mul(projectionMatrix, screenModelViewMatrix);
}


/*
 * Computes the view frustum for the scene
 */
void
frustum(float *m, int offset,
             float left, float right, float bottom, float top,
             float nearz, float farz)
{
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


/*
 * Constructs a projection matrix for the "Screen" and "Console"
 */
void
setProjectionMatrix(void)
{
    // width and height of viewport to display on (screen dimensions in case of fullscreen rendering)
    float ratio = (float) viewaspect;
    float left = -ratio;
    float right = ratio;
    float bottom = -1.0f;
    float top = 1.0f;
    float nearz = 0.0f;
    float farz = 200.0f;
    frustum((float*)&projectionMatrix, 0, left, right, bottom, top, nearz, farz);
}


/*
 * Builds the program for the "Console"
 */
void
buildConsoleShaderProgram(void)
{
    // Vertex shader, string from textfile
    GLuint  vs = compileShaderFromFile( "Shaders/consoleVs.txt", GL_VERTEX_SHADER );
    // Fragment shader, string from textfile
    GLuint  fs = compileShaderFromFile( "Shaders/consoleFs.txt", GL_FRAGMENT_SHADER );

    glid_console.prog_shader = glCreateProgram();
    glAttachShader(glid_console.prog_shader, vs);
    glAttachShader(glid_console.prog_shader, fs);
    glLinkProgram(glid_console.prog_shader);

    // Vertex shader attributes

    glid_console.attr_vertexOffs = glGetAttribLocation(glid_console.prog_shader, "vertexOffs");
    glid_console.attr_uvChar = glGetAttribLocation(glid_console.prog_shader, "uvChar");
    glid_console.attr_charColor = glGetAttribLocation(glid_console.prog_shader, "charColor");
    glid_console.attr_charData = glGetAttribLocation(glid_console.prog_shader, "charData");

    // Vertex shader uniforms

    glid_console.uni_bgCol =
            glGetUniformLocation(glid_console.prog_shader, "bgcol");
    glid_console.uni_cursorX =
            glGetUniformLocation(glid_console.prog_shader, "cursorx");
    glid_console.uni_cursorY =
            glGetUniformLocation(glid_console.prog_shader, "cursory");
    glid_console.uni_cursorVis =
            glGetUniformLocation(glid_console.prog_shader, "cursorvis");

    glid_console.uni_v_showBg =
            glGetUniformLocation(glid_console.prog_shader, "v_showBg");
    glid_console.uni_v_pixResX =
            glGetUniformLocation(glid_console.prog_shader, "v_pixResX");
    glid_console.uni_v_pixResY =
            glGetUniformLocation(glid_console.prog_shader, "v_pixResY");

    glid_console.uni_viewMatrix =
            glGetUniformLocation(glid_console.prog_shader, "viewMatrix");
    glid_console.uni_modelViewMatrix =
            glGetUniformLocation(glid_console.prog_shader, "modelViewMatrix");
    glid_console.uni_modelViewProjectionMatrix =
            glGetUniformLocation(glid_console.prog_shader,
                                 "modelViewProjectionMatrix");

    // Samplers
    glid_console.uni_arrayTextureSampler =
            glGetUniformLocation(glid_console.prog_shader, "arrayTextureSampler");

    glDeleteShader(vs);
    glDeleteShader(fs);
}


/*
 * Builds the buffer objects for the "Console"
 */
void
buildConsoleVao(void)
{
    // Set up a vertex buffer array

    glGenVertexArrays(1, &glid_console.buf_vao);
    glBindVertexArray(glid_console.buf_vao);

    // Set up the buffer containing the vertices of the base quad

    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);

    GLfloat vertexData[ 6*8 ] =   // 3 vertex offset, 2 tex coordinates
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

    glVertexAttribPointer( (GLuint) glid_console.attr_vertexOffs, 3, GL_FLOAT, GL_FALSE,
                          5*sizeof(GLfloat), (void *)0);
    glEnableVertexAttribArray( (GLuint) glid_console.attr_vertexOffs);

    glVertexAttribPointer( (GLuint) glid_console.attr_uvChar, 2, GL_FLOAT, GL_FALSE,
                          5*sizeof(GLfloat), (void *)12);
    glEnableVertexAttribArray( (GLuint) glid_console.attr_uvChar);


    // Set up the buffer for screen characters

    glGenBuffers(1, &glid_console.buf_vboChars);
    glBindBuffer(GL_ARRAY_BUFFER, glid_console.buf_vboChars);
    glBufferData(GL_ARRAY_BUFFER, sizeof(paverho.screenData),
                 &paverho.screenData,
                 GL_STREAM_DRAW);

    glVertexAttribIPointer( (GLuint)glid_console.attr_charData, 1, GL_UNSIGNED_SHORT,
                           1*sizeof(GL_UNSIGNED_SHORT), (GLvoid*)0 );
    glVertexAttribDivisor( (GLuint)glid_console.attr_charData, 1 ); // Instanced
    glEnableVertexAttribArray( (GLuint)glid_console.attr_charData);


    // Set up the buffer for screen colors

    glGenBuffers(1, &glid_console.buf_vboColors);
    glBindBuffer(GL_ARRAY_BUFFER, glid_console.buf_vboColors);
    glBufferData(GL_ARRAY_BUFFER, sizeof(console.screenColor),
                 &console.screenColor,
                 GL_STREAM_DRAW);

    glVertexAttribPointer( (GLuint)glid_console.attr_charColor, 3, GL_FLOAT,
                          GL_FALSE, 3*sizeof(GL_FLOAT), (GLvoid*)0 );
    glVertexAttribDivisor( (GLuint)glid_console.attr_charColor, 1 ); // Instanced
    glEnableVertexAttribArray( (GLuint)glid_console.attr_charColor);

    glBindVertexArray(0);
}


/*
 * Initialises the "Console"
 */
void
initConsole(void)
{
    buildConsoleShaderProgram();
    buildConsoleVao();
    glid_console.tex_arrayTexture = arrayTextureFromAtlasfile( "sdf_font.png", 3);
}


/*
 * Renders the "Console" in OpenGL
 */
void
renderConsole(void)
{
    glUseProgram(glid_console.prog_shader);

    glUniform1i(glid_console.uni_arrayTextureSampler, 3);

    glUniform3f(glid_console.uni_bgCol, bgColor.x, bgColor.y, bgColor.z);

    glUniform1i(glid_console.uni_cursorX, paverho.cursorX);
    glUniform1i(glid_console.uni_cursorY, paverho.cursorY);
    glUniform1i(glid_console.uni_cursorVis, paverho.cursorVis);

    glUniform1f(glid_console.uni_v_showBg, console.showBg);
    glUniform1f(glid_console.uni_v_pixResX, screen.scale * surface_width);
    glUniform1f(glid_console.uni_v_pixResY, screen.scale * surface_height);

    glUniformMatrix4fv(glid_console.uni_viewMatrix,
                       1, GL_FALSE, (const GLfloat*) &viewMatrix.m );
    glUniformMatrix4fv(glid_console.uni_modelViewMatrix,
                       1, GL_FALSE, (const GLfloat*) &screenModelViewMatrix.m );
    glUniformMatrix4fv(glid_console.uni_modelViewProjectionMatrix,
                       1, GL_FALSE, (const GLfloat*) &screenModelViewProjectionMatrix.m );

    glBindVertexArray(glid_console.buf_vao);

    // Bind array texture to unit 3
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D_ARRAY, glid_console.tex_arrayTexture);

    glDrawArraysInstanced( GL_TRIANGLE_STRIP, 0, 6, 64*32 );
}


/*
 * Builds the OpenGL program for the "Screen"
 */
void
buildScreenShaderProgram(void)
{
    // Vertex shader, string from textfile
    GLuint  vs = compileShaderFromFile( "Shaders/glassVs.txt", GL_VERTEX_SHADER );

    // Fragment shader, string from textfile
    GLuint  fs = compileShaderFromFile( "Shaders/glassFs.txt", GL_FRAGMENT_SHADER );

    glid_screen.prog_shader = glCreateProgram();
    glAttachShader(glid_screen.prog_shader, vs);
    glAttachShader(glid_screen.prog_shader, fs);
    glLinkProgram(glid_screen.prog_shader);

    // Vertex shader attributes

    glid_screen.attr_vertexOffs = (GLuint) glGetAttribLocation(glid_screen.prog_shader, "vertexOffs");
    glid_screen.attr_uvChar =  (GLuint) glGetAttribLocation(glid_screen.prog_shader, "uvChar");

    // Vertex shader uniforms

    glid_screen.uni_bgCol =
            glGetUniformLocation(glid_screen.prog_shader, "bgcol");

    glid_screen.uni_modelViewProjectionMatrix =
            glGetUniformLocation(glid_screen.prog_shader,
                                 "modelViewProjectionMatrix");

    glid_screen.uni_v_diffuseAlpha =
            glGetUniformLocation(glid_screen.prog_shader, "v_diffuseAlpha");

    // Fragment shader uniforms

    // Samplers
    glid_screen.uni_diffuseMapSampler =
            glGetUniformLocation(glid_screen.prog_shader, "diffuse_map");
    glid_screen.uni_inlaySampler =
            glGetUniformLocation(glid_screen.prog_shader, "inlay");
    glid_screen.uni_cubemapSampler =
            glGetUniformLocation(glid_screen.prog_shader, "cubemapSampler");
    glid_screen.uni_skyboxYRot =
            glGetUniformLocation(glid_screen.prog_shader, "skyboxYRot");


    glDeleteShader(vs);
    glDeleteShader(fs);
}



/*
 * Builds the buffer objects for the "Screen" object
 *
 */
void
buildScreenVao(void)
{
    // Set up a vertex buffer array

    glGenVertexArrays(1, &glid_screen.buf_vao);
    glBindVertexArray(glid_screen.buf_vao);

    // Set up the buffer containing the vertices of the base quad

    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);

    float vertexData[ 5*4 ] =   // 2 vertex offsets, 2 tex coordinates
            {
                   -1.0f,  -1.0f,   0.0f, 0.0f,
                    1.0f,  -1.0f,   1.0f, 0.0f,
                    1.0f,   1.0f,   1.0f, 1.0f,
                   -1.0f,   1.0f,   0.0f, 1.0f,
                   -1.0f,  -1.0f,   0.0f, 0.0f
            };

    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData),
                 vertexData, GL_STATIC_DRAW);

    glVertexAttribPointer(glid_screen.attr_vertexOffs, 2, GL_FLOAT, GL_FALSE,
                          4*sizeof(GLfloat), (void *)0);
    glEnableVertexAttribArray(glid_screen.attr_vertexOffs);

    glVertexAttribPointer(glid_screen.attr_uvChar, 2, GL_FLOAT, GL_FALSE,
                          4*sizeof(GLfloat), (void *)8);
    glEnableVertexAttribArray(glid_screen.attr_uvChar);

    glBindVertexArray(0);
}


/*
 * Initializes the "Screen"
 */
void
initScreen(void)
{
    buildScreenShaderProgram();
    buildScreenVao();

    glid_screen.tex_diffuse = buildTextureFromFile( "leaftex1.png", 0);
    glid_screen.tex_cube = getCubeTextureId(1);

    glGenTextures(1, &glid_screen.tex_gfx);
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, glid_screen.tex_gfx);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,
                                256, 256, 0, GL_RGBA, GL_UNSIGNED_BYTE, paverho.gfxRawData);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
}


/*
 * Renders the "Screen", a rectangular region that's overlayed over the "Console"
 */
void
renderScreen(void)
{
    glUseProgram(glid_screen.prog_shader);

    glUniform1i(glid_screen.uni_diffuseMapSampler, 0);
    glUniform1i(glid_screen.uni_cubemapSampler, 1);
    glUniform1i(glid_screen.uni_inlaySampler, 2);
    glUniform3f(glid_screen.uni_bgCol, bgColor.x, bgColor.y, bgColor.z);
    glUniform1f(glid_screen.uni_skyboxYRot, scene.skybox_yRot);
    glUniform1f(glid_screen.uni_v_diffuseAlpha, screen.v_diffuseAlpha);

    glUniformMatrix4fv(glid_screen.uni_modelViewProjectionMatrix, 1, GL_FALSE,
                       (const GLfloat*) &screenModelViewProjectionMatrix.m );

    glBindVertexArray(glid_screen.buf_vao);

    // Bind gfx/diffuse map to texture unit 0
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, glid_screen.tex_diffuse);

    // Bind cube map to unit 1
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_CUBE_MAP, glid_screen.tex_cube);

    // Bind array texture to unit 2
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, glid_screen.tex_gfx);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 5);
}


/*
 * Starts a Paverho thread
 */
void startSonne16( void)
{
    char fname[1024];
    size_t length;
    strcpy(fname, phos_applicationpath);
    strcat(fname, "/card.8T3");
    strcpy(cardFileName, fname);

    FILE* f =  fopen(cardFileName, "r+");
    if (!f){ // Copy to internal storage if missing
        char* p = getAssetPtr("card.8T3", &length);
        f =  fopen(cardFileName, "w"); // Force
        fwrite(p, length, 1, f);
    }
    fclose(f);

    int w, h, channels;
    char *p = getAssetPtr("poppy.png", &length);
    const stbi_uc* buffer = (stbi_uc*) p;
    paverho.gfxRawData = stbi_load_from_memory(
            buffer, (int)length, &w, &h, &channels, STBI_rgb_alpha);

    uint16_t *gpramptr = (uint16_t*) malloc(GP_MAX_ADDR*2);
    paverho_init( gpramptr);

	int blk = 0;
	/* Populate 0-56k non-overlay region */
	for (int i = 0; i < 56 * 4; i++) /* These are 56k cells = 112k bytes = 224 blocks */
		rd_blk_into_ram(blk++, 256 * i, 0); /* Each block fills 256 cells */
	/* Blk now at beginning of overlay region, overlays share 56k-64k */
	for (int ovl = 0; ovl < 4; ovl++) {
		for (int i = 56 * 4; i < 64 * 4; i++) /* Sweep overlay region 56k - 64k for each overlay */
			rd_blk_into_ram(blk++, 256 * i, ovl);
	}

    //rd_blk_range(0,96*2,gpramptr);
    phos_runthread(run);
}


/*
 * Called by the glue layer when the model needs updating, typically once a frame
 */
void
update_model(void)
{
    /* Do the following every time */

    updateMatrices();

     bgColor = vec3((float) (paverho.bgCol >> 11) / 32.0,
                    (float) ((paverho.bgCol >> 5) & 63) / 64.0,
                    (float) ((paverho.bgCol & 31) / 32.0));

     if (scene.yrotIncrement < -0.0001 || scene.yrotIncrement > 0.0001)
            scene.skybox_yRot += scene.yrotIncrement;

    glBindBuffer(GL_ARRAY_BUFFER, glid_console.buf_vboChars);
    glBufferSubData(GL_ARRAY_BUFFER, 0,
                    2048*4, &paverho.screenData[paverho.txtBase & 4095]);

    glBindBuffer(GL_ARRAY_BUFFER, glid_console.buf_vboColors);
    glBufferSubData(GL_ARRAY_BUFFER, 0, 2048*12,
                    &console.screenColor[paverho.txtBase & 4095]);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, glid_screen.tex_gfx );
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0,
                    256, 256, GL_RGBA,
                    GL_UNSIGNED_BYTE, &paverho.gfxRawData[4*(paverho.gfxBase & 128*1024-1)]);
}


/*
 * Called by the OpenGL view for each frame
 */
void
draw_frame(void)
{
    glClearColor(bgColor.x, bgColor.y, bgColor.z, 0.0);
    //glClearColor(0.9, 0.9, 0.2, 0.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    renderScreen();
    renderConsole();
}


/*
 * Called by the glue layer when individual keypresses are not available from the host system
 * and the text input interface has signaled that a line of text has been entered, i.e. the
 * user has pressed ENTER or DONE etc.
 */
void
line_ready(const char* linestr)
{
    size_t size = strlen(linestr) > 1022 ? 1022 : strlen(linestr);
    int i;
    for (i=0; i<size; i++)
        paverho.linebuffer[i] = linestr[i]; /* Error if host to network ! */
    paverho.linebuffer[i] = 10; // Error: htons(10);
    paverho.linebuffer[i+1] = 0;
    paverho.scanCodeReady = 1;
    paverho.idle = 0;
}


/*
 * Called by the host system (via glue layer) for certain events during application startup
 */
void
application_phase(enum Phase phase)
{
    switch (phase)
    {
        case CREATE: /* Create one-time application data */

            __android_log_print(ANDROID_LOG_VERBOSE, "Phos", "CREATE %d ", 0 );

            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_DEPTH_TEST);
            glDepthFunc(GL_LESS);

            setProjectionMatrix();
            updateMatrices();
            glid_screen.tex_cube = getCubeTextureId(0);

            initScreen();
            initConsole();

            scene.yrotIncrement = 0.001;
            screen.v_diffuseAlpha = 0.5;
            screen.scale = screen.lastScale = 1.0;
            console.showBg = 0.0;
            paverho.gfxH = 0; //512;
            paverho.gfxV = 0; //140;
            startSonne16();

            break;

        case RESTORE: /* Initialize or load application state */
            __android_log_print(ANDROID_LOG_VERBOSE, "Phos", "RESTORE %d ", 0 );
            break;

        case PAUSE: /* Switch to standby, be quick */
            __android_log_print(ANDROID_LOG_VERBOSE, "Phos", "PAUSE %d ", 0 );
            break;

        case SAVE: /* Save application state, prepare to exit */
            __android_log_print(ANDROID_LOG_VERBOSE, "Phos", "SAVE %d ", 0 );
            break;

        case EXIT: /* Deallocate stuff */
            __android_log_print(ANDROID_LOG_VERBOSE, "Phos", "EXIT %d ", 0 );
            break;

    }
}


/*
 * Called by Paverho to set the text color array
 */
void
setTextColor( uint16_t offs, uint16_t val)
{
    console.screenColor[offs].r = (float)((float)(val >> 11) / 32.0);
    console.screenColor[offs].g = (float)((float)((val >> 5)&63)/64.0);
    console.screenColor[offs].b = (float)((float)(val & 0b11111)/32.0);
}


/*
* Read n contiguous 512-byte-blocks from sdcard image into a buffer
* Each block 256 uint16_t, network byte order
*/
int
rd_blk_range(int bstart, int blocks, uint16_t *buffer)
{
	uint16_t w;
	FILE *f;
	f = fopen(cardFileName, "rb+");
	if (f == NULL) return -1;
	fseek(f, 512 * bstart, SEEK_SET);
	for (size_t i = 0; i < 256 * blocks; i++) {
		fread(&w, 2, 1, f);
		buffer[i] = ntohs(w);
	}
	fclose(f);
	return 0;
}


/*
* Write n contiguous 512-byte-blocks from a buffer to the sdcard image
* Each block 256 uint16_t, network byte order
*/
int
wr_blk_range(int bstart, int blocks, uint16_t *buffer)
{
	uint16_t w;
	FILE *f;
	f = fopen(cardFileName, "rb+");
	if (f == NULL) return -1;
	fseek(f, 512 * bstart, SEEK_SET);
	for (size_t i = 0; i < 256 * blocks; i++) {
		w = htons(buffer[i]);
		fwrite(&w, 2, 1, f);
	}
	fclose(f);
	return 0;
}


