//
//  paverho.h
//  Phos
//
//  Created by Michael on 05.02.18.
//  Copyright © 2018 Michael Mangelsdorf. All rights reserved.
//

#include <inttypes.h>
#include <OpenGLES/ES2/gl.h>

#ifndef paverho_h
#define paverho_h



struct paverho_state_t { // State variables for Paverho emulator
    
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
    
    GLuint screenData[64*32 * 2];
    struct { GLfloat r, g, b; } screenColor[64*32 * 2];
    
};


void setCardFileName( const char* fname);
int xferboot( const char* fname );
void run( void );



#endif /* paverho_h */
