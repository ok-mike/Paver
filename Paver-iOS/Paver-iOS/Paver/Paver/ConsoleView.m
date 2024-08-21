//
//  OpenGLView.m
//  Phos-iOS
//
//  Created by Michael on 05.02.18.
//  Copyright © 2018 Michael Mangelsdorf. All rights reserved.
//

#import "ConsoleView.h"

#include "paverho.h"

struct mim_glmenu_t *menu;

dispatch_queue_t emulatorQueue;
char pavMacPath[1024];
uint8_t* gfxRawData;


GLfloat rdist(GLfloat x, GLfloat y) {
    return sqrt( (32.0 - x) * ( 32.0 - x ) +  (16.0 - y) * (16.0 - y) );
    // range 0 - 35.77
}

extern struct paverho_state_t paverho;

void sendPaverhoChar( char keycode)
{
    paverho.keyCode = keycode;
    paverho.scanCodeReady = 1;
    paverho.idle = 0;
    while (paverho.scanCodeReady) ;
}

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
    
    GLfloat uni_v_diffuseAlpha;
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

struct {
    
    GLfloat xrot, yrot, zrot;
    GLfloat xtransl, ytransl, ztransl;
    GLfloat scale, lastScale;
    GLfloat showBg;
    GLfloat* data;
    
} console;

struct {
    
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
    
    GLuint uni_v_showBg;
    GLuint uni_v_pixResX;
    GLuint uni_v_pixResY;
    
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
    
} glid_console;

struct { // These are OpenGL handles for the skybox
    
    GLuint buf_vao;
    
    GLuint prog_shader;
    
    GLuint attr_pos;
    
    GLuint uni_skyboxMatrix;
    GLuint uni_cubemapSampler;
    GLfloat uni_hRot;
    
    GLuint tex_cube;
    
} glid_skybox;






@implementation ConsoleView

- (BOOL) acceptsFirstResponder { return YES; }



- (void) frameUpdate
{
    [self updateMatrices];    
    
    // Bind the VAO to draw. Bind the VBO to modify the VBO.
    _bgColor = GLKVector4Make((float)(paverho.bgCol>>11)/32.0,
                              (float)((paverho.bgCol>>5)&63)/64.0,
                              (float)((paverho.bgCol&31)/32.0),
                              1.0);
    
//    if (scene.yrotIncrement >0) scene.yrotIncrement -= 0.0000001;
//    if (scene.yrotIncrement <0) scene.yrotIncrement += 0.0000001;
    if (scene.yrotIncrement < -0.0001 || scene.yrotIncrement > 0.0001)
        scene.skybox_yRot += scene.yrotIncrement;
    
    glBindBuffer(GL_ARRAY_BUFFER, glid_console.buf_vboChars);
    glBufferSubData(GL_ARRAY_BUFFER, 0,
                    2048*4, &paverho.screenData[paverho.txtBase & 4095]);
    
    glBindBuffer(GL_ARRAY_BUFFER, glid_console.buf_vboColors);
    glBufferSubData(GL_ARRAY_BUFFER, 0, 2048*12,
                    &paverho.screenColor[paverho.txtBase & 4095]);
    
    glActiveTexture(GL_TEXTURE0 + 0); // GFX/diffuse texture
    glBindTexture(GL_TEXTURE_2D, _tex_GFX );
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0,
                    256, 256, GL_RGBA,
                    GL_UNSIGNED_BYTE, &gfxRawData[4*(paverho.gfxBase & 128*1024-1)]);
    
    //    menu.frame_n++;
    //    char str[80];
    //    sprintf(str,"%d         ", menu.frame_n);
    //    mim_glmenu_text(5,11,0,2,&myHoverFunc2,NULL,str);
}


