//
//  MIM_OpenGLView.m
//  Phos
//
//  Created by Michael on 26.01.18.
//  Copyright © 2018 Michael Mangelsdorf. All rights reserved.
//

#import "MIM_OpenGLView.h"


struct { // State variables for paver emulator
    
    uint16_t scanCodeReady;
    uint16_t keyCode;
    uint16_t idle;
    uint16_t cursorVis;
    uint16_t cursorX, cursorY;
    uint16_t bgCol;
    uint16_t txtBase;
    uint16_t gfxBase;
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


@implementation MIM_OpenGLView


///////////////////////////////////////////////////////////////////////////////

- (BOOL) acceptsFirstResponder { return YES; }

///////////////////////////////////////////////////////////////////////////////

- (void) viewDidMoveToWindow
{
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(windowResized:)
     name:NSWindowDidResizeNotification
     object:[self window]];
}

///////////////////////////////////////////////////////////////////////////////

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

///////////////////////////////////////////////////////////////////////////////

- (void) windowResized:(NSNotification *) notification {
    [self adjustProjection];
}

///////////////////////////////////////////////////////////////////////////////

- (void) prepareOpenGL
{
    NSOpenGLPixelFormatAttribute pixelFormatAttributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFADepthSize, 32,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        0
    };
    
    NSOpenGLPixelFormat *pixelFormat =
        [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes];
    
    super.pixelFormat = pixelFormat;
    
    // Synchronize buffer swaps with vertical refresh rate (enable VSYNC)
    GLint swapInt = 1;
    
    [[self openGLContext]
        setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    [[self openGLContext] makeCurrentContext];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
}

///////////////////////////////////////////////////////////////////////////////


- (void) adjustProjection {
    
    NSView *contentView = [[self window] contentView];
    NSSize size = contentView.bounds.size;
    
    [self.window setContentAspectRatio:NSMakeSize(size.width, size.height)];
    
    glViewport(0, 0, size.width, size.height);
    _viewAspect = fabs(size.width / size.height);
    
    _projectionMatrix = GLKMatrix4MakePerspective(
      GLKMathDegreesToRadians(80.0f), _viewAspect, 0.01f, 200.0f );
}


///////////////////////////////////////////////////////////////////////////////

- (void) timerFired:(id)sender {
    
    // Bind the VAO to draw. Bind the VBO to modify the VBO.
    _bgColor = GLKVector4Make((float)(paver.bgCol>>11)/32.0,
                             (float)((paver.bgCol>>5)&63)/64.0,
                             (float)((paver.bgCol&31)/32.0),
                              1.0);
    
    glBindBuffer(GL_ARRAY_BUFFER, glid_screen.buf_vboChars);
    glBufferSubData(GL_ARRAY_BUFFER, 0,
                    4096*4, &paver.screenData[paver.txtBase]);

    glBindBuffer(GL_ARRAY_BUFFER, glid_screen.buf_vboColors);
    glBufferSubData(GL_ARRAY_BUFFER, 0, 4096*12,
                    &paver.screenColor[paver.txtBase]);
   
    glActiveTexture(GL_TEXTURE0 + 0); // GFX/diffuse texture
    glBindTexture(GL_TEXTURE_2D, glid_screen.tex_GFX );
    glTexSubImage2D(GL_TEXTURE_2D, 0,
                    paver.gfxH % (1024-256),
                    paver.gfxV % (768-256),
                    256, 256, GL_RGBA,
    GL_UNSIGNED_BYTE, &gfxRawData[4*(paver.gfxBase & 128*1024-1)]);
    
    
    scene.skybox_yRot += 0.00001;
    
    [self setNeedsDisplay:YES];
}

///////////////////////////////////////////////////////////////////////////////

- (void) cancelOperation:(id)sender // Escape key
{	
    _showFlag = 1 - _showFlag;
}

