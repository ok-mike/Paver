

/* Paver Hen / Sonne-16 emulation tool
* Copyright 2015-2020 by Michael Mangelsdorf (mim@ok-schalter.de)
* CC0 Public Domain - Use for any purpose, no warranties
*/


#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/in.h>
#include <unistd.h>

typedef uint16_t cell;

#define TEA_RUNNABLE	1
#define TEA_UTILITY		2
#define TEA_CYF_SYMBOL	3
#define TEA_RDV         4

    /* 012345678901234567890 */

#define RDV_FUNC_wrPFSFile   5
#define RDV_FUNC_rdPFSFile   6

#define RDV_SIG_Timeout      0x10017 // Can only be produced by Hen itself

#define RDV_VM_ReadsRDVBuf  1
#define RDV_VM_Finished     2
#define RDV_VM_NeedsStr16   11
#define RDV_VM_PullsBlock   13
#define RDV_VM_PushesBlk    16


#define VOLUME_FILENAME "hen.egg"

#define BYTES_PER_BLOCK      512

#define WORDS_PER_BLOCK      BYTES_PER_BLOCK / 2

#define VOL_PHYS_BLOCK       992   // 0th block of PFS volume too

#define PFS_OFFS_CHARGE      5
#define PFS_OFFS_NEXT        4
#define PFS_OFFS_DATA        6

#define PFS_OFFS_KERNEL_BIX  2

#define RAM_MAX_ADDR     (56 + 16 * 8) * 1024 // 188416 cells, 736 blocks
#define FRAMES_MAX_ADDR  (64) * 1024          // 65536 cells, 256 blocks => 992

#define MAX_CYCLES			83 * 1000 * 1000

#define SFRAMESIZE  11

#define D               Frames[ sfp + 0]
#define R               Frames[ sfp + 8]
#define W               Frames[ sfp + 9]
#define CFK             Frames[ sfp + 10]

#define pc              Frames[ 0]    // Program Counter          
#define sfp             Frames[ 1]
#define fbp             Frames[ 2]
#define cfk             Frames[ 3]

#define PTR             Frames[ 4]    // Fixed locations
#define RV              Frames[ 5]

#define TOS             Frames[ fbp + 1]
#define SEC             Frames[ fbp]

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
#define sop_VM_ready    26

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
#define dop_VM_rdv      11

#define CSTRBUFSIZE     BYTES_PER_BLOCK

cell Ram[ RAM_MAX_ADDR];
cell Frames[ FRAMES_MAX_ADDR] = {
        0,                       // Program Counter
        SFRAMESIZE,              // Subroutine Frame Pointer
        6,                       // Frame base ptr
        0,                       // Current frame key
};

int mute_threshold = 0;
int force = 0;

int fetches;

int VM_End; // Don't use type 'cell'. Values >FFFF used by Hen itself.

cell iw; // Instruction cell

cell G, L, R2_LOR, R1, R2_MSB, R2; // Names for parts of instruction cell
cell opcode, SEVEN, OFFS, SXOFFS;

FILE *volFP;

cell *RDVPtr;
int RDVCounter;
cell RDVBuf[ 256];

char cStrBuffer[ BYTES_PER_BLOCK];





FILE*
openVolumeFileOrDie( void)
{
		FILE * volFP;
		volFP = fopen( VOLUME_FILENAME, "r+");
		if (volFP == NULL) {
				printf( "Missing volume file or file error\n");
				exit(-1);
		}
		return volFP;
}



void
storeCStrAt( cell* blockBuffer, int woffs, char* cstr)
{
		int i=0;
		for (;;) {
				blockBuffer[ woffs] = cstr[ i++] << 8;
				if (cstr[ i] == '\0') break; 
				blockBuffer[ woffs] += cstr[ i++] & 0xFF;
				woffs++;
				if (cstr[ i] == '\0') break; 				
		}
}



int
copyToCStrFrom( cell* blockBuffer, int woffs)
{
		int i = 0;
		int ch;
		
		for (;;) {
				if (woffs >= WORDS_PER_BLOCK) return -1;
				if (i >= BYTES_PER_BLOCK) return -1;
				
				ch = blockBuffer[ woffs];
				cStrBuffer[ i++] = ch >> 8;
				if (ch == 0) break;
				if (i >= BYTES_PER_BLOCK) return -1;
				
				ch &= 0xFF;
				cStrBuffer[ i++] = ch;
				woffs++;
				if (ch == 0) break;
		}
		return 0;
}




/*
* Return memory value implement overlay logic
*/
cell
ram_ld(cell addr, int ovl)
{
	int effective = addr;
	if ((addr >> 13) == 7) /* Top 8k are bank switched OVERLAY */
		effective = ((7 + ovl) << 13) + (addr & 0x1FFF);
	return effective < RAM_MAX_ADDR ? Ram[ effective] : (cell) 0;
}



/*
* Store memory value implement overlay logic
*/
void
ram_st(cell addr, cell  val, int ovl)
{
	int effective = addr;
	if ((addr >> 13) == 7) /* Top 8k are bank switched OVERLAY */
		effective = ((7 + ovl) << 13) + (addr & 0x1FFF);
	if (effective < RAM_MAX_ADDR)
		Ram[ effective] = val;
}




int
strEql8( cell str8p, char* str)
{
		int i = 0, l = strlen(str);
		cell ch;
		for (;;) {
				ch = ram_ld( str8p++, 0);
				if (i < l) {
						printf( "%04X %c\n",ch, str[i]);
						if ((ch >> 8) != str[i]) return 0;
				} else return 0;
				i++;
				if (i < l) {
						printf( "%c %c\n",ch >> 8, str[i]);
						if ((ch & 0xFF) != str[i]) return 0;
				} else return 0;
				i++;		
		}
		return 1;
}




