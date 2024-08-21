//
//  sonne16.c
//  Poppyhen
//
//  Created by Michael on 11.01.18.
//  Copyright © 2018 Michael Mangelsdorf. All rights reserved.
//
//  This file is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//
//  Any derivative work ("Fork") please leave this notice intact.
//
//  More information on Poppy can be found at:
//
//  http://ok-schalter.de/poppy
//
//  card.8T3 is a binary file containing 16-bit cells
//  in network byte order, organized in blocks of 256 cells (512 bytes)

#include "paverho.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
#include <arpa/inet.h>

#import <MacTypes.h>


typedef uint16_t word;
typedef int32_t big;

struct paverho_state_t paverho;
extern char pavMacPath[1024];

extern uint8_t* gfxRawData;

#define WORKFNAME_MAXLEN 20
FILE *workfile;
char workfname[WORKFNAME_MAXLEN];

char cardFileName[1024];

#define GP_MAX_ADDR (64+32)*1024
#define TOP16 65535

word gp_RAM[GP_MAX_ADDR];
word fs_RAM[TOP16+1];
word gfx_RAM[2*TOP16+1];
word txt_RAM[4096];

uint32_t cycles;  // Counts instruction cycles
word delay, delaycount;

#define SFRAMESIZE 10

word pc,        // Program Counter
sfp=TOP16-SFRAMESIZE,  // Subroutine Frame Pointer
cfk;       // Current frame key

word work, ip;
big txtAddrBuf;

#define D               fs_RAM[sfp+0]
#define R               fs_RAM[sfp+8]
#define CFK             fs_RAM[sfp+9]

#define TOS             fs_RAM[0] // Fixed locations
#define E               fs_RAM[1]
#define SP              fs_RAM[2]
#define DP              fs_RAM[3]

#define op_ZOP          0 // Operation codes
#define op_SOP          1
#define op_ELS          2
#define op_THN          3
#define op_REP          4
#define op_LTL          5
#define op_EQL          6
#define op_GTL          7
#define op_INT          8
#define op_LTR          9
#define op_EQR          10
#define op_GTR          11
#define op_LOD          12
#define op_STO          13
#define op_SHL          14
#define op_SHR          15
#define op_JSR          16
#define op_JSR2         17
#define op_DOP          18
#define op_DOP2         19
#define op_GET          20
#define op_GET2         21
#define op_AND          22
#define op_AND2         23
#define op_IOR          24
#define op_IOR2         25
#define op_EOR          26
#define op_EOR2         27
#define op_ADD          28
#define op_ADD2         29
#define op_SUB          30
#define op_SUB2         31

#define sop_VM_gets     0
#define sop_VM_exit     1
#define sop_VM_prn      2
#define sop_VM_putc     3
#define sop_VM_puts     7
#define sop_VM_argc     8
#define sop_VM_argvset  9
#define sop_VM_argvget  10
#define sop_VM_rdblk    14
#define sop_VM_wrblk    15
#define sop_VM_HTON     16
#define sop_VM_NTOH     17
#define sop_VM_flen     18
#define sop_VM_fseek    19
#define sop_VM_fgetpos  20
#define sop_VM_fread    21
#define sop_VM_fwrite   22
#define sop_VM_fnew     23
#define sop_VM_fold     24
#define sop_VM_fclose   25

#define sop_GFX_H         93
#define sop_GFX_V         94
#define sop_TXT_colors    100
#define sop_TXT_colorg    101
#define sop_TXT_pos_set   102
#define sop_TXT_glyphs    103
#define sop_TXT_glyphg    104
#define sop_TXT_curset    105
#define sop_KB_keyc       106
#define sop_BGCOL_set     109