- (void) keyDown:(NSEvent *)event
{
        int key = (int)[[event characters] characterAtIndex:0];
    //  NSLog(@"Key:%d",key);
        switch(key) {
        
            case 13:                        key = 10; break;    // Enter
            case 127:                       key = 8; break;     // Backspace
            case 63272:                     key = 127; break;   // Del
            case 63234:                     key = 12; break;    // Left
            case 63235:                     key = 14; break;    // Right
            case 63232:                     key = 6; break;     // Up
            case 63233:                     key = 11; break;    // Down
            case 63276:                     key = 4; break;     // PgUp
            case 63277:                     key = 5; break;     // PgDn
                
            case 63273:                     key = 5; break;     // Home
            case 9:                         key = 1; break;     // Ins missing ins key use TAB
         // Shift Del    29!
                
         //   case VK_END:
         //       getClipText();
         //       paver.clipReady = 1;
         //       paver.keyCode = 3;
         //       break;
                
            case 63236:                     key = 16; break;    // F1
            case 63237:                     key = 17; break;    // F2
            case 63238:                     key = 18; break;    // F3
            case 63239:                     key = 19; break;    // F4
            case 63240:                     key = 20; break;    // F5
            case 63241:                     key = 21; break;    // F6
            case 63242:                     key = 22; break;    // F7
            case 63243:                     key = 23; break;    // F8
                
           // case 62:                        key = 15; break;
           // case 60:                        key = 31; break;
           // case 93:                        key = 34; break;
           // case 64:                        key = 35; break;
           // case 47:                        key = 38; break;
           // case 41:                        key = 40; break;
           // case 61:                        key = 41; break;
           // case 40:                        key = 42; break;
           // case 96:                        key = 43; break;
           // case 59:                        key = 44; break;
           // case 58:                        key = 46; break;
           // case 95:                        key = 47; break;
        }
    
 //    if ( (wParam != VK_SHIFT) || (paver.keyCode == 29)) {
    paver.scanCodeReady = 1;
    paver.keyCode = key;
    paver.idle = 0;
    
   // [self interpretKeyEvents:[NSArray arrayWithObject:event]];
    [super keyDown:event];
}

///////////////////////////////////////////////////////////////////////////////

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    //actualFramesPerSecond
    // = 1 / (displaylink.targetTimestamp - displaylink.timestamp)
    [self updateMatrices];
    glClearColor(0.3*_bgColor.r, 0.3*_bgColor.g, 0.3*_bgColor.b, _bgColor.a);
   // glClearColor(1.0, 1.0, 1.0, 1.0);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if (_showFlag) [self renderSkybox];
    // Shader don't manipulate z/w, must render skybox first
    // glClear( GL_DEPTH_BUFFER_BIT);
    [self renderScreen];
    [[self openGLContext] flushBuffer];
}

///////////////////////////////////////////////////////////////////////////////

- (void) awakeFromNib
{
    //[self setAlphaValue: 0.9];
    //[[self window] setBackgroundColor:[NSColor clearColor]];
    //[[self window] setOpaque:NO];
    // [self window].styleMask |= NSFullSizeContentViewWindowMask;
    // [self window].titlebarAppearsTransparent = true;
    
    [self prepareOpenGL];
    
    [self adjustProjection];
    [self initSkyBox];
    [self initScreenModel];
    
    _viewMatrix = GLKMatrix4Identity;
    
    _bgColor = GLKVector4Make(0.0, 0.0, 0.5, 1.0);
    screen.scale = 6.5; //= 7.13;
    
    _renderTimer = [NSTimer timerWithTimeInterval:0.05  // Number of seconds
                                           target:self
                                         selector:@selector(timerFired:)
                                         userInfo:nil
                                          repeats:YES];
    
    [[NSRunLoop currentRunLoop]
        addTimer:_renderTimer forMode:NSDefaultRunLoopMode];
    
    //Ensure timer fires during resize
    [[NSRunLoop currentRunLoop]
        addTimer:_renderTimer forMode:NSEventTrackingRunLoopMode];
    
    [[self window] setAcceptsMouseMovedEvents:YES];
    
    paver.gfxH = 512;
    paver.gfxV = 140;
    
    [self startSonne16];
  //  [self randomScreen];
    
}

///////////////////////////////////////////////////////////////////////////////



- (void)mouseMoved:(NSEvent *)theEvent {
    NSPoint windowOrigin;
    NSWindow *window = [self window];
    windowOrigin = [window frame].origin;
    scene.xlight += theEvent.deltaX / 30;
    scene.ylight -= theEvent.deltaY / 30;
    
    if (scene.xlight>30) scene.xlight = 30;
    if (scene.xlight<-30) scene.xlight = -30;
    if (scene.ylight>30) scene.ylight = 30;
    if (scene.ylight<-30) scene.ylight = -30;
}

///////////////////////////////////////////////////////////////////////////////

- (void)mouseDragged:(NSEvent *)theEvent {
    NSPoint windowOrigin;
    NSWindow *window = [self window];
    windowOrigin = [window frame].origin;
    float dx = theEvent.deltaX / 20;
    float dy = theEvent.deltaY / 20;
    if ((dx<0 && scene.yrot < 2) || (dx>0 && scene.yrot > -2)) scene.yrot -= dx;
    if ((dy<0 && scene.xrot < 2) || (dy>0 && scene.xrot > -2)) scene.xrot -= dy;
}

///////////////////////////////////////////////////////////////////////////////

- (void) FPSViewRH:(GLKMatrix4*)matrix // First person view from
               eye:(GLKVector3)eye pitch:(float)pitch yaw:(float)yaw;
{
    
//    [self FPSViewRH: &(_viewMatrix)
//                eye: GLKVector3Make(0, 0, 0)
//              pitch: scene.xrotSky
//                yaw: scene.yrotSky ];
    
    // Pitch and yaw angles in radians
    float cosPitch = cos(pitch);
    float sinPitch = sin(pitch);
    float cosYaw = cos(yaw);
    float sinYaw = sin(yaw);
    
    GLKVector3 xaxis = { cosYaw, 0, -sinYaw };
    GLKVector3 yaxis = { sinYaw * sinPitch, cosPitch, cosYaw * sinPitch };
    GLKVector3 zaxis = { sinYaw * cosPitch, -sinPitch, cosPitch * cosYaw };
    
    *matrix = GLKMatrix4MakeWithColumns(
        GLKVector4Make(   xaxis.x,  yaxis.x,   zaxis.x,      0 ),
        GLKVector4Make(   xaxis.y,  yaxis.y,   zaxis.y,      0 ),
        GLKVector4Make(   xaxis.z,  yaxis.z,   zaxis.z,      0 ),
        GLKVector4Make(  -GLKVector3DotProduct( xaxis, eye ),
                         -GLKVector3DotProduct( yaxis, eye ),
                         -GLKVector3DotProduct( zaxis, eye ), 1 )
    );
}

///////////////////////////////////////////////////////////////////////////////

- (void) updateMatrices
{
    _screenModelMatrix = GLKMatrix4Identity;
    _screenModelMatrix = GLKMatrix4RotateZ(_screenModelMatrix,
                        GLKMathDegreesToRadians(screen.zrot));
    _screenModelMatrix = GLKMatrix4RotateX(_screenModelMatrix,
                        GLKMathDegreesToRadians(screen.xrot));
    _screenModelMatrix = GLKMatrix4RotateY(_screenModelMatrix,
                        GLKMathDegreesToRadians(screen.yrot));
    _screenModelMatrix = GLKMatrix4Translate( _screenModelMatrix,
                  screen.xtransl, screen.ytransl, screen.ztransl-10);
    _screenModelMatrix = GLKMatrix4Scale(_screenModelMatrix,
                    screen.scale * _viewAspect, screen.scale, screen.scale);
    
    _viewMatrix = GLKMatrix4Identity;
    _viewMatrix = GLKMatrix4RotateX(_viewMatrix,
                                    GLKMathDegreesToRadians(scene.xrot));
    _viewMatrix = GLKMatrix4RotateY(_viewMatrix,
                                    GLKMathDegreesToRadians(scene.yrot));
    _viewMatrix = GLKMatrix4RotateZ(_viewMatrix,
                                    GLKMathDegreesToRadians(scene.zrot));
    _viewMatrix = GLKMatrix4Translate(_viewMatrix, 0, 0, 0);
    
    _screenModelViewMatrix =
        GLKMatrix4Multiply(_viewMatrix, _screenModelMatrix);
    
    _screenModelViewProjectionMatrix =
        GLKMatrix4Multiply(_projectionMatrix, _screenModelViewMatrix);
}

///////////////////////////////////////////////////////////////////////////////

- (GLuint) compileShaderFromFile:(NSString*)path shaderType:(GLenum)shaderType
{
    GLuint shaderId;
    NSString *content =
        [NSString stringWithContentsOfFile:path
                encoding:NSUTF8StringEncoding error:nil];
    
    const char *shaderSrc =
        [content cStringUsingEncoding:NSISOLatin1StringEncoding];
    
    shaderId = glCreateShader(shaderType);
    glShaderSource(shaderId, 1, &shaderSrc, NULL);
    glCompileShader(shaderId);
    GLint shaderStatus;
    glGetShaderiv(shaderId, GL_COMPILE_STATUS, &shaderStatus);
    if (shaderStatus != GL_TRUE)
    {
        NSLog(@"shader compile error");
        GLchar messages[256];
        glGetShaderInfoLog(shaderId, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    return shaderId;
}

///////////////////////////////////////////////////////////////////////////////

- (CGImageRef) textureFileImageRef:(NSString*)filePath
{
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:filePath];
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    CGRect imageCGRect = CGRectMake(0, 0, image.size.width, image.size.height);
    NSRect imageRect = NSRectFromCGRect(imageCGRect);
    return [image CGImageForProposedRect:&imageRect context:context hints:nil];
}

///////////////////////////////////////////////////////////////////////////////

- (CFDataRef) textureFileData:(NSString*)filePath {

    CFDataRef rawData;
    CGImageRef imageRef = [self textureFileImageRef:filePath];
    rawData = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    return rawData;
    // Use (UInt8*) CFDataGetBytePtr(rawData)
}

///////////////////////////////////////////////////////////////////////////////

- (GLuint) arrayTextureFromAtlasfile:(NSString*)filePath
        forTextureUnit:(GLuint)tu {
    
    int xstep=9, ystep=16, xpos=0, ypos=0, chindex=0;
    CGImageRef atlasRef = [self textureFileImageRef:filePath];
    CGImageRef subImage;
    CFDataRef rawData;
    
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
    
    for (ypos=0; ypos<16*ystep; ypos+=ystep)
        for (xpos=0; xpos<16*xstep; xpos+=xstep)
        {
            subImage = CGImageCreateWithImageInRect(
                        atlasRef,CGRectMake(xpos,ypos,xstep,ystep));
            rawData = CGDataProviderCopyData(CGImageGetDataProvider(subImage));
            glTexSubImage3D(GL_TEXTURE_2D_ARRAY, 0, 0, 0, chindex++,
                            xstep, ystep, 1, GL_RGBA, GL_UNSIGNED_BYTE,
                            (UInt8*) CFDataGetBytePtr(rawData));
            CFRelease(rawData);
            CGImageRelease(subImage);
        }
    // CGImageRelease(atlasRef);  When? This segfaults...
    return arrayTextureId;
}

///////////////////////////////////////////////////////////////////////////////

- (CFStringRef) pathToBundle
{
    // Even easier:  appdir = [[[NSBundle mainBundle] bundlePath] UTF8String];
    CFBundleRef mainBundle;
    mainBundle = CFBundleGetMainBundle();
    CFURLRef resourcesURL = CFBundleCopyBundleURL(mainBundle);
    CFStringRef str = CFURLCopyFileSystemPath( resourcesURL,
                                    kCFURLPOSIXPathStyle );
    CFRelease(resourcesURL);
    return str;
}

///////////////////////////////////////////////////////////////////////////////

- (GLKMatrix4) getNormalMatrixFor:(GLKMatrix4)srcMatrix // No translation
{
    bool invertible;
    GLKMatrix4 normalMatrix;
    normalMatrix = GLKMatrix4InvertAndTranspose(srcMatrix, &invertible);
    if(!invertible) { NSLog(@"Matrix not invertible"); exit(1); }
    return normalMatrix;
}

///////////////////////////////////////////////////////////////////////////////

- (GLuint) getCubeTextureId:(GLuint)textureUnit
{
    GLuint textureId;
    glActiveTexture(GL_TEXTURE0 + textureUnit);
    glGenTextures(1, &textureId);
    glBindTexture(GL_TEXTURE_CUBE_MAP, textureId);
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL_RGBA, 2048, 2048, 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE, (UInt8*) CFDataGetBytePtr(_nz));
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL_RGBA, 2048, 2048, 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE, (UInt8*) CFDataGetBytePtr(_pz));
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL_RGBA, 2048, 2048, 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE, (UInt8*) CFDataGetBytePtr(_py));
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL_RGBA, 2048, 2048, 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE, (UInt8*) CFDataGetBytePtr(_ny));
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL_RGBA, 2048, 2048, 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE, (UInt8*) CFDataGetBytePtr(_nx));
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL_RGBA, 2048, 2048, 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE, (UInt8*) CFDataGetBytePtr(_px));
    
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    return textureId;
}