- (void)frameDraw:(CGRect)rect
{
    //   _currentRotation += displayLink.duration * 90;
   
    glClearColor(0.9*_bgColor.r, 0.9*_bgColor.g, 0.9*_bgColor.b, _bgColor.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // [self renderSkybox];
    if (console.showBg==0.0) [self renderScreen];
    [self renderConsole];
}

- (void) initMyView
{
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);

    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    _viewAspect = fabs(width / height);

    // Must call each frame for GLKView (different from Android)
    // glViewport(40, height-120, width-40, height-150);
    
    [self getSkyboxData:@"delta2_"];
    glid_screen.tex_cube = [self getCubeTextureId: 0];
    [self initScreen];
    [self initConsole];   
    
    // Text input field and soft keyboard
    
    textField = [[UITextField alloc] initWithFrame:CGRectMake(20, height - 100, width-170, 40)];
    textField.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.font = [UIFont fontWithName:@"courier-bold" size:32];
    textField.placeholder = @"Type here";
    textField.textColor = [UIColor whiteColor];
    textField.tintColor = [UIColor grayColor];
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.keyboardType = UIKeyboardTypeASCIICapable;
    textField.returnKeyType = UIReturnKeyDefault;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.delegate = self;
   // [textField addTarget:self action:@selector(textFieldShouldEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
    [self addSubview:textField];
    
    // Set up global variables
    
    scene.yrotIncrement = 0.0000;
    _projectionMatrix = GLKMatrix4MakeOrtho(-1.0, 1.0, -1.0, 1.0, 0.0, 200.0);
    _viewMatrix = GLKMatrix4Identity;
    _bgColor = GLKVector4Make(0,0,0,0);
    screen.v_diffuseAlpha = 0.3;
    screen.scale = screen.lastScale = 1.0;
    _imageIndex = 1;
    _cubeIndex = 1;
    console.showBg = 0.0;
    
    paverho.gfxH = 512;
    paverho.gfxV = 140;

    // Define inlay graphics
    
    UIImage *image = [UIImage imageNamed:@"poppy.tga"];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"poppy" ofType:@"tga"];
    gfxRawData = (UInt8*) CFDataGetBytePtr( [self textureFileData:filePath] );
    // UIImage *image = [UIImage imageWithData:[NSData dataWithBytes:(const void *)gfxRawData length:4*256*256];];
    // Remove background (black=>transparent)
    CGFloat colorMasking[] = {0, 1,  0, 1,  0, 1, 255, 255};
    CGImageRef imageRef = CGImageCreateWithMaskingColors(image.CGImage, colorMasking);
    image = [UIImage imageWithCGImage:imageRef];
    
    CGFloat borderWidth = 4.0;
    
    //    CGFloat h = image.size.height;
    //    CGFloat w = image.size.width;
    //    CGRect adjusted = CGRectMake(0, 0, w + 2*borderWidth, h + 2*borderWidth);
    //    UIImageView *imageViewBig = [[UIImageView alloc] initWithFrame:adjusted];
    
    inlayView = [[UIImageView alloc] initWithImage:image];
    inlayView.layer.backgroundColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5] CGColor];
    inlayView.layer.cornerRadius = 10;
    inlayView.layer.borderWidth = borderWidth;
    inlayView.layer.masksToBounds = YES;
    inlayView.layer.borderColor=[[UIColor whiteColor] CGColor];
    inlayView.frame = CGRectMake( width - 300, 50, 256, 256);
    [self addSubview:inlayView];
    
    // Define image change buttons

    UIImage *image2 = [UIImage imageNamed:@"door_open.png"];
    UIButton *buttonCube = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttonCube addTarget:self
               action:@selector(cubeButtonPressed:)
     forControlEvents:UIControlEventTouchUpInside];
    buttonCube.backgroundColor = [UIColor clearColor];
    [buttonCube setBackgroundImage:image2 forState:UIControlStateNormal];
    buttonCube.frame = CGRectMake(width-80, height-120, 64.0, 64.0);
    buttonCube.alpha = 0.6;
    [self addSubview:buttonCube];
    
    UIImage *image3 = [UIImage imageNamed:@"door2_open.png"];
    UIButton *buttonImage = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttonImage addTarget:self
               action:@selector(imageButtonPressed:)
     forControlEvents:UIControlEventTouchUpInside];
    buttonImage.backgroundColor = [UIColor clearColor];
    [buttonImage setBackgroundImage:image3 forState:UIControlStateNormal];
    buttonImage.frame = CGRectMake(width-130, height-120, 64.0, 64.0);
    buttonImage.alpha = 0.6;
    buttonImage.transform = CGAffineTransformMakeScale(-1, 1);
    [self addSubview:buttonImage];

    
    
    [self startSonne16];
    
    // TAP
    
    UITapGestureRecognizer *singleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                        action:@selector(handleSingleTap:)];
    [self addGestureRecognizer:singleTap];

    UITapGestureRecognizer *doubleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                        action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
        
    // PAN
    
    UIPanGestureRecognizer *panRecognizer =
    [[UIPanGestureRecognizer alloc] initWithTarget:self
                     action:@selector(handlePanning:)];
    panRecognizer.minimumNumberOfTouches = 1;
    [self addGestureRecognizer:panRecognizer];
    
    // PINCH
    
    UIPinchGestureRecognizer* pinch =
    [[UIPinchGestureRecognizer alloc] initWithTarget:self
                    action:@selector(handlePinch:)];
    [self addGestureRecognizer:pinch];
    
}