#define sop_cycles_lo   95
#define sop_cycles_hi   96
#define sop_DELAY       89
#define sop_OVERLAY     90
#define sop_CORE_id     99
#define sop_SET         59
#define sop_PER         73
#define sop_PUSH        64
#define sop_POP         63
#define sop_LODS        66
#define sop_STOS        67
#define sop_ONEHOT      69
#define sop_EXEC        72
#define sop_SERVICE     74
#define sop_NYBL        77
#define sop_LIT         78
#define sop_DROP        79
#define sop_PICK        80
#define sop_GO          81
#define sop_PC_GET      82
#define sop_BYTE        83
#define sop_VIA         68
#define sop_IP_GET      75
#define sop_IP_SET      76
#define sop_IRQ_vec     60
#define sop_IP_POP      61
#define sop_CALLER      65
#define sop_W_GET       62
#define sop_MSB         85
#define sop_LSB         86
#define sop_NOT         87
#define sop_NEG         88
#define sop_RETI        108
#define sop_PERIOD      114
#define sop_SYSID       115

#define zop_INIT        0
#define zop_NEXT        1
#define zop_SWAP        2
#define zop_STALL       6
#define zop_RET         7
#define zop_THREAD      8
#define zop_DOCOL       9
#define zop_JUMP        10
#define zop_IP_COND     11
#define zop_SYNC        17
#define zop_BMOVU       18
#define zop_BMOVD       19
#define zop_NOP         20

#define zop_VM_IDLE      15
#define zop_TXT_flip     13
#define zop_GFX_flip     14
#define zop_TXT_SHOWCUR  3
#define zop_TXT_HIDECUR  4

#define dop_REF         1
#define dop_GFX_LD      2
#define dop_GFX_ST      3
#define dop_BRA         4
#define dop_PEEK        5
#define dop_PAR         6
#define dop_PULL        7
#define dop_GFX_THRU    8     // This is an error in hen ! gets called, handler doesn't work for 8
#define dop_FRLD        9
#define dop_FRST        10

big srclength; // Size of input text file in bytes

word iw; // Instruction word
// Names for parts of instruction word
word G, L, R2_LOR, R1, R2_MSB, R2;
word opcode, SEVEN, OFFS, SXOFFS;

// Temporary variables
big widesum;
word i, tmp;

word gp_ram_ld( word addr ) { // Top 8k are bank switched OVERLAY
    big effective = addr;
    if ((addr>>13)>=7) effective = ((7+(cfk>>12))<<13) + (addr&0x1FFF);
    return effective > GP_MAX_ADDR ? 0 : gp_RAM[effective];
}

void gp_ram_st( word addr, word val ) { // Top 8k are bank switched OVERLAY
    big effective = addr;
    if ((addr>>13)>=7) effective = ((7+(cfk>>12))<<13) + (addr&0x1FFF);
    if (effective <= GP_MAX_ADDR) gp_RAM[effective] = val;
}

void rdblk ( word blockn, big bufptr)
{
    word w;
    FILE *f;
    f = fopen( cardFileName,"rb+");
    fseek( f, 512 * blockn, SEEK_SET);
    for (i=0;i<256;i++) {
        fread( &w, 2, 1, f);
        gp_ram_st( bufptr+i, ntohs(w) );
    }
    fclose( f);
}

void wrblk ( word blockn, big bufptr)
{
    word w;
    FILE *f;
    f = fopen( cardFileName,"rb+");
    fseek( f, 512 * blockn, SEEK_SET);
    for (i=0;i<256;i++) {
        w = htons( gp_ram_ld( bufptr+i ));
        fwrite( &w, 2, 1, f);
    }
    fclose( f);
}

word framekey( word slot )
{
    switch (slot) {
        case 0: return (cfk >> 9) & 7;
        case 1: return (cfk >> 6) & 7;
        case 2: return (cfk >> 3) & 7;
        default: return cfk & 7;
    }
}

word* ref( word regsel)
{
    word* r;
    if (regsel > 7) r = &fs_RAM[ sfp + (regsel-8) ];
    else if (regsel < 4) r = &fs_RAM[ regsel ];
    else r = &fs_RAM[ sfp + SFRAMESIZE + framekey(regsel-4) ];
    return r;
}