///////////////////////////////////////////////////////////////////////////////

- (GLuint) buildTextureFromFile:(NSString*)filePath forTextureUnit:(GLuint)tUnit
{
    GLuint tex;
    glGenTextures(1, &tex);
    glActiveTexture(GL_TEXTURE0 + tUnit);
    glBindTexture(GL_TEXTURE_2D, tex);
    
    CFDataRef rawData;
    UInt8* gfxRawData;
    
    CGImageRef imageRef = [self textureFileImageRef:filePath];
    rawData = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    gfxRawData = (UInt8*) CFDataGetBytePtr(rawData);

    // Order matters! glTexImage2d before glTexParameteri (!)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,
                 (GLsizei) CGImageGetWidth(imageRef),
                 (GLsizei) CGImageGetHeight(imageRef), 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, gfxRawData);
    CFRelease(rawData);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    glGenerateMipmap(GL_TEXTURE_2D);
    
    return tex;
}



///////////////////////////////////////////////////////////////////////////////
//
//      SKYBOX STUFF
//
///////////////////////////////////////////////////////////////////////////////

- (void) initSkyBox
{
        _nx  = [self textureFileData:[[NSBundle mainBundle]
                                      pathForResource:@"nx" ofType:@"png"]];
        _ny  = [self textureFileData:[[NSBundle mainBundle]
                                      pathForResource:@"ny" ofType:@"png"]];
        _nz  = [self textureFileData:[[NSBundle mainBundle]
                                      pathForResource:@"nz" ofType:@"png"]];
        _px  = [self textureFileData:[[NSBundle mainBundle]
                                      pathForResource:@"px" ofType:@"png"]];
        _py  = [self textureFileData:[[NSBundle mainBundle]
                                      pathForResource:@"py" ofType:@"png"]];
        _pz  = [self textureFileData:[[NSBundle mainBundle]
                                      pathForResource:@"pz" ofType:@"png"]];
        
      //  [self buildSkyboxShaderProgram];
        [self initSkyboxVertexData];
    glid_skybox.tex_cube = [self getCubeTextureId: 0];
}

///////////////////////////////////////////////////////////////////////////////