- (void)cubeButtonPressed:(UIButton *)button
{
    _cubeIndex += 1;
    if (_cubeIndex>3) _cubeIndex = 1;
    
    NSString *resName;
    switch(_cubeIndex) {
        case 1: resName = @"delta2_"; break;
        case 2: resName = @"venise_"; break;
        case 3: resName = @"fishhoek_"; break;
    }
    
    [self getSkyboxData:resName];
    glDeleteTextures(1, &glid_screen.tex_cube);
    glid_screen.tex_cube = [self getCubeTextureId: 0];
}

- (void)imageButtonPressed:(UIButton *)button
{
    _imageIndex += 1;
    if (_imageIndex>3) _imageIndex = 1;
    
    console.showBg = 0.0;
    NSString *resName;
    switch(_imageIndex) {
        case 1: resName = @"leaftex1"; break;
        case 2: resName = @"leaftex1_NRM"; break;
        case 3: console.showBg = 1.0;
                break;
    }
    
    glid_screen.tex_GFX =
    [self buildTextureFromFile:
     [[NSBundle mainBundle]
      pathForResource:resName ofType:@"png"]
                forTextureUnit: 0 ];

}


- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    uint8_t size = textField.text.length;
    for (int i=0; i<size; i++) {
       sendPaverhoChar(textField.text.UTF8String[i]);
    }
    textField.text = @"";
    sendPaverhoChar(10);
    return YES;
}



- (void)handlePanning:(UIPanGestureRecognizer *)sender
{
    if (!sender.numberOfTouches) return;
    
    CGPoint touch1 = [sender locationOfTouch:0 inView:self];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        _initialTouchX = touch1.x;
        _initialTouchY = touch1.y;
        _initialInlayCenterX = inlayView.center.x;
        _initialInlayCenterY = inlayView.center.y;
    }
    
    if (sender.state == UIGestureRecognizerStateChanged && sender.numberOfTouches==2) {
        
        if (touch1.x >= inlayView.frame.origin.x &&
            touch1.x <= inlayView.frame.origin.x + inlayView.frame.size.width &&
            touch1.y >= inlayView.frame.origin.y &&
            touch1.y <= inlayView.frame.origin.y + inlayView.frame.size.height
        ){
            inlayView.center = CGPointMake( _initialInlayCenterX + [sender translationInView:self].x,
                                        _initialInlayCenterY + [sender translationInView:self].y );

            if (inlayView.frame.origin.x <= 0) inlayView.frame = CGRectMake(0, inlayView.frame.origin.y, inlayView.frame.size.width, inlayView.frame.size.height);
            
            if (inlayView.frame.origin.y <= 0) inlayView.frame = CGRectMake(inlayView.frame.origin.x, 0, inlayView.frame.size.width, inlayView.frame.size.height);
            
            if (inlayView.frame.origin.x + inlayView.frame.size.width >= self.bounds.size.width) inlayView.frame = CGRectMake(self.bounds.size.width - inlayView.frame.size.width, inlayView.frame.origin.y, inlayView.frame.size.width, inlayView.frame.size.height);
            
            CGFloat yLimit = self.bounds.size.height - 130;
            
            if (inlayView.frame.origin.y + inlayView.frame.size.height >= yLimit) inlayView.frame = CGRectMake(inlayView.frame.origin.x, yLimit - inlayView.frame.size.height, inlayView.frame.size.width, inlayView.frame.size.height);
        }
        else { // Change main view diffuse texture alpha
            screen.v_diffuseAlpha += (GLfloat) [sender translationInView:self].x / 50000;
            if (screen.v_diffuseAlpha < 0) screen.v_diffuseAlpha = 0.0;
            if (screen.v_diffuseAlpha > 1.0) screen.v_diffuseAlpha = 1.0;
        }
    }
    else if (sender.state == UIGestureRecognizerStateChanged && sender.numberOfTouches==1) {
        if (touch1.x >= inlayView.frame.origin.x &&
            touch1.x <= inlayView.frame.origin.x + inlayView.frame.size.width &&
            touch1.y >= inlayView.frame.origin.y &&
            touch1.y <= inlayView.frame.origin.y + inlayView.frame.size.height
            ){
        }
        else {
            scene.skybox_yRot -= (_initialTouchX - touch1.x) / 25000;
            if ([sender velocityInView:self].x > 50.0) scene.yrotIncrement += 0.00005;
            if ([sender velocityInView:self].x < -50.0) scene.yrotIncrement -= 0.00005;
            if (scene.yrotIncrement>0.0004) scene.yrotIncrement = 0.0004;
            if (scene.yrotIncrement<-0.0004) scene.yrotIncrement = -0.0004;
        }
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:[recognizer.view self]];
    //NSLog(@"Tapped\n %f %f", location.x, location.y);
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    scene.xlight = (0.5 * width - location.x) / 100;
    scene.ylight = (0.5 * height - location.y) / 100;
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
   // NSLog(@"Doubletap\n");
}