// Use this to extend the instruction set with instructions that use
// one operand slot of the instruction word (Single Operand)
void sop_switch( void )
{
    size_t large_n;
    big i;
    word u;
    char fname[1024];
    
    switch (SEVEN) { // 127 possible instructions here
        
        // This sets the quit flag, causing the while loop in run()
        // to end the simulation and quit.
        case sop_VM_exit:
        printf("sop_VM_exit (%04X)\n",*ref(L));
        paverho.quit=1;
        if (workfile) fclose( workfile );
        break;
        
        case sop_TXT_colors:
        txt_RAM[(paverho.txtBase + txtAddrBuf) & 4095] = *ref(L);
        paverho.screenColor[(paverho.txtBase + txtAddrBuf) & 4095].r = (float)(*ref(L) >> 11)/32.0;
        paverho.screenColor[(paverho.txtBase + txtAddrBuf) & 4095].g = (float)((*ref(L) >> 5)&63)/64.0;
        paverho.screenColor[(paverho.txtBase + txtAddrBuf) & 4095].b = (float)(*ref(L) & 0b11111)/32.0;
        break;

        case sop_TXT_colorg:
        *ref(L) = txt_RAM[ (paverho.txtBase + txtAddrBuf) & 4095];
        break;
        
        case sop_TXT_pos_set: txtAddrBuf = *ref(L) & 2047;
        break;

        case sop_TXT_glyphg:
        *ref(L) = paverho.screenData[(paverho.txtBase + txtAddrBuf) & 4095];
        break;

        case sop_TXT_glyphs:
        paverho.screenData[(paverho.txtBase + txtAddrBuf) & 4095] = *ref(L);
        break;
        
        case sop_TXT_curset:
            paverho.cursorX = *ref(L)&63;
            paverho.cursorY = (*ref(L)>>6)&31;
        break;
        
        case sop_KB_keyc:
        *ref(L) = paverho.scanCodeReady ? paverho.keyCode : 0;
        paverho.scanCodeReady = 0;
        break;
        
        case sop_GFX_H: paverho.gfxH = *ref(L); break;
            
        case sop_GFX_V: paverho.gfxV = *ref(L); break;
            
        case sop_BGCOL_set: paverho.bgCol = *ref(L);
        break;
          
        case sop_VM_rdblk: // Block number in A1, buffer ptr in A2
        //  printf("rdbuf %04X to %04X\n", *ref(4), *ref(5));
        *ref(L) = 0;
        rdblk(*ref(4),*ref(5));
        *ref(5)+=256;
        break;
        
        case sop_VM_wrblk: // Block number in A1, buffer ptr in A2
        //  printf("wrbuf %04X from %04X\n", *ref(4), *ref(5));
        *ref(L) = 0;
        wrblk(*ref(4),*ref(5));
        *ref(5)+=256;
        break;
        
        case sop_EXEC:
        gp_ram_st( --DP, ip );
        ip = pc + 1;
        pc = *ref(L) - 1;
        break;
        
        case sop_PER: gp_ram_st( gp_ram_ld( 1+(pc++) ), *ref(L) );
        break;
        
        case sop_PUSH: gp_ram_st( --SP, TOS );
        TOS = *ref(L);
        break;
        
        case sop_POP:  *ref(L) = TOS;
        TOS = gp_ram_ld( SP++ );
        break;
        
        case sop_W_GET: *ref(L) = work;
        break;
        
        case sop_SET: *ref(L) = gp_ram_ld( 1+(pc++) );
        break;
        
        case sop_cycles_lo:
        *ref(L) = cycles & 0xFFFF;
        break;
        
        case sop_cycles_hi:
        *ref(L) = cycles >> 16;
        break;
        
        case sop_GO: pc = *ref(L) - 1;
        break;
        
        case sop_PC_GET: *ref(L) = pc;
        break;
        
        // Create a SIG_EXT_VECTOR for ::
        case sop_VIA: pc = gp_ram_ld( *ref(L)) - 1;
        break;
        
        case sop_IP_GET: *ref(L) = ip;
        break;
        
        case sop_IP_SET: ip = *ref(L);
        break;
        
        case sop_IP_POP: *ref(L) = gp_ram_ld( ip++ );
        break;
        
        case sop_CALLER: *ref(L) = gp_ram_ld( R++ );
        break;
        
        case sop_DELAY:
        break;
        
        case sop_MSB:
        D = *ref(L) & 0x8000;
        break;
        
        case sop_LSB:
        D = *ref(L) & 1;
        break;
        
        case sop_NOT:
        D = 0xFFFF ^ *ref(L);
        break;
        
        case sop_NEG:
        D = (0xFFFF ^ *ref(L)) + 1;
        break;
        
        case sop_BYTE:
        D = *ref(L) & 0xFF;
        break;
        
        case sop_NYBL:
        D = *ref(L) & 0xF;
        break;
        
        case sop_PICK:
        gp_ram_st( --SP, TOS );
        TOS = gp_ram_ld( SP+L+1 );
        break;
        
        case sop_DROP:  SP += L+1;
        TOS = gp_ram_ld( SP-1 );
        break;
        
        case sop_LIT:   gp_ram_st( --SP, TOS );
        TOS = L;
        break;
        
        case sop_OVERLAY:
        cfk = (cfk<<4)>>4; // Clear overlay_select bits
        cfk += (L)<<12;
        break;
        
        case sop_CORE_id:
        *ref(L) = 1;
        break;
        
        case sop_LODS:
        D = gp_ram_ld( (*ref(L))++ );
        break;
        
        case sop_STOS:
        gp_ram_st( (*ref(L))++, D );
        break;
        
        case sop_ONEHOT:
        D = 1 << L;
        printf("Onehot: %d", L);
        break;
        
        case sop_IRQ_vec:
        printf("Vector\n");
        fs_RAM[L] = gp_ram_ld( ++pc );
        break;
        
        case sop_SERVICE:
        printf("Service\n");
        break;
        
        case sop_RETI:
        printf("RETI\n");
        break;
        
        // Drop through
        case sop_VM_flen: if (workfile) fseek( workfile, 0, SEEK_END );
        case sop_VM_fgetpos:
        if (workfile) {
            large_n = ftell( workfile );
            E = large_n / 65536;
            *ref(L) = large_n - 65536 * E;
        } else {
            E = 0;
            *ref(L) = E = 0;
        }
        break;
        
        case sop_VM_fseek:
        if (workfile) D = fseek( workfile, E*65536 + *ref(L), SEEK_SET );
        else D = 0xFFFF;
        break;
        
        case sop_VM_fread:
        if (workfile) {
            u = fread( ref(L), 1, 1, workfile );
            D = u;
        }
        else D = 0xFFFF;
        break;
        
        case sop_VM_fwrite:
        if (workfile) {
            u = fwrite( ref(L), 1, 1, workfile );
            D = u;
        }
        else D = 0xFFFF;
        break;
        
        case sop_VM_fnew:
            if (workfile) fclose(workfile);
            for (i=0;i<WORKFNAME_MAXLEN-1;i++) {
                u = gp_ram_ld( *ref(L)+i );
                workfname[i] = u;
                if (!u) break;
            }
            workfname[i] = 0;
            strcpy( fname, pavMacPath);
            strcat( fname, "/");
            strcat( fname, workfname);
            D = (workfile = fopen(fname,"w+")) ? 1 : 0;
        break;
        
        case sop_VM_fold:
            if (workfile) fclose(workfile);
            for (i=0;i<WORKFNAME_MAXLEN-1;i++) {
                u = gp_ram_ld( *ref(L)+i );
                workfname[i] = u;
                if (!u) break;
            }
            workfname[i] = 0;
            strcpy( fname, pavMacPath);
            strcat( fname, "/");
            strcat( fname, workfname);
            D = (workfile = fopen(fname,"r+")) ? 1 : 0;
        break;
        
        case sop_VM_fclose:
        // E:D truncation length,if 0 discard
        if (workfile) {
            // fseek( workfile,0,SEEK_END );
            // large_n = ftell( workfile );
            strcpy( fname, pavMacPath);
            strcat( fname, "/");
            strcat( fname, workfname);
            if (!(*ref(L)|E)) remove(fname);
            else truncate(fname,E*65536+ *ref(L));
            fclose(workfile);
        }
        break;
        
        case sop_VM_HTON:
        D = htons(*ref(L));
        break;
        
        case sop_VM_NTOH:
        D = ntohs(*ref(L));
        break;
        
        case sop_SYSID: *ref(L) = 1; break; // 1=Hen, 2=Paverho
        
        default: // printf("Unhandled SOP %d\n", SEVEN);
        break;
    }
}