- (void) initSkyboxVertexData
{
    // 6 Faces, 2 triangles per face
    // Winding order: front faces of cube towards inside
    
    GLfloat cubeStrip[] = {
        -100.0f, 100.0f, 100.0f,     // Front-top-left
        100.0f, 100.0f, 100.0f,      // Front-top-right
        -100.0f, -100.0f, 100.0f,    // Front-bottom-left
        100.0f, -100.0f, 100.0f,     // Front-bottom-right
        100.0f, -100.0f, -100.0f,    // Back-bottom-right
        100.0f, 100.0f, 100.0f,      // Front-top-right
        100.0f, 100.0f, -100.0f,     // Back-top-right
        -100.0f, 100.0f, 100.0f,     // Front-top-left
        -100.0f, 100.0f, -100.0f,    // Back-top-left
        -100.0f, -100.0f, 100.0f,    // Front-bottom-left
        -100.0f, -100.0f, -100.0f,   // Back-bottom-left
        100.0f, -100.0f, -100.0f,    // Back-bottom-right
        -100.0f, 100.0f, -100.0f,    // Back-top-left
        100.0f, 100.0f, -100.0f      // Back-top-right
    };
    
    glGenVertexArrays(1, &glid_skybox.buf_vao);
    glBindVertexArray(glid_skybox.buf_vao);
    
    glGenBuffers(1, &glid_skybox.buf_vao);
    glBindBuffer(GL_ARRAY_BUFFER, glid_skybox.buf_vao);
    glBufferData(GL_ARRAY_BUFFER, 3 * 14 * sizeof(float),
                 &cubeStrip, GL_STATIC_DRAW);
    
    glVertexAttribPointer(glid_skybox.attr_pos, 3, GL_FLOAT, GL_FALSE,
                          sizeof(float) * 3, (void*)(sizeof(float) * 0));
    glEnableVertexAttribArray(glid_skybox.attr_pos);
}

///////////////////////////////////////////////////////////////////////////////

- (void) buildSkyboxShaderProgram
{
    // Vertex shader, string from textfile
    GLuint  vs = [self compileShaderFromFile:[[NSBundle mainBundle]
                            pathForResource:@"skyboxVs"
                            ofType:@"txt"] shaderType:GL_VERTEX_SHADER ];
    
    // Fragment shader, string from textfile
    GLuint  fs = [self compileShaderFromFile:[[NSBundle mainBundle]
                            pathForResource:@"skyboxFs"
                            ofType:@"txt"] shaderType:GL_FRAGMENT_SHADER ];
    
    glid_skybox.prog_shader = glCreateProgram();
    glAttachShader(glid_skybox.prog_shader, vs);
    glAttachShader(glid_skybox.prog_shader, fs);
    glBindFragDataLocation(glid_skybox.prog_shader, 0, "fsFragColor");
    glLinkProgram(glid_skybox.prog_shader);
    
    glid_skybox.attr_pos =
    glGetAttribLocation(glid_skybox.prog_shader, "vsPos");
    glid_skybox.uni_cubemapSampler =
    glGetAttribLocation(glid_skybox.prog_shader, "cubemapSampler");
    glid_skybox.uni_skyboxMatrix =
    glGetUniformLocation(glid_skybox.prog_shader, "viewMatrix");
    
    glid_skybox.uni_hRot =
    glGetUniformLocation(glid_skybox.prog_shader, "skyboxHRot");
    
    glDeleteShader(vs);
    glDeleteShader(fs);
}

///////////////////////////////////////////////////////////////////////////////

- (void) renderSkybox
{
    GLint OldCullFaceMode;
    glGetIntegerv(GL_CULL_FACE_MODE, &OldCullFaceMode);
    GLint OldDepthFuncMode;
    glGetIntegerv(GL_DEPTH_FUNC, &OldDepthFuncMode);
    
    glDisable(GL_CULL_FACE);
    glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);
    
    glUseProgram(glid_skybox.prog_shader);

    glUniform1f(glid_skybox.uni_hRot, scene.skybox_yRot);
    
    // Remove translation from skyboxMatrix to center at origin (!)
    GLKMatrix4 mat = GLKMatrix4Multiply(_projectionMatrix, _viewMatrix);
    glUniformMatrix4fv( glid_skybox.uni_skyboxMatrix,
                       1, GL_FALSE, mat.m );
    
    glUniform1i(glid_skybox.uni_cubemapSampler, 0);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_CUBE_MAP, glid_skybox.tex_cube);
    //glBindSampler(0, SamplerHandle);   Samplers are yet separate things
    
    glBindVertexArray(glid_skybox.buf_vao);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 14);
    
    glCullFace(OldCullFaceMode);
    glDepthFunc(OldDepthFuncMode);
}



///////////////////////////////////////////////////////////////////////////////
//
//      SCREEN STUFF
//
///////////////////////////////////////////////////////////////////////////////