// Pinch-zoom handler
-(void)handlePinch:(UIPinchGestureRecognizer*)sender
{
    CGPoint touch1 = [sender locationOfTouch:0 inView:self];
    
    // First case: pinch inside inlay
    if (touch1.x >= inlayView.frame.origin.x &&
        touch1.x <= inlayView.frame.origin.x + inlayView.frame.size.width &&
        touch1.y >= inlayView.frame.origin.y &&
        touch1.y <= inlayView.frame.origin.y + inlayView.frame.size.height
        ){
//
//        if([(UIPinchGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
//
//        }
//        else {
//            inlayView.frame = CGRectMake(
//            inlayView.frame.origin.x,
//            inlayView.frame.origin.y,
//            inlayView.frame.size.width * ,
//            inlayView.frame.size.height *
//            );
//            if (inlayView.frame.origin.x + inlayView.frame.size.width >= self.bounds.size.width) inlayView.frame = CGRectMake(self.bounds.size.width - inlayView.frame.size.width, inlayView.frame.origin.y, inlayView.frame.size.width, inlayView.frame.size.height);
//
//            CGFloat yLimit = self.bounds.size.height - 130;
//
//            if (inlayView.frame.origin.y + inlayView.frame.size.height >= yLimit) inlayView.frame = CGRectMake(inlayView.frame.origin.x, yLimit - inlayView.frame.size.height, inlayView.frame.size.width, inlayView.frame.size.height);
//        }
    }
    else { // Pinch outside of inlay
        if([(UIPinchGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
            sender.scale = screen.scale;
        }
        else {
            screen.scale = sender.scale;
            if (screen.scale < 0.8) screen.scale = 0.8;
            if (screen.scale > 2.0) screen.scale = 2.0;
        }
    }
}


///////////////////////////////////////////////////////////////////////////////

- (void) updateMatrices
{
    _screenModelMatrix = GLKMatrix4Identity;
    
    GLfloat fixX=0, fixY=0;
    if (screen.scale<1.0) {
        fixX = -(1.0 - screen.scale) + 0.04;
        fixY = -(1.0 - screen.scale) + 0.3;
    } else {
        fixX = (screen.scale - 1.0) + 0.04;
        fixY = (screen.scale - 1.0) + 0.3;
    }
    
    _screenModelMatrix = GLKMatrix4Translate( _screenModelMatrix, fixX, fixY, 0.0);
    _screenModelMatrix = GLKMatrix4Scale(_screenModelMatrix, screen.scale, screen.scale, 1.0);
    // _viewAspect
    
    _viewMatrix = GLKMatrix4Identity;
    
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
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:filePath];
    return image.CGImage;
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
    
    int xstep=40, ystep=40, xpos=0, ypos=0, chindex=0;
    CGImageRef atlasRef = [self textureFileImageRef:filePath];
    CGImageRef subImage;
    CFDataRef rawData;
    
    GLuint arrayTextureId;
    glGenTextures(1, &arrayTextureId);
    glActiveTexture(GL_TEXTURE0 + tu);
    glBindTexture(GL_TEXTURE_2D_ARRAY, arrayTextureId);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MIN_FILTER,
                    GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_S,
                    GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_T,
                    GL_CLAMP_TO_EDGE);
    glTexImage3D(GL_TEXTURE_2D_ARRAY, 0, GL_RGBA8, 24, 38,
                 256, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glGenerateMipmap(GL_TEXTURE_2D_ARRAY);
    
    for (ypos=0; ypos<8*ystep; ypos+=ystep)
        for (xpos=0; xpos<16*xstep; xpos+=xstep)
        {
            subImage = CGImageCreateWithImageInRect(atlasRef,CGRectMake(xpos,ypos,24,38));
            rawData = CGDataProviderCopyData(CGImageGetDataProvider(subImage));
            glTexSubImage3D(GL_TEXTURE_2D_ARRAY, 0, 0, 0, chindex++,
                            24, 38, 1, GL_RGBA, GL_UNSIGNED_BYTE,
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
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL_RGBA8, 1024, 1024, 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE, (UInt8*) CFDataGetBytePtr(_nz));
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL_RGBA8, 1024, 1024, 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE, (UInt8*) CFDataGetBytePtr(_pz));
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL_RGBA8, 1024, 1024, 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE, (UInt8*) CFDataGetBytePtr(_py));
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL_RGBA8, 1024, 1024, 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE, (UInt8*) CFDataGetBytePtr(_ny));
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL_RGBA8, 1024, 1024, 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE, (UInt8*) CFDataGetBytePtr(_nx));
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL_RGBA8, 1024, 1024, 0,
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
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    glGenerateMipmap(GL_TEXTURE_2D);
    
    return tex;
}



///////////////////////////////////////////////////////////////////////////////
//
//      SKYBOX STUFF
//
///////////////////////////////////////////////////////////////////////////////

- (void) getSkyboxData:(NSString*)prefix
{
    _nx  = [self textureFileData:[[NSBundle mainBundle]
                                  pathForResource:[NSString stringWithFormat:@"%@%@", prefix, @"nx"] ofType:@"png"]];
    _ny  = [self textureFileData:[[NSBundle mainBundle]
                                  pathForResource:[NSString stringWithFormat:@"%@%@", prefix, @"ny"] ofType:@"png"]];
    _nz  = [self textureFileData:[[NSBundle mainBundle]
                                  pathForResource:[NSString stringWithFormat:@"%@%@", prefix, @"nz"] ofType:@"png"]];
    _px  = [self textureFileData:[[NSBundle mainBundle]
                                  pathForResource:[NSString stringWithFormat:@"%@%@", prefix, @"px"] ofType:@"png"]];
    _py  = [self textureFileData:[[NSBundle mainBundle]
                                  pathForResource:[NSString stringWithFormat:@"%@%@", prefix, @"py"] ofType:@"png"]];
    _pz  = [self textureFileData:[[NSBundle mainBundle]
                                  pathForResource:[NSString stringWithFormat:@"%@%@", prefix, @"pz"] ofType:@"png"]];
}


///////////////////////////////////////////////////////////////////////////////
//
//      SCREEN STUFF
//
///////////////////////////////////////////////////////////////////////////////



