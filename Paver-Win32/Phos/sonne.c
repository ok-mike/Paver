// Sonne emulator code for Phos/Win32
// This file is part of the Aerosol project.
// The entire project including this file has been released to the public domain
// by its author, Michael Mangelsdorf <mim@ok-schalter.de>.
// It comes with no warranty whatsoever, use at your own risk.
// For more information see https://ok-schalter.de/aerosol.

//  card.8T3 is a binary file containing 16-bit cells
//  in network byte order, organized in blocks of 256 cells (512 bytes)

#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS
#endif

#include "sonne.h"

typedef uint16_t word;
typedef int32_t big;


word aced_marker;


#define WORKFNAME_MAXLEN 20
FILE *workfile;
FILE *debugf;
char workfname[WORKFNAME_MAXLEN];

char cardFileName[1024];

#define GP_MAX_ADDR (64+32)*1024
#define TOP16 65535

word gp_RAM[GP_MAX_ADDR];
word fs_RAM[TOP16+1];
word gfx_RAM[2*TOP16+1];
word txt_RAM[8*1024];

#define IRQ_KB_BITMASK 128 // Relevant bit is index + 1
#define IRQ_KB_INDEX 6 // Count array index from 0
#define IRQ_KB_UP 5

uint32_t irq_enabled; // Each bit stores enable state for one of 16 interrupts
word irq_vec[16]; // Interrupt address vectors for 16 interrupts
word irq_up[16];  // Bits show which interrupt request has been handled
uint32_t irq_par;

uint32_t fetches;  // Counts instruction fetches
word delay, delaycount;

#define SFRAMESIZE 11

word pc,        // Program Counter
	sfp=TOP16-SFRAMESIZE,  // Subroutine Frame Pointer
	fbp=2,  // Frame base ptr
	cfk;       // Current frame key

uint32_t txtAddrBuf;

#define D               fs_RAM[sfp+0]
#define R               fs_RAM[sfp+8]
#define W               fs_RAM[sfp+9]
#define CFK             fs_RAM[sfp+10]

#define PTR             fs_RAM[0] // Fixed locations
#define RV              fs_RAM[1]
#define TOS             fs_RAM[fbp+1]
#define SEC             fs_RAM[fbp]

#define op_ZOP          0 // Operation codes
#define op_SOP          1
#define op_ELS          2
#define op_THN          3
#define op_REP          4
#define op_LTL          5
#define op_EQL          6
#define op_GTL          7
#define op_SET          8
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

#define sop_SETL        59
#define sop_IRQ_vec     60
#define sop_W_get       62
#define sop_POP         63
#define sop_DROP        64
#define sop_PULL        65
#define sop_LODS        66
#define sop_STOS        67
#define sop_ASR         68
#define sop_W_set       69
#define sop_TXT_fg      70
#define sop_TXT_bg      71
#define sop_PER         73
#define sop_NYBL        77
#define sop_PC_set      81
#define sop_PC_get      82
#define sop_BYTE        83
#define sop_SERVICE     84
#define sop_MSB         85
#define sop_LSB         86
#define sop_NOT         87
#define sop_NEG         88
#define sop_DELAY       89
#define sop_OVERLAY     90
#define sop_BLANKING    91
#define sop_IRQ_self    92
#define sop_GFX_H       93
#define sop_GFX_V       94
#define sop_CYCLES      95
#define sop_CORE_id     99
#define sop_TXT_setcolor  100
#define sop_TXT_getcolor  101
#define sop_TXT_setpos    102
#define sop_TXT_setglyph  103
#define sop_TXT_getglyph  104
#define sop_TXT_curset  105
#define sop_KB_keyc     106
#define sop_RETI        108
#define sop_BGCOL_set   109
#define sop_CPU_speed   114
#define sop_CPU_id      115
#define sop_FONT_ld     116
#define sop_FONT_st     117

#define zop_INIT        0
#define zop_NEXT        1
#define zop_LIT         2
#define zop_TXT_SHOWCUR 3
#define zop_TXT_HIDECUR 4
#define zop_JUMP        10
#define zop_TXT_flip    13
#define zop_GFX_flip    14
#define zop_VM_IDLE     15
#define zop_SOFT        16
#define zop_SYNC        17
#define zop_NOP         20
#define zop_GOTKEY		21