- (void) initScreenModel
{
    [self buildScreenShaderProgram];
    [self buildScreenVao];
    
    NSString *filePath = [[NSBundle mainBundle]
                          pathForResource:@"VGA9x16" ofType:@"tga"];
        glid_screen.tex_arrayTexture =
        [self arrayTextureFromAtlasfile:filePath forTextureUnit:3];

    filePath = [[NSBundle mainBundle]
                pathForResource:@"poppy" ofType:@"tga"];
    gfxRawData = (UInt8*) CFDataGetBytePtr( [self textureFileData:filePath] );
    
        glid_screen.tex_GFX =
            [self buildTextureFromFile:
                [[NSBundle mainBundle]
                    pathForResource:@"leaftex1" ofType:@"png"]
                        forTextureUnit: 0 ];
    
        glid_screen.tex_normal = [self buildTextureFromFile:
                [[NSBundle mainBundle]
                    pathForResource:@"leaftex1_NRM" ofType:@"png"]
                        forTextureUnit: 2 ];
    
        glid_screen.tex_cube = [self getCubeTextureId: 1];
}

///////////////////////////////////////////////////////////////////////////////

- (void) buildScreenShaderProgram
{
    // Vertex shader, string from textfile
    GLuint  vs = [self compileShaderFromFile:[[NSBundle mainBundle]
                    pathForResource:@"glassVs" ofType:@"txt"]
                    shaderType:GL_VERTEX_SHADER ];
    // Fragment shader, string from textfile
    GLuint  fs = [self compileShaderFromFile:[[NSBundle mainBundle]
                    pathForResource:@"glassFs" ofType:@"txt"]
                    shaderType:GL_FRAGMENT_SHADER ];
    
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

- (void) buildScreenVao
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
    
    glVertexAttribPointer(glid_screen.attr_vertexOffs, 3, GL_FLOAT, GL_FALSE,
                          5*sizeof(GLfloat), (void *)0);
    glEnableVertexAttribArray(glid_screen.attr_vertexOffs);
    
    glVertexAttribPointer(glid_screen.attr_uvChar, 2, GL_FLOAT, GL_FALSE,
                          5*sizeof(GLfloat), (void *)12);
    glEnableVertexAttribArray(glid_screen.attr_uvChar);
    
    
    // Set up the buffer for screen characters
    
    glGenBuffers(1, &glid_screen.buf_vboChars);
    glBindBuffer(GL_ARRAY_BUFFER, glid_screen.buf_vboChars);
    glBufferData(GL_ARRAY_BUFFER, sizeof(paver.screenData),
                 &paver.screenData,
                 GL_STREAM_DRAW);
    
    glVertexAttribIPointer(glid_screen.attr_charData, 1, GL_UNSIGNED_SHORT,
                1*sizeof(GL_UNSIGNED_SHORT), (GLvoid*)0 );
    glVertexAttribDivisor(glid_screen.attr_charData, 1 ); // Instanced
    glEnableVertexAttribArray(glid_screen.attr_charData);

    
    // Set up the buffer for screen colors
    
    glGenBuffers(1, &glid_screen.buf_vboColors);
    glBindBuffer(GL_ARRAY_BUFFER, glid_screen.buf_vboColors);
    glBufferData(GL_ARRAY_BUFFER, sizeof(paver.screenColor),
                 &paver.screenColor,
                 GL_STREAM_DRAW);
    
    glVertexAttribPointer(glid_screen.attr_charColor, 3, GL_FLOAT,
                          GL_FALSE, 3*sizeof(GL_FLOAT), (GLvoid*)0 );
    glVertexAttribDivisor(glid_screen.attr_charColor, 1 ); // Instanced
    glEnableVertexAttribArray(glid_screen.attr_charColor);
    
    glBindVertexArray(0);
}

///////////////////////////////////////////////////////////////////////////////