- (void) initScreen
{
    [self buildScreenShaderProgram];
    [self buildScreenVao];
    
    glid_screen.tex_GFX =
    [self buildTextureFromFile:
     [[NSBundle mainBundle]
      pathForResource:@"leaftex1" ofType:@"png"]
                forTextureUnit: 0 ];
    
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
    glLinkProgram(glid_screen.prog_shader);
    
    // Vertex shader attributes
    
    glid_screen.attr_vertexOffs = glGetAttribLocation(glid_screen.prog_shader,
                                                      "vertexOffs");
    glid_screen.attr_uvChar = glGetAttribLocation(glid_screen.prog_shader,
                                                  "uvChar");
    
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
    glid_screen.uni_cubemapSampler =
    glGetUniformLocation(glid_screen.prog_shader, "cubemapSampler");
    glid_screen.uni_skyboxYRot =
    glGetUniformLocation(glid_screen.prog_shader, "skyboxYRot");
    
    
    glDeleteShader(vs);
    glDeleteShader(fs);
}

///////////////////////////////////////////////////////////////////////////////

- (void) buildScreenVao
{
    // Set up a vertex buffer array
    
    glGenVertexArrays(1, &glid_screen.buf_vao);
    glBindVertexArray(glid_screen.buf_vao);
    
    // Set up the buffer containing the vertices of the base quad
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    
    GLfloat vertexData[ 5*4 ] =   // 2 vertex offsets, 2 tex coordinates
    {
       -1.0,  -1.0,   0.0, 0.0,
        1.0,  -1.0,   1.0, 0.0,
        1.0,   1.0,   1.0, 1.0,
       -1.0,   1.0,   0.0, 1.0,
       -1.0,  -1.0,   0.0, 0.0
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

///////////////////////////////////////////////////////////////////////////////

- (void) renderScreen
{
    glUseProgram(glid_screen.prog_shader);
    
    glUniform1i(glid_screen.uni_diffuseMapSampler, 0);
    glUniform1i(glid_screen.uni_cubemapSampler, 1);
    glUniform3f(glid_screen.uni_bgCol, _bgColor.r, _bgColor.g, _bgColor.b);
    glUniform1f(glid_screen.uni_skyboxYRot, scene.skybox_yRot);
    glUniform1f(glid_screen.uni_v_diffuseAlpha, screen.v_diffuseAlpha);
    
    glUniformMatrix4fv(glid_screen.uni_modelViewProjectionMatrix, 1, GL_FALSE,
                       _screenModelViewProjectionMatrix.m );
    
    glBindVertexArray(glid_screen.buf_vao);
    
    // Bind gfx/diffuse map to texture unit 0
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, glid_screen.tex_GFX);
    
    // Bind cube map to unit 1
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_CUBE_MAP, glid_screen.tex_cube);
  
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 5);
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
    
    NSString *downloadFolderPath = NSTemporaryDirectory();
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
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self quitApp];
//        });
    });
}



///////////////////////////////////////////////////////////////////////////////
//
//      CONSOLE STUFF (Char matrix only)
//
///////////////////////////////////////////////////////////////////////////////



- (void) initConsole
{
    [self buildConsoleShaderProgram];
    [self buildConsoleVao];
    
    NSString *filePath = [[NSBundle mainBundle]
                          pathForResource:@"sdf_font" ofType:@"png"];
    glid_console.tex_arrayTexture =
    [self arrayTextureFromAtlasfile:filePath forTextureUnit:3];
}

///////////////////////////////////////////////////////////////////////////////