// Add two 16-bit numbers and see if the result exceeds 16 bit
// For SUB, this function is called with negative b
// In this case the carry is an inverted borrow
word carry( word a, word b ) {
    widesum = (uint32_t) a + (uint32_t) b;
    return widesum > 0xFFFF ? 1 : 0;
}

// Sign extend "bits" wide number to word
int16_t sxt( word val, word bits) {
    // Test the sign bit, if negative return two's complement
    return val&(1<<(bits-1)) ? val-(1<<bits) : val;
}

// Use this to extend the instruction set with instructions that do not
// use any operand slot of the instruction word (Zero Operand)
void zop_switch( void )
{
    word u;
    
    switch ((L<<4)+R1) // 127*16 possible instructions here
    {
        case zop_INIT:
        
        break;
        case zop_NOP:  break;
        
        case zop_RET:
        pc = R - 1;
        cfk = CFK;
        sfp += SFRAMESIZE;
        break;
        
        case zop_NEXT:
        work = gp_ram_ld( ip++ );
        pc = work - 1;
        break;
        
        case zop_SWAP:
        u = TOS;
        TOS = gp_ram_ld( SP );
        gp_ram_st( SP, u );
        break;
        
        case zop_STALL:
        pc = ip - 1;
        ip = gp_ram_ld( DP++ );
        break;
        
        case zop_THREAD:
        gp_ram_st( --DP, ip );
        ip = pc + 2;
        pc = gp_ram_ld( pc+1 ) - 1;
        break;
        
        case zop_DOCOL:
        gp_ram_st( --DP, ip );
        ip = pc + 1;
        work = gp_ram_ld( ip++ );
        pc = work - 1;
        break;
        
        case zop_JUMP:
        pc = gp_ram_ld( pc+1 ) - 1;
        break;
        
        case zop_IP_COND:
        if (D) ip = gp_ram_ld( ip );
        else {
            ip++;
            D = 0;
        }
        break;
        
        case zop_VM_IDLE: paverho.idle=1;
        break;
            
        case zop_TXT_flip:
            paverho.txtBase = 32*64 - paverho.txtBase; // Toggle
            break;

        case zop_GFX_flip:
            paverho.gfxBase = 64*1024 - paverho.gfxBase; // Toggle
            break;
            
        case zop_TXT_SHOWCUR: paverho.cursorVis = 1;
            break;
            
        case zop_TXT_HIDECUR: paverho.cursorVis = 0;
            break;
            
        default: // printf("Unhandled ZOP %04X\n", (L<<4)+R1);
        break;
    }
}

// Use this to extend the instruction set with instructions that use
// two operand slots of the instruction word (Dual Operand)
void dop_switch( void )
{
    big w;
    
    switch (R2) { // 16 possible instructions here
        
        case dop_REF:
        w = gp_ram_ld( 1+(pc++) );
        *ref(R1) = w;
        *ref(L) = gp_ram_ld( w );
        break;
        
        case dop_BRA:
        pc += sxt( (L<<4)+R1, 8 ) - 1;
        break;
        
        case dop_PEEK:
        *ref(L) = gp_ram_ld( SP + R1 );
        break;
        
        case dop_PULL:
        *ref(L) = gp_ram_ld( pc+1 );
        *ref(R1) = gp_ram_ld( pc+2 );
        pc = pc + 2;
        break;
        
        case dop_GFX_LD:
        w = (*ref(R1) + gp_ram_ld(++pc)) & 0xFFFF;
        *ref(L) = gfx_RAM[w];
        break;
        
        case dop_GFX_ST:
        case dop_GFX_THRU:
        w = (*ref(R1) + gp_ram_ld(++pc)) & 0xFFFF; // Constrain the address range
        gfx_RAM[w] = *ref(L) & 511; // 9 bit depth
        gfxRawData[4*w+0] = ((gfx_RAM[w] >> 6) & 7) << 5;
        gfxRawData[4*w+1] = ((gfx_RAM[w] >> 3) & 7) << 5;
        gfxRawData[4*w+2] =  (gfx_RAM[w]       & 7) << 5;
        gfxRawData[4*w+3] = 255;
        if (R2==dop_GFX_THRU) {
            w = paverho.gfxBase ? w+0 : w+0x10000;
            gfx_RAM[w] = *ref(L) & 511; // 9 bit depth
            gfxRawData[4*w+0] = ((gfx_RAM[w] >> 6) & 7) << 5;
            gfxRawData[4*w+1] = ((gfx_RAM[w] >> 3) & 7) << 5;
            gfxRawData[4*w+2] =  (gfx_RAM[w]       & 7) << 5;
            gfxRawData[4*w+3] = 255;
        }
        break;
        
        case dop_PAR:
        fs_RAM[( sfp - SFRAMESIZE + L ) & 0xFFFF] = *ref(R1);
            printf("PAR\n");
        break;
        
        case dop_FRLD:
        *ref(L) = fs_RAM[( sfp - SFRAMESIZE + *ref(R1) ) & 0xFFFF];
            printf("FRLD\n");
        break;
        
        case dop_FRST:
        fs_RAM[( sfp - SFRAMESIZE + *ref(R1) ) & 0xFFFF] = *ref(L);
            printf("FRST\n");
        break;
        
        default: // printf("Unhandled DOP %04X\n", R2);
        break;
    }
}

void execute( word opcode )
{
    switch (opcode)
    {
        // Half range instructions
        
        case op_ZOP: zop_switch(); // Zero operand
        pc++;
        break;
        
        case op_SOP: sop_switch(); // Single operand
        pc++;
        break;
        
        case op_ELS: if (*ref(L)==0) pc += sxt( SEVEN, 7 );
        else pc++;
        break;
        
        case op_THN: if (*ref(L)!=0) pc += sxt( SEVEN, 7 );
        else pc++;
        break;
        
        case op_REP: if (--(*ref(L))) pc += sxt( SEVEN, 7 );
        else pc++;
        break;
        
        case op_LTL: D = (*ref(L)<SEVEN) ? 1 : 0;
        pc++;
        break;
        
        case op_EQL: D = (*ref(L)==SEVEN) ? 1 : 0;
        pc++;
        break;
        
        case op_GTL: D = (*ref(L)>SEVEN) ? 1 : 0;
        pc++;
        break;
        
        // IRQ: sfp-8 already belongs to interrupted func
        // fs_RAM[sfp - SFRAMESIZE + R2_LOR] = *ref(R1) + sxt(L,4);
        case op_INT: *ref(L) = (R2_LOR<<4) + R1;
        pc++;
        break;
        
        case op_LTR: D = (*ref(L)<(SXOFFS)) ? 1 : 0;
        pc++;
        break;
        
        case op_EQR: D = (*ref(L)==(SXOFFS)) ? 1 : 0;
        pc++;
        break;
        
        case op_GTR: D = (*ref(L)>(SXOFFS)) ? 1 : 0;
        pc++;
        break;
        
        case op_LOD: *ref(L) = gp_ram_ld( OFFS );
        pc++;
        break;
        
        case op_STO: gp_ram_st( OFFS, *ref(L) );
        pc++;
        break;
        
        case op_SHL: *ref(L) = (*ref(R1) << (R2_LOR+1));
        pc++;
        break;
        
        case op_SHR: *ref(L) = (*ref(R1) >> (R2_LOR+1));
        pc++;
        break;
        
        // Full range instructions
        
        case op_JSR:
        case op_JSR2: tmp = D; // Src has TOS GET D
        sfp -= SFRAMESIZE;
        CFK = cfk;
        cfk &= 0xF000; //Zero all but overlay selector
        cfk |= (iw & 0x0FFF);
        R = pc + 2;
        pc = gp_ram_ld( pc + 1 );
        if (!pc) pc = tmp;
        break;
        
        case op_DOP:  // Dual operand
        case op_DOP2: dop_switch();
        pc++;
        break;
        
        case op_GET:
        case op_GET2: *ref(L) = *ref(R1) + sxt(R2,4);
        pc++;
        break;
        
        case op_AND:
        case op_AND2: *ref(L) = *ref(R2) & *ref(R1);
        pc++;
        break;
        
        case op_IOR:
        case op_IOR2: *ref(L) = *ref(R2) | *ref(R1);
        pc++;
        break;
        
        case op_EOR:
        case op_EOR2: *ref(L) = *ref(R2) ^ *ref(R1);
        pc++;
        break;
        
        case op_ADD:
        case op_ADD2:
        *ref(L) = *ref(R2) + *ref(R1);
        if (L != 8) D = carry(*ref(R2), *ref(R1));  // Don't store carry of L=D
        pc++;
        break;

        case op_SUB:
        case op_SUB2:
        tmp = (*ref(R1)^0xFFFF)+1;
        *ref(L) = *ref(R2) + tmp;
        if (L != 8) D = carry( *ref(R2), tmp ); // Don't store carry of L=D
        pc++;
        break;
    }
}

void run( void )
{
    while (!paverho.quit)
    {
        while (paverho.idle) usleep(1000);
        
        cycles++;
        iw = gp_ram_ld( pc ); // Fetch instruction word
        
        // if (cycles<128) printf("%04X %04X\n", pc, iw);
        
        // Decode instruction
        
        G = (iw & 0xF000) >> 12; // Slot 0 - Guide code
        L = (iw & 0xF00) >> 8;   // Slot 1 - Left operand
        R2 = (iw & 0xF0) >> 4;   // Slot 2 - First right operand
        R2_MSB = (R2 & 8) >> 3;  // Slot 2 - Most significant bit
        R2_LOR = R2 & 7;         // Slot 3 - Remaining three bits
        R1 = iw & 0xF;           // Slot 3 - Second right operand
        
        SEVEN = (R2_LOR<<4) + R1;
        OFFS = R2_LOR + *ref(R1);
        SXOFFS = sxt(R2_LOR,3) + *ref(R1);
        
        execute( opcode = (G<<1) | R2_MSB ); // Execute instruction
    }
}

void setCardFileName( const char* fname)
{
    strcpy( cardFileName, fname);
}

int xferboot( const char* fname)       // Read RAM from binary file
{                                       // Network order
    word w;
    size_t r=0;
    FILE *f = fopen( fname, "r");
    if (f) {
        for (r=0;r<GP_MAX_ADDR;r++) {
            fread( &w, 2, 1, f);
            gp_RAM[r] = ntohs(w);
        }
        fclose( f);
        return 0;
    }
    else return -1;
}