- (void) renderScreen
{
    glUseProgram(glid_screen.prog_shader);
    
    glUniform1i(glid_screen.uni_diffuseMapSampler, 0);
    glUniform1i(glid_screen.uni_cubemapSampler, 1);
    glUniform1i(glid_screen.uni_normalMapSampler, 2);
    glUniform1i(glid_screen.uni_arrayTextureSampler, 3);

    glUniform3f(glid_screen.uni_bgCol, _bgColor.r, _bgColor.g, _bgColor.b);
    
    glUniform1i(glid_screen.uni_cursorX, paver.cursorX);
    glUniform1i(glid_screen.uni_cursorY, paver.cursorY);
    glUniform1i(glid_screen.uni_cursorVis, paver.cursorVis);

    glUniform1f(glid_screen.uni_skyboxYRot, scene.skybox_yRot);
    
    glUniformMatrix4fv(glid_screen.uni_viewMatrix, 1, GL_FALSE,
                       _viewMatrix.m );
    glUniformMatrix4fv(glid_screen.uni_modelViewMatrix, 1, GL_FALSE,
                       _screenModelViewMatrix.m );
    glUniformMatrix4fv(glid_screen.uni_modelViewProjectionMatrix, 1, GL_FALSE,
                       _screenModelViewProjectionMatrix.m );
    
    glUniform4f(glid_screen.uni_lightPosition,
                scene.xlight, scene.ylight, scene.zlight+2, 1.0);
    
    glUniform4f(glid_screen.uni_lightDiffuse, 1.0, 1.0, 1.0, 1.0);
    glUniform4f(glid_screen.uni_materialDiffuse, 1.0, 1.0, 1.0, 1.0);
    glUniform4f(glid_screen.uni_lightSpecular, 0.9, 0.9, 0.9, 1.0);
    glUniform4f(glid_screen.uni_materialSpecular, 0.9, 0.9, 0.9, 1.0);
    glUniform1f(glid_screen.uni_materialGloss, 32.0);
    
    //  glUniform1f(_uLightConstant, 1.0);
    //  glUniform1f(_uLightLinear, 0.7);
    //  glUniform1f(_uLightQuadratic, 1.8);

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

    glDrawArraysInstanced( GL_TRIANGLE_STRIP, 0, 6, 128*32 );
}



///////////////////////////////////////////////////////////////////////////////
//
//      POPPY STUFF
//
///////////////////////////////////////////////////////////////////////////////


- (void) startSonne16
{
    // Check if card.8T3 present in Downloads, else copy default from bundle
    // 8T3.asm access also relative to Downloads
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(
                                NSDownloadsDirectory, NSUserDomainMask, YES);
    NSString* downloadFolderPath = paths[0]; // if [paths count] > 0
    strcpy(pavMacPath, downloadFolderPath.UTF8String );
    NSString* filePath = [NSString stringWithFormat:@"%@/%@",
                          downloadFolderPath, @"card.8T3"];
    
    BOOL isPresent = [fileManager fileExistsAtPath:filePath];
    if (!isPresent)
    {
        NSURL *srcURL = [[NSBundle mainBundle]
                         URLForResource:@"card" withExtension:@"8T3"];
        NSURL *dstURL = [NSURL fileURLWithPath:filePath];
        NSError *error;
        [fileManager copyItemAtURL:srcURL toURL:dstURL error:&error];
        // NSLog(@"Copy error: %@", error);
    }
    
    setCardFileName(  filePath.UTF8String );
    xferboot( filePath.UTF8String );
    emulatorQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
    dispatch_async(emulatorQueue, ^{
        run();
        dispatch_async(dispatch_get_main_queue(), ^{
            [self quitApp];
        });
    });
}

///////////////////////////////////////////////////////////////////////////////

- (void) quitApp
{
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

///////////////////////////////////////////////////////////////////////////////

- (void) randomScreen
{
    for (int i=0; i<128*32; i++) {
        paver.screenColor[i].r =  1.0 / (GLfloat) (rand() % 10);
        paver.screenColor[i].g =  1.0 / (GLfloat) (rand() % 10);
        paver.screenColor[i].b =  1.0 / (GLfloat) (rand() % 10);
        paver.screenData[i] = rand() % 255;
    }
}

///////////////////////////////////////////////////////////////////////////////

@end



