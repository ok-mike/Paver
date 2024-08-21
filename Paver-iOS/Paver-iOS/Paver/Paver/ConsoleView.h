//
//  OpenGLView.h
//  Phos-iOS
//
//  Created by Michael on 05.02.18.
//  Copyright © 2018 Michael Mangelsdorf. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import <GLKit/GLKit.h>


// Define the view

@interface ConsoleView : GLKView <UITextFieldDelegate> {
    
    GLuint _tex_GFX;
    
    CGFloat _initialTouchX, _initialTouchY;
    CGFloat _initialInlayCenterX, _initialInlayCenterY;
    
    uint8_t _imageIndex, _cubeIndex;
    
    UITextField *textField;
    UIImageView *inlayView;
    
    CGFloat prevPanX, prevPanY;
    CGFloat baseRotX, baseRotY;
    CGFloat deltaRotX, deltaRotY;
    
    GLfloat _viewAspect;
    CFDataRef _nx, _ny, _nz, _px, _py, _pz;
    
    GLKMatrix4 _viewMatrix;

    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _screenModelMatrix;
    GLKMatrix4 _screenModelViewMatrix;
    GLKMatrix4 _screenModelViewProjectionMatrix;
    GLKVector4 _bgColor;

}

- (void) initMyView;
- (void) frameDraw:(CGRect)rect;
- (void) frameUpdate;

@end