int
strEql16( cell str16p, char* str)
{
		int i = 0, l = strlen(str);
		cell ch;
		int result = 1;
		for (;;) {
				ch = ram_ld( str16p++, 0);
				if (!ch || !str[i] ) {
						if (ch != str[i]) result = 0;
						break;
				}
				if (i < l) if (ch != str[i]) return 0;
				i++;
		}
		return result;
}




void
mifgen( char *fname)
{
	FILE *f;
	int i;
	f = fopen( fname, "wb");
	if (f) {
		fprintf( f, "-- hen output image\n\n");
		fprintf( f, "DEPTH = %d;\n", RAM_MAX_ADDR);
		fprintf( f, "WIDTH = 16;\n");
		fprintf( f, "ADDRESS_RADIX = HEX;\n");
		fprintf( f, "DATA_RADIX = HEX;\n");
		fprintf( f, "CONTENT\n");
		fprintf( f, "BEGIN\n\n");

		for (i = 0; i<RAM_MAX_ADDR; i++) {
			fprintf( f, "%04X : %04X;\n", i, Ram[ i]);
		}

		fprintf( f, "\nEND;\n");
		fclose( f);
	}
}



#include "blockio.h"



/*
* Set RAM overlay
*/
void
paver_set_overlay( int overlay)
{
	cfk &= 0xFFF; // Clear overlay_select bits
	cfk += (overlay & 0xF) << 12;
}



cell framekey( cell slot )
{
    switch (slot) {
        case 0: return (cfk >> 9) & 7;
        case 1: return (cfk >> 6) & 7;
        case 2: return (cfk >> 3) & 7;
        default: return cfk & 7;
    }
}

cell* ref( cell regsel)
{
    cell* r;
    if (regsel > 7) r = &Frames[ sfp + (regsel-8) ];
	else if (regsel < 4)
		switch (regsel) {
		case 0: r = &PTR; break;
		case 1: r = &RV; break;
		case 2: r = &TOS; break;
		default: r = &SEC; break;
		}
    else r = &Frames[ sfp - SFRAMESIZE + framekey(regsel-4) ];
    return r;
}





// Add two 16-bit numbers and see if the result exceeds 16 bit
// For SUB, this function is called with negative b
// In this case the carry is an inverted borrow
cell carry( cell a, cell b ) {
    int widesum = (uint32_t) a + (uint32_t) b;
    return widesum > 0xFFFF ? 1 : 0;
}


// Sign extend "bits" wide number to cell
int16_t sxt( cell val, cell bits) {
    // Test the sign bit, if negative return two's complement
    return val&(1<<(bits-1)) ? val-(1<<bits) : val;
}

#include "sop_switch.h"
#include "RDV_switch.h"
#include "zop_switch.h"
#include "dop_switch.h"
#include "execute.h"

#include "tea.h"


void
writePFSFile( char *path, cell *datap, int cells)
{
        RDVPtr = datap;
        RDVCounter = cells;

		storeCStrAt( RDVBuf, 0, path);
		tea( NULL, RDV_FUNC_wrPFSFile, 0);
}



void
readPFSFile( char *path, cell *datap, int cells_max)
{
        RDVPtr = datap;
        RDVCounter = cells_max;

		storeCStrAt( RDVBuf, 0, path);
		tea( NULL, RDV_FUNC_rdPFSFile, 0);
}



/* Transfer a Paver kernel from PFS volume into the process image
   Assume block index of kernel is in volume info block at given offset
*/

void
xferKernel()
{
		cell bix;
		cell words_in_block;
		cell word_offset;

		cell blockbuf[ WORDS_PER_BLOCK];
		cell *dest = Ram;
        
        int allowed = RAM_MAX_ADDR;

		rd_blk_range( VOL_PHYS_BLOCK, 1, blockbuf);
		bix = blockbuf[ PFS_OFFS_KERNEL_BIX]; 

		for (;;) {   /* Pull in linked list of kernel blocks */

				rd_blk_range( bix + VOL_PHYS_BLOCK, 1, blockbuf);
				words_in_block = blockbuf[ PFS_OFFS_CHARGE] / 2;

				for (int i=0; i<words_in_block; i++)
				{
						word_offset = PFS_OFFS_DATA + i;
						if (word_offset < WORDS_PER_BLOCK) {
								if (allowed--)
								*dest++ = blockbuf[ word_offset];
						}
				}

				bix = blockbuf[ PFS_OFFS_NEXT];
				if (bix == 0) break;
		}
}



void
night( void) // Was dumpLife()
{
		int RAM_blocks = RAM_MAX_ADDR / 256;
		int FRAME_blocks = FRAMES_MAX_ADDR / 256;

		wr_blk_range( 0, RAM_blocks, Ram);
		wr_blk_range( RAM_blocks, FRAME_blocks, Frames);
}



void
day( void)
{
		int RAM_blocks = RAM_MAX_ADDR / 256;
		int FRAME_blocks = FRAMES_MAX_ADDR / 256;

		rd_blk_range( 0, RAM_blocks, Ram);
		rd_blk_range( RAM_blocks, FRAME_blocks, Frames);	
}



void
cluck( int importance)
{
		if (mute_threshold > importance) return; // Hush

		printf("\n/* ");
		for (int i=0; i<strlen( cStrBuffer); i++) {
				if (cStrBuffer[ i] == '\n') {
						printf( "\n*  ");
				}
				else printf( "%c", cStrBuffer[ i]);
		}
		printf( "\n*/\n\n");
}




#include "main.h"