#define dop_REF         1
#define dop_GFX_LDFG    2
#define dop_GFX_STBG    3
#define dop_BRA         4
#define dop_PAR         6
#define dop_SETD        7
#define dop_PUSH        9
#define dop_RET         10

big srclength; // Size of input text file in bytes

word iw; // Instruction word
// Names for parts of instruction word
word G, L, R2_LOR, R1, R2_MSB, R2;
word opcode, SEVEN, OFFS, SXOFFS;

// Temporary variables
big widesum;
word i, tmp;

void mifgen(char* fname)
{
	FILE *f;
	int i;
	f = fopen(fname, "wb");
	if (f) {
		fprintf(f, "-- hen output image\n\n");
		// fprintf( f, "DEPTH = 65536;\n");
		fprintf(f, "DEPTH = %d;\n", GP_MAX_ADDR);
		fprintf(f, "WIDTH = 16;\n");
		fprintf(f, "ADDRESS_RADIX = HEX;\n");
		fprintf(f, "DATA_RADIX = HEX;\n");
		fprintf(f, "CONTENT\n");
		fprintf(f, "BEGIN\n\n");

		for (i = 0; i<GP_MAX_ADDR; i++) {
			fprintf(f, "%04X : %04X;\n", i, gp_RAM[i]);
		}

		fprintf(f, "\nEND;\n");
		fclose(f);
	}
}

/*
* Set RAM overlay
*/
void
paver_set_overlay(int overlay)
{
	cfk &= 0xFFF; // Clear overlay_select bits
	cfk += (overlay & 0xF) << 12;
}


/*
* Return memory value implement overlay logic
*/
uint16_t
gp_ram_ld(uint16_t addr, int ovl)
{
	int effective = addr;
	if ((addr >> 13) == 7) /* Top 8k are bank switched OVERLAY */
		effective = ((7 + ovl) << 13) + (addr & 0x1FFF);
	return effective < GP_MAX_ADDR ? gp_RAM[effective] : (uint16_t)0;
}


