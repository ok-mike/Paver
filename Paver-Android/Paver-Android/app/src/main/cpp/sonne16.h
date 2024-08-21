// Android version of a Paverho/Sonne-16 simulator
// Copyr. 2018 Michael Mangelsdorf (mim@ok-schalter.de)

#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <arpa/inet.h>
#include <math.h>
#include <time.h>

#define GP_MAX_ADDR (64+32)*1024

extern void* run(void* dummy);
extern void setTextColor( uint16_t offs, uint16_t val);
extern int rd_blk_range(int bstart, int blockn, uint16_t *buffer);
extern int wr_blk_range(int bstart, int blockn, uint16_t *buffer);

extern void rd_blk_into_ram(int srcblk, uint16_t dstaddr, int ovl);
extern void wr_ram_into_blk(int destblk, uint16_t srcaddr, int ovl);

extern void paverho_init(uint16_t *gpramptr);
extern void paverho_set_overlay(int overlay);

extern uint16_t gp_ram_ld( uint16_t addr, int ovl );
extern void gp_ram_st( uint16_t addr, uint16_t val, int ovl);

struct Paverho
{
    uint16_t linebuffer[1024];
    uint16_t scanCodeReady;
    char keyCode;
    uint16_t idle;
    uint16_t cursorVis;
    uint16_t cursorX, cursorY;
    uint16_t bgCol;
    uint16_t txtBase;
    uint16_t gfxBase;
    uint16_t gfxH;
    uint16_t gfxV;
    uint16_t quit;

    int screenData[64*32*2];

    unsigned char* gfxRawData;
    int threadData;
};

extern struct Paverho paverho;