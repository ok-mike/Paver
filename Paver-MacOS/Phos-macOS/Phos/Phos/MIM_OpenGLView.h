//
//  MIM_OpenGLView.h
//  Phos
//
//  Created by Michael on 26.01.18.
//  Copyright © 2018 Michael Mangelsdorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>
#import <GLKit/GLKit.h>


// Functions defined in sonne16.c

extern void setCardFileName( const char* fname);
extern int xferboot( const char* fname );
extern void run( void );


char pavMacPath[1024];

dispatch_queue_t emulatorQueue;
dispatch_queue_t queue;
dispatch_source_t timer;

uint8_t* gfxRawData;

@interface MIM_OpenGLView : NSOpenGLView

///////////////////////////////////////////////////////////////////////////////

@property NSTimer* renderTimer;
@property GLfloat viewAspect;

@property CFDataRef nx, ny, nz, px, py, pz;

@property GLuint showFlag;

@property GLKMatrix4 projectionMatrix;
@property GLKMatrix4 viewMatrix;
@property GLKMatrix4 screenModelMatrix;
@property GLKMatrix4 screenModelViewMatrix;
@property GLKMatrix4 screenModelViewProjectionMatrix;

@property GLKVector4 bgColor;

///////////////////////////////////////////////////////////////////////////////

- (BOOL) acceptsFirstResponder;
- (void) viewDidMoveToWindow;
- (void) dealloc;
- (void) windowResized:(NSNotification *) notification;
- (void) prepareOpenGL;
- (void) timerFired:(id)sender;


@end