/*
* Store memory value implement overlay logic
*/
void
gp_ram_st(uint16_t addr, uint16_t  val, int ovl)
{
	int effective = addr;
	if ((addr >> 13) == 7) /* Top 8k are bank switched OVERLAY */
		effective = ((7 + ovl) << 13) + (addr & 0x1FFF);
	if (effective < GP_MAX_ADDR)
		gp_RAM[effective] = val;
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



/*
* Read a block from sdcard into a buffer, then transfer to gp_ram
* Address is 16-bit only, bank switching
*/
void
rd_blk_into_ram(int srcblk, uint16_t dstaddr, int ovl)
{
	uint16_t buffer[256];
	rd_blk_range(srcblk, 1, buffer);
	for (int i = 0; i < 256; i++)
		gp_ram_st((uint16_t)(dstaddr + i), buffer[i], ovl);
}


/*
* Write a block from gp_ram to sdcard
* Address is 16-bit only, bank switching
*/
void
wr_ram_into_blk(int destblk, uint16_t srcaddr, int ovl)
{
	uint16_t buffer[256];
	for (int i = 0; i < 256; i++)
		buffer[i] = gp_ram_ld((uint16_t)(srcaddr + i), ovl);
	wr_blk_range(destblk, 1, buffer);
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
	else if (regsel < 4)
		switch (regsel) {
		case 0: r = &PTR; break;
		case 1: r = &RV; break;
		case 2: r = &TOS; break;
		default: r = &SEC; break;
		}
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
	i = 0;
	//while (gp_ram_ld(*ref(L) + i, 3) != 0) { fprintf(debugf, "%04X ", gp_ram_ld(*ref(L) + i, 3)); i++; }
	//while (i<5) { fprintf(debugf, "%c", gp_ram_ld(*ref(L) + i, 0)); i++; }
    //fprintf(debugf, "\n");
	//fprintf(debugf, "%04X (%d)\n", *ref(L), *ref(L));
	//fprintf(debugf, "%c", *ref(L), *ref(L));
	//  paver.quit=1;
        //  if (workfile) fclose( workfile );
		//  xferboot("card.8T3");
		//  mifgen("RAM_image_exitdump.mif");
		//exit(*ref(L));
	//fprintf(debugf, "%04X\n", R);
		break;

		case sop_TXT_fg:
			*ref(L) = paver.txtBase & 8191;
		break;

		case sop_TXT_bg:
			*ref(L) = (4096 - paver.txtBase) & 8191;
			break;

        case sop_TXT_setcolor:
		i = txtAddrBuf & 8191;
        txt_RAM[i] = *ref(L);
        paver.screenColor[i].r = (float)(*ref(L) >> 11)/32.0;
        paver.screenColor[i].g = (float)((*ref(L) >> 5)&63)/64.0;
        paver.screenColor[i].b = (float)(*ref(L) & 0b11111)/32.0;
        break;

        case sop_TXT_getcolor:
		i = txtAddrBuf & 8191;
        *ref(L) = txt_RAM[i];
        break;

        case sop_TXT_setpos: txtAddrBuf = *ref(L) & 8191;
        break;

        case sop_TXT_getglyph:
		i = txtAddrBuf & 8191;
        *ref(L) = paver.screenData[i];
        break;

        case sop_TXT_setglyph:
		i = txtAddrBuf & 8191;
        paver.screenData[i] = *ref(L);
        break;

        case sop_TXT_curset:
            paver.cursorX = *ref(L)&127;
            paver.cursorY = (*ref(L)>>7)&31;
        break;

        case sop_KB_keyc:
        *ref(L) = paver.scanCodeReady ? paver.keyCode : 0;
        paver.scanCodeReady = 0;
        break;

        case sop_GFX_H: paver.gfxH = *ref(L); break;

        case sop_GFX_V: paver.gfxV = *ref(L); break;

        case sop_BGCOL_set: paver.bgCol = *ref(L);
        break;

        case sop_VM_rdblk: // Block number in A1, buffer ptr in A2
        *ref(L) = 0; // Signal back that VM handles this
		rd_blk_into_ram(*ref(4),*ref(5), cfk >> 12);
        *ref(5)+=256;
        break;

        case sop_VM_wrblk: // Block number in A1, buffer ptr in A2
        *ref(L) = 0;
        wr_ram_into_blk(*ref(4),*ref(5), cfk >> 12);
        *ref(5)+=256;
        break;

        case sop_PER: gp_ram_st( gp_ram_ld( 1+(pc++), cfk >> 12), *ref(L), cfk >> 12);
        break;

        case sop_W_get: *ref(L) = W;
        break;

        case sop_SETL: *ref(L) = gp_ram_ld( 1+(pc++), cfk >> 12);
        break;

       	case sop_CYCLES:
			*ref(L) = fetches & 0xFFFF;
			D = fetches >> 16;
		break;

        case sop_PC_set: pc = *ref(L) - 1;
        break;

        case sop_PC_get: *ref(L) = pc;
        break;

        case sop_ASR: // Arithmetic shift right
			i = *ref(L);
			*ref(L) >>=  1;
			if (i & 0x8000) *ref(L) |= 0x8000;
        break;

        case sop_PULL: // Caller frame overlay may be different
			*ref(L) = gp_ram_ld( R++, CFK >> 12);
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

        case sop_OVERLAY:
		paver_set_overlay(L);
        break;

		case sop_POP:
			*ref(L) = TOS;
			fbp--;
		break;

		case sop_DROP:
			fbp -= L;
		break;

        case sop_CORE_id:
        *ref(L) = 1;
        break;

        case sop_LODS:
        RV = gp_ram_ld( (*ref(L))++, cfk >> 12);
        break;

        case sop_STOS:
        gp_ram_st( (*ref(L))++, RV, cfk >> 12);
        break;

        case sop_IRQ_vec:
        irq_vec[L&15] = gp_ram_ld( ++pc, cfk >> 12);
        break;

        case sop_SERVICE:
        // service cmd = L
        // service par = D concat RV
        irq_par = (D << 16) + RV;
        switch (L) {
			case 1: irq_enabled &= ~irq_par; break; // Disable bits
			case 2: irq_enabled |= irq_par; break; // Enable bits
        }
        break;

        case sop_RETI:
			cfk = CFK;
			pc = R - 1; // Compensate post increment
			sfp += (SFRAMESIZE << 1);
			//fprintf(debugf, "RETI\n");
		break;

        // Drop through
        case sop_VM_flen: if (workfile) fseek( workfile, 0, SEEK_END );
        case sop_VM_fgetpos:
        if (workfile) {
            large_n = ftell( workfile );
            RV = large_n / 65536;
            *ref(L) = large_n - 65536 * RV;
        } else {
            RV = 0;
            *ref(L) = RV = 0;
        }
        break;

        case sop_VM_fseek:
        if (workfile) D = fseek( workfile, RV*65536 + *ref(L), SEEK_SET );
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
                u = gp_ram_ld( *ref(L)+i, cfk >> 12);
                workfname[i] = u;
                if (!u) break;
            }
            workfname[i] = 0;
            strcpy( fname, paver.pavMacPath);
            strcat( fname, "/");
            strcat( fname, workfname);
            D = (workfile = fopen(fname,"w+")) ? 1 : 0;
        break;

        case sop_VM_fold:
            if (workfile) fclose(workfile);
            for (i=0;i<WORKFNAME_MAXLEN-1;i++) {
                u = gp_ram_ld( *ref(L)+i, cfk >> 12);
                workfname[i] = u;
                if (!u) break;
            }
            workfname[i] = 0;
            strcpy( fname, paver.pavMacPath);
            strcat( fname, "/");
            strcat( fname, workfname);
            D = (workfile = fopen(fname,"r+")) ? 1 : 0;
        break;

        case sop_VM_fclose:
        // RV:D truncation length,if 0 discard
        if (workfile) {
            // fseek( workfile,0,SEEK_END );
            // large_n = ftell( workfile );
            strcpy( fname, paver.pavMacPath);
            strcat( fname, "/");
            strcat( fname, workfname);
            if (!(*ref(L)|RV)) remove(fname);
          //  else truncate(fname,RV*65536+ *ref(L));
            fclose(workfile);
        }
        break;

        case sop_VM_HTON:
        D = htons(*ref(L));
        break;

        case sop_VM_NTOH:
        D = ntohs(*ref(L));
        break;

        case sop_CPU_id:
			//f = fopen("debug.txt", "a");
			//for (i = 0; i < 256; i++) {
			//	fprintf(f, "%04X ", gp_ram_ld(*ref(L) + i, 0));
			//	if ((i+1)%16 == 0) fprintf(f, "\n");
			//}
			//fprintf(f, "\n%04X\n\n", *ref(L));
			//fclose(f);
			*ref(L) = 1;
			break; // 1=Hen, 2=Paverho

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
			sfp = TOP16 - SFRAMESIZE;
			cfk = 0;
			pc = 0;
			paver.cursorVis = 0;
			paver.cursorY = 0;
			paver.cursorX = 0;
			paver.bgCol = 0;
			irq_enabled = 0; // Disable all 16 interrupts
			// paver.gfxV = 164;
			// paver.gfxH = 768;
        break;

		case zop_NOP:  break;

		case zop_LIT:
			fbp++;
			TOS = gp_ram_ld(1 + (pc++), cfk >> 12);
		break;

        case zop_NEXT:
        W = gp_ram_ld( R++, cfk >> 12);
        pc = W - 1;
        break;

        case zop_JUMP:
        pc = gp_ram_ld( pc+1, cfk >> 12) - 1;
        break;

		case zop_SOFT:
			sfp = TOP16 - SFRAMESIZE;
			break;

        case zop_VM_IDLE: paver.idle=1;
        break;

        case zop_TXT_flip:
            paver.txtBase = 32*128 - paver.txtBase; // Toggle
            break;

        case zop_GFX_flip:
            paver.gfxBase = 64*1024 - paver.gfxBase; // Toggle
            break;

        case zop_TXT_SHOWCUR: paver.cursorVis = 1;
            break;

        case zop_TXT_HIDECUR: paver.cursorVis = 0;
            break;

        case zop_GOTKEY:
            paver.scanCodeReady = 0;
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
        w = gp_ram_ld( 1+(pc++), cfk >> 12);
        *ref(R1) = w;
        *ref(L) = gp_ram_ld( w, cfk >> 12);
        break;

        case dop_BRA:
        pc += sxt( (L<<4)+R1, 8 ) - 1;
        break;

        case dop_SETD:
        *ref(L) = gp_ram_ld( pc+1, cfk >> 12);
        *ref(R1) = gp_ram_ld( pc+2, cfk >> 12);
        pc = pc + 2;
        break;

        case dop_GFX_LDFG:
        w = *ref(R1);
        *ref(L) = gfx_RAM[w + paver.gfxBase];
        break;

        case dop_GFX_STBG:
        w = *ref(R1);
		i = w + (65536 - paver.gfxBase);
        gfx_RAM[i] = *ref(L) & 511; // 9 bit depth
        paver.gfxRawData[4*w+0 + (65536 - paver.gfxBase)] = ((gfx_RAM[i] >> 6) & 7) << 5;
        paver.gfxRawData[4*w+1 + (65536 - paver.gfxBase)] = ((gfx_RAM[i] >> 3) & 7) << 5;
        paver.gfxRawData[4*w+2 + (65536 - paver.gfxBase)] =  (gfx_RAM[i]       & 7) << 5;
        paver.gfxRawData[4*w+3 + (65536 - paver.gfxBase)] = 255;
        break;

        case dop_PAR:
        fs_RAM[( sfp - SFRAMESIZE + L ) & 0xFFFF] = *ref(R1);
            printf("PAR\n");
        break;

		case dop_PUSH:
			fbp++;
			TOS = *ref(L) + sxt(R1, 4);
		break;

		case dop_RET:
			RV = *ref(L) + sxt(R1, 4);
		pc = R - 1;
		cfk = CFK;
		sfp += SFRAMESIZE;
		break;

        default: // printf("Unhandled DOP %04X\n", R2);
        break;
    }
}