- (void) buildConsoleShaderProgram
{
    // Vertex shader, string from textfile
    GLuint  vs = [self compileShaderFromFile:[[NSBundle mainBundle]
                                              pathForResource:@"consoleVs" ofType:@"txt"]
                                  shaderType:GL_VERTEX_SHADER ];
    // Fragment shader, string from textfile
    GLuint  fs = [self compileShaderFromFile:[[NSBundle mainBundle]
                                              pathForResource:@"consoleFs" ofType:@"txt"]
                                  shaderType:GL_FRAGMENT_SHADER ];
    
    glid_console.prog_shader = glCreateProgram();
    glAttachShader(glid_console.prog_shader, vs);
    glAttachShader(glid_console.prog_shader, fs);
    glLinkProgram(glid_console.prog_shader);
    
    // Vertex shader attributes
    
    glid_console.attr_vertexOffs = glGetAttribLocation(glid_console.prog_shader,
                                                      "vertexOffs");
    glid_console.attr_uvChar = glGetAttribLocation(glid_console.prog_shader,
                                                  "uvChar");
    glid_console.attr_charColor = glGetAttribLocation(glid_console.prog_shader,
                                                     "charColor");
    glid_console.attr_charData = glGetAttribLocation(glid_console.prog_shader,
                                                    "charData");
    
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

///////////////////////////////////////////////////////////////////////////////

- (void) buildConsoleVao
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
    
    glVertexAttribPointer(glid_console.attr_vertexOffs, 3, GL_FLOAT, GL_FALSE,
                          5*sizeof(GLfloat), (void *)0);
    glEnableVertexAttribArray(glid_console.attr_vertexOffs);
    
    glVertexAttribPointer(glid_console.attr_uvChar, 2, GL_FLOAT, GL_FALSE,
                          5*sizeof(GLfloat), (void *)12);
    glEnableVertexAttribArray(glid_console.attr_uvChar);
    
    
    // Set up the buffer for screen characters
    
    glGenBuffers(1, &glid_console.buf_vboChars);
    glBindBuffer(GL_ARRAY_BUFFER, glid_console.buf_vboChars);
    glBufferData(GL_ARRAY_BUFFER, sizeof(paverho.screenData),
                 &paverho.screenData,
                 GL_STREAM_DRAW);
    
    glVertexAttribIPointer(glid_console.attr_charData, 1, GL_UNSIGNED_SHORT,
                           1*sizeof(GL_UNSIGNED_SHORT), (GLvoid*)0 );
    glVertexAttribDivisor(glid_console.attr_charData, 1 ); // Instanced
    glEnableVertexAttribArray(glid_console.attr_charData);
    
    
    // Set up the buffer for screen colors
    
    glGenBuffers(1, &glid_console.buf_vboColors);
    glBindBuffer(GL_ARRAY_BUFFER, glid_console.buf_vboColors);
    glBufferData(GL_ARRAY_BUFFER, sizeof(paverho.screenColor),
                 &paverho.screenColor,
                 GL_STREAM_DRAW);
    
    glVertexAttribPointer(glid_console.attr_charColor, 3, GL_FLOAT,
                          GL_FALSE, 3*sizeof(GL_FLOAT), (GLvoid*)0 );
    glVertexAttribDivisor(glid_console.attr_charColor, 1 ); // Instanced
    glEnableVertexAttribArray(glid_console.attr_charColor);
    
    glBindVertexArray(0);
}

///////////////////////////////////////////////////////////////////////////////

- (void) renderConsole
{
    glUseProgram(glid_console.prog_shader);
    
    glUniform1i(glid_console.uni_arrayTextureSampler, 3);
    
    glUniform3f(glid_console.uni_bgCol, _bgColor.r, _bgColor.g, _bgColor.b);
    
    glUniform1i(glid_console.uni_cursorX, paverho.cursorX);
    glUniform1i(glid_console.uni_cursorY, paverho.cursorY);
    glUniform1i(glid_console.uni_cursorVis, paverho.cursorVis);
    
    glUniform1f(glid_console.uni_v_showBg, console.showBg);
    glUniform1f(glid_console.uni_v_pixResX, self.contentScaleFactor * self.bounds.size.width);
    glUniform1f(glid_console.uni_v_pixResY, self.contentScaleFactor * self.bounds.size.height);
    
    glUniformMatrix4fv(glid_console.uni_viewMatrix, 1, GL_FALSE,
                       _viewMatrix.m );
    glUniformMatrix4fv(glid_console.uni_modelViewMatrix, 1, GL_FALSE,
                       _screenModelViewMatrix.m );
    glUniformMatrix4fv(glid_console.uni_modelViewProjectionMatrix, 1, GL_FALSE,
                       _screenModelViewProjectionMatrix.m );
    
    glBindVertexArray(glid_console.buf_vao);
    
    // Bind array texture to unit 3
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D_ARRAY, glid_console.tex_arrayTexture);
    
    glDrawArraysInstanced( GL_TRIANGLE_STRIP, 0, 6, 64*32 );
}






@end