void execute( word opcode )
{
	fetches++;
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
        case op_SET: *ref(L) = (R2_LOR<<4) + R1;
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

        case op_LOD: *ref(L) = gp_ram_ld( OFFS, cfk >> 12);
        pc++;
        break;

        case op_STO: gp_ram_st( OFFS, *ref(L), cfk >> 12);
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
        case op_JSR2:
        tmp = D; // Src has TOS GET D
        sfp -= SFRAMESIZE;
        CFK = cfk;
        cfk &= 0xF000; //Zero all but overlay selector
        cfk |= (iw & 0x0FFF);
        R = pc + 2;
        pc = gp_ram_ld( pc + 1, cfk >> 12);
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
    //debugf = fopen("debug.txt", "a");
	int debugflag = 0;
    while (!paver.quit)
    {
        // posedge clock
		while (paver.idle) Sleep(1);
		if (paver.clipReady) {
			int i=0;
			uint16_t ch;
			while (i++ < 32*80) {
				ch = paver.clipText[i];
				gp_ram_st(0xE000 + i, ch, 4);
			}
			paver.clipReady = 0;
		}

        // Handle KB interrupt
		if ((paver.scanCodeReady == 0) && (irq_enabled & IRQ_KB_BITMASK))
			irq_up[IRQ_KB_UP] = 1;
		if ( (irq_enabled & IRQ_KB_BITMASK) && irq_up[IRQ_KB_UP] && paver.scanCodeReady ) {
            // Fake JSR
            sfp -= (SFRAMESIZE<<1);  // Protect PAR frame owned by subroutine
            CFK = cfk;
            cfk = 0b000001010011; // overlay 0, signature D L1 L2 L3
			R = pc;
            pc = irq_vec[IRQ_KB_INDEX];
			irq_up[IRQ_KB_UP] = 0;
			//debugflag = 1;
        }

        iw = gp_ram_ld( pc, cfk >> 12); // Fetch instruction word

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

		if (debugflag) fprintf(debugf, "%04X %04X\n", pc, iw);

        execute( opcode = (G<<1) | R2_MSB ); // Execute instruction
    }
	//fclose(debugf);
}

void setCardFileName( const char* fname)
{
    strcpy( cardFileName, fname);
}


int xferboot( const char* fname)       // Read RAM from binary file
{                                      // Network order

	//rd_blk_into_ram(0, 0, 0);
	int blk = 0;
	/* Populate 0-56k non-overlay region */
	for (int i = 0; i < 56 * 4; i++) /* These are 56k cells = 112k bytes = 224 blocks */
		rd_blk_into_ram(blk++, 256 * i, 0); /* Each block fills 256 cells */
	/* Blk now at beginning of overlay region, overlays share 56k-64k */
	for (int ovl = 0; ovl <= 4; ovl++) {
		for (int i = 56 * 4; i < 64 * 4; i++) /* Sweep overlay region 56k - 64k for each overlay */
			rd_blk_into_ram(blk++, 256 * i, ovl);
	}

	//for (unsigned i = 0; i < 0xFFFF; i++) {
	//	if (gp_ram_ld(i, 0) == 0xACED) aced_marker = i-1;
	//}

	mifgen("RAM_image.mif");
}

// FILE * f = fopen("debug.txt", "a");
// fprintf(f, "%04X\n", *ref(L));
// fclose(f);
