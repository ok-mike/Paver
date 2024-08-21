/* Cyf Bootstrap-Assembler and Simulator
   Copyr. Nov.2015 Michael Mangelsdorf

   Read asm file into memory, assemble and run
   Cyf machine code.
*/


// The source file is loaded into memory array src[], srcpos is a global index
// into this array. assemble() sweeps src[], incrementing srcpos on the way
// and storing machine code into te_MEM[], the memory image, indexed by imgpos.
// The second part of the program is run, which simulates the memory image.

#define IP 0
#define FP 1
#define SP 2
#define DP 3

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

uint16_t *lhsref, *rhs1ref, *rhs2ref; // Not used for assembly, only sim
uint16_t lhsop, rhs1op, rhs2op;
uint16_t reg[8];
uint16_t vmaddr; /* For addressing of VM memory, only sim */
uint32_t cycles;
uint16_t vmbank;
uint16_t vmcell;
uint16_t lutaddr=0xFFFF;

int debug;

char* src; /* entire text from source file */
uint32_t srclength; /* allocation size of src */

/* Allocation sizes */
const uint32_t cellcount = 64*1024+1, symbols=1024, labelsize=16;

uint16_t te_MEM[cellcount]; /* data memory cells */
uint16_t te_LUT[cellcount]; /* LUT RAM */

struct { /* Field names and operand types */
  char name[labelsize];
  int optype;
} fields[] = {
  {"IP",0},{"FP",1},{"SP",2},{"T0",3},
  {"T1",4},{"T2",5},{"T3",6},{"T4",7},
  {"L0",0},{"L1",1},{"L2",2},{"L3",3},
  {"L4",4},{"L5",5},{"L6",6},{"L7",7},
  {"REF",1},{"INP",0},{"OUT",0},{"CCA",2},
  {"ADD",2},{"AND",2},{"EOR",2},{"IOR",2},
  {"ADL",3},{"COM",3},{"LOD",3},{"STO",3},
  {"LSL",3},{"LSR",3},{"BRZ",1},{"BNZ",1}
};

struct {                   // See parsenamingparen()
    char id[labelsize];
    char comment[80];
} naming[16];

struct {
  char label[labelsize];
  uint32_t val;
} asym[symbols]; /* address symbol table */

struct {
  char label[labelsize];
  uint32_t val;
} lsym[symbols]; /* LUT */

uint16_t lsympos = 0;
uint16_t asympos = 0; /* last defined address symbol index */
uint16_t asympos2;
uint16_t lsympos2;
uint16_t star; /* this is the size of the stack frame */

int forcecomment = 0;

uint32_t srcpos; /* points to current character in assembly source
                    this was changed from uint16_t on Feb 1 16, it
                    took me all afternoon to find out where the
                    assembler errors came from (srcfile exceed 64k) */

uint16_t imgpos; /* points to current insert position in data memory */

unsigned lhs, rhs1, rhs2, opcode, optype, pass;

/*  Print out a command line message */

    void prhello( void)
    {
        printf("\ncyf 8T0 bootstrap cross assembler/simulator for Sonne-16\n");
        printf("Copyr. 2015 Michael Mangelsdorf\n");
    }


/*  Read the entire source file into a memory buffer */

    char* slurp( const char* fname)
    {
        FILE* f = fopen( fname,"rb");
        if (!f) return NULL;

        fseek( f, 0, SEEK_END);
        srclength = ftell( f) + 1;
        fseek( f, 0, SEEK_SET);

        char *buffer = malloc (srclength);
        if (buffer) {
          fread (buffer, 1, srclength-1, f);
          buffer[srclength]='\0';
        }
        fclose( f);
        return buffer;
    }


/*  Return the current line number in source text */

    int linenum( void)
    {
        uint16_t pos=0;
        uint16_t lines=1;
        while (pos < srcpos) {
           if (src[pos]=='\n') lines++;
           pos++;
        }
        return lines;
    }


/*  Print an error message and drop out */

    void asmerror(const char* emsg)
    {
        printf("Assembler error: '%s', line %d\n", emsg, linenum());
        exit(1);
    }


/*  Return the source character at 'index' from the current position.
    If index exceeds srclength return '\0' */

    char nextch( int index)
    {
        if (srcpos+index >= srclength) return '\0';
        else return src[srcpos+index];
    }

    void prc(const char* str)
    {
         printf("%s: '%c%c%c'\n",
         str, nextch(0), nextch(1),
         nextch(2));
    }

///////// PART 1 - ASSEMBLER /////////////////////////////////////////////


/*  Copy a space terminated string into a null-terminated
    character buffer. Returns length of result string */

    int wordcpy( char* tostr, const char* fromstr)
    {
        int i=0; char ch;
        while ( (ch=fromstr[i])!=' ' && ch!='\t' && ch!='\n' && ch!='\0'
         && ch!=']' && ch!=')' && i<labelsize) tostr[i++]=ch;

        tostr[i]='\0';
        return strlen(tostr);
    }


/*  Compare a space terminated string with a null-terminated string.
    Return 0 if both are equal */

    int wordcmp( const char* strspace, const char* strnull)
    {
        int i=0; char ch; int flag=0; /* assume strings are equal */

    //(ch=strspace[i]) !=' ' && ch!='\t' && ch!='\n' && ch!='.'
    //      &&

        while (i<labelsize && strnull[i]!='\0') {
          ch=strspace[i];
          if (strnull[i++]!=ch) {flag=1;}
        }
        return flag;
    }


/*  Test whether srcpos is still inside the source text */

    int validpos( void)
    {
        if (srcpos < srclength - 1) return 1;
        else return 0;
    }


    void skipcomment(void)
    {
        if ( (nextch(0) >= 'A' && nextch(0) <= 'Z')
          && (nextch(1)>='a' && nextch(1)<='z')) {
            while (validpos() && nextch(0)!='\n') srcpos++;
        }
        if ( (nextch(0) >= 'a' && nextch(0) <= 'z')
          && (nextch(1)>='a' && nextch(1)<='z')) {
            while (validpos() && nextch(0)!='\n') srcpos++;
        }

        if (nextch(0)==';') while (nextch(0)!='\n') srcpos++;
        if (nextch(0)=='-' && nextch(1)=='-') while (nextch(0)!='\n') srcpos++;
    }

    int skipspace(void)
    {
        char ch;
        int isnewline = 0;

        while (validpos()) {
            if (nextch(0)!=' ' && nextch(0)!='\t' && nextch(0)!='\n') break;
            else {
                if (nextch(0)=='\n') isnewline=1;
                srcpos++;
            }
        }

        skipcomment();

        while (validpos()) {
            if (nextch(0)!=' ' && nextch(0)!='\t' && nextch(0)!='\n') break;
            else {
                if (nextch(0)=='\n') isnewline=1;
                srcpos++;
            }
        }
        return isnewline;
    }

/*  Test whether a character is whitespace */

    int space(char c)
    {
        if (c==' '||c=='\n'||c=='\t') return 1;
        else return 0;
    }


/*  Check if number literal and convert to 16-bit variable */

    int parsenum(void)
    {
        const int err = 0x10000;    /* NOT -1 ! */
        int negative = 0;
        int dostar = 0;
        char hexdigit[] = {'0','1','2','3','4','5','6','7','8','9',
                           'A','B','C','D','E','F'};
        int result=0;
        int len, len0, i, multiplier;

        if (nextch(0)=='*') {
            srcpos++;
            //printf("Star as lit = %d\n", star);
            return star;
        }

        if (nextch(0)=='-') {
            negative = 1;
            srcpos++;
        }

        for (len=0; len<19; len++) {
            if (space(nextch(len)) || nextch(len)==']') break;
        }

        if (len==19) return err;
        len0 = len--;

        if (len>0 && nextch(len)=='*') {
           dostar = 1;
           len--;
        }

        /* Look for number base indicator */
        if (len>0 && nextch(len)=='h') {
            multiplier = 1;
            while (--len+1) {
                for (i=0; i<16; i++) {
                    if (nextch(len)==hexdigit[i]) {
                        result += multiplier*i;
                        break;
                    }
                }
                if (i==16) return err;
                multiplier *= 16;
            }
        }
        else if (len>0 && nextch(len)=='b') {
            multiplier = 1;
            while (--len+1) {
               if (nextch(len)=='1') {
                   result += multiplier;
               }
               else if (nextch(len)!='0') return err;
               multiplier *= 2;
            }
        }
        else {
             multiplier = 1;
             while (len+1) {
                 for (i=0; i<10; i++) {
                     if (nextch(len)==hexdigit[i]) {
                         result += multiplier*i;
                         break;
                     }
                 }
                 if (i==10) return err;
                 multiplier *= 10;
                 len--;
             }
        }

        srcpos += len0;
        if (dostar) star = result;
        if (negative) result *= -1;
        return result;
    }


void definenaming(void)
{
    int i,j;
    char *c;

    if (nextch(0)!='(') return;
    // srcpos points to open paren (

    // Is it the FORGET directive?
    if (!wordcmp( &src[srcpos+1], "NEW)")) {
        for (i=0; i<16; i++) {
                naming[i].comment[0] = '\0';
                naming[i].id[0] = '\0';
        }
        srcpos += 5; /* Including opening paren! */
        //printf("FORGETTING\n");
        return;
    }

    // Is it a naming definition? i.e. (Lx ident comment)
    // Must return the reference number + 1 for L-vars (skipping LNK)
    if (nextch(1)=='L') j = 1;
    if (nextch(1)=='S') j = 12;
    if (j==1 || j==12) {
        srcpos+=2; /* Including opening paren */
        i = nextch(0);
        if (j==1) {
            if (i>='0' && i<='6') i = nextch(0) - '0' + 1;
        }
        else if (j==12) {
            if (i>='0' && i<='7') i = nextch(0) - '0' + 12;
        }
        else asmerror("Invalid L register index");

        srcpos++;
        while (validpos() && (nextch(0)==' ' || nextch(0)=='\t')) srcpos++;

        // Get the identifier
        srcpos += wordcpy( naming[i].id, &src[srcpos]);
        srcpos++; // skip )

        // Skip the comment
        while (validpos() && nextch(0)!=')') srcpos++;
        srcpos++;

        //printf("Defined naming %d: %s\n", i, naming[i].id);
    }
}

int refnaming(void)
{
    int i, j=-1, maxlen=0;
    char *c;

    if (nextch(0)!='(') return -1;
    // srcpos points to open paren (

    // Is it a valid naming, i.e. reference to a register?
    for (i=0; i<16; i++) {
        c = naming[i].id;
        if (c[0]!='\0' && !wordcmp(&src[srcpos+1],c)) {
            //printf("found=%s\n",c);
            if (strlen(c)>maxlen) {
                    j=i;
                    maxlen = strlen(c);
                    //printf("largest=%s\n",c);
            }
        }
    }
    if (j != -1) {
        srcpos += maxlen + 2; /* Including opening paren */
        return j;
    }
    else asmerror("Invalid register naming");

    asmerror("Opening naming parenthesis only");
    return -1;
}


void definesymbol(void)
{
    int i, v, x;
    if (nextch(0)=='@')
    {
      /* Address symbol definition (local) */

        srcpos++; /* skip @ */
        i = asympos++;
        srcpos += wordcpy( asym[i].label, &src[srcpos]);
        asym[i].val = imgpos;

         //printf("Define@: '%s' = %d\n", asym[i].label, asym[i].val);
    }
    else while (nextch(0)=='[')
    {
        /* Symbol definition stored in LUT (global) */

        srcpos++; /* skip [ */
        i = lsympos++;
        v = asympos++;
        wordcpy( lsym[i].label, &src[srcpos]);
        srcpos += wordcpy( asym[v].label, &src[srcpos]);

        if (nextch(0)==']') {
            lsym[i].val = imgpos;
            asym[v].val = imgpos;
        }
        else {
            skipspace();
            x = parsenum();
            lsym[i].val = x;
            asym[v].val = x;
        }

        //printf("Define[: '%s' = %d \n", lsym[i].label, lsym[i].val);
        srcpos++; /* Skip ] */
        while (validpos() && nextch(0)==' ') srcpos++;
    }
    if (nextch(0)=='(') definenaming();
}


int getoffset( void)
{
   int offs;
   int i, ifound=asympos, minlen;
   int closestoffs = 0x10000;

   if (nextch(0)=='@')
   {
     srcpos++;
     for (minlen=0; minlen<labelsize; minlen++)
          if (space(nextch(minlen))) break;

     for (i=0; i<asympos; i++) {
       if (strlen(asym[i].label) < minlen) continue;
       if (!wordcmp( &src[srcpos], asym[i].label)) {

         offs = asym[i].val - imgpos;
         ifound=i;
         if (abs(offs)<abs(closestoffs)) {
             closestoffs = offs;
         }
       }
     }

     if (ifound==asympos) {
         while (validpos() && !space(nextch(0))) srcpos++;
         if (pass==2) asmerror("Pass 2 offset not resolved");
     }
     else srcpos+=strlen(asym[ifound].label);
   }

   return closestoffs == 0x10000 ? -1 : closestoffs;
}

int te_isdigit(char c)
{
    if ( (c >= '0') && (c <= '9') ) return c-'0';
    else return -1;
}

int getregfield(void)
{
    int loopc, maxindex, maxlen=0;
    char *c;
    int rval = -1;
    int regindex;

    regindex = refnaming();
    if (regindex >= 0) {
        //printf("getregfield returns refnaming value %d (%s)\n",
          //regindex, naming[regindex].id);
        return regindex;
    }

    for (loopc=0; loopc<16; loopc++)
    {
            c = fields[loopc].name;
            if ((!wordcmp(&src[srcpos],c)) && (strlen(c)>maxlen)) {
                maxindex = loopc;
                maxlen = strlen(c);
            };
    }
    if (maxlen != 16) {
        srcpos += maxlen;
        //printf("Reg found %s\n", c);
        return maxindex;
    }

    return rval;
}


int getopcodefield(void)
{
    int loopc, maxindex, maxlen=0;
    char *c;

    for (loopc=16; loopc<32; loopc++)
    {
            c = fields[loopc].name;
            if ((!wordcmp(&src[srcpos],c)) && (strlen(c)>maxlen)) {
                maxindex = loopc;
                maxlen = strlen(c);
            };
    }
    if (maxlen) {
       srcpos+=maxlen;
       optype = fields[maxindex].optype;
       return maxindex-16;
    }
    return -1;
}


int getlutindex(void)
    {
        int loopc, maxindex, maxlen=0;
        char *c;

        if (nextch(0)!='@') return -1;
        srcpos++;

        for (loopc=0; loopc<lsympos; loopc++)
        {
                c = lsym[loopc].label;
                if ((!wordcmp(&src[srcpos],c)) && (strlen(c)>maxlen)) {
                    maxindex = loopc;
                    maxlen = strlen(c);
                }
        }
        if (maxlen) {
           srcpos+=maxlen;
           return maxindex;
        }
        else {
           while (validpos() && !space(nextch(0))) srcpos++;
           if (pass==2) asmerror("Pass 2 LUT entry not found");
        }

        return -1;
    }



int combine_unsigned(int needlhs)
{
      /* RHS1 and RHS combine into 8 bit UNSIGNED */
      /* Example: INP */

      int i,lit, val;
      char ch;

      if (needlhs) asmerror("Missing LHS register");

      /* Check if it's a long literal */
      i = parsenum();
      if (i!=0x10000) {
           /* Is a literal */
           lit = i&0xFF;
           if (i>0 && i!=lit)
             asmerror("Long literal exceeds 8 bits (too positive)");
           if (i<0 && !lit&0x80)
             asmerror("Long literal exceeds 8 bits (too negative)");
           rhs2 = lit&0b00001111;
           rhs1 = (lit&0b11110000)>>4;
      }
      else
      if (opcode==1)
      {
           /* INP */
           if ((!wordcmp(&src[srcpos],"VMGETS"))) {
                srcpos += 6;
                rhs1 = 0xF;
                rhs2 = 0xF;
           }
           if ((!wordcmp(&src[srcpos],"VMCELL"))) {
                srcpos += 6;
                rhs1 = 0xF;
                rhs2 = 0xE;
           }
           // Addr ???
           // Bank ???
           if ((!wordcmp(&src[srcpos],"VMTLOAD"))) {
                srcpos += 7;
                rhs1 = 0xF;
                rhs2 = 0xB;
           }
           if ((!wordcmp(&src[srcpos],"LUTRDV"))) {
                srcpos += 6;
                rhs1 = 0xF;
                rhs2 = 0xA;
           }
      }
      else
      if (opcode==2)
      {
           /* OUT */
           if ((!wordcmp(&src[srcpos],"VMEXIT"))) {
                srcpos += 6;
                rhs1 = 0xF;
                rhs2 = 0xF;
           }
           if ((!wordcmp(&src[srcpos],"VMPRN"))) {
                srcpos += 5;
                rhs1 = 0xF;
                rhs2 = 0xE;
           }
           if ((!wordcmp(&src[srcpos],"VMPUTS"))) {
                srcpos += 6;
                rhs1 = 0xF;
                rhs2 = 0xD;
           }
           if ((!wordcmp(&src[srcpos],"VMPUTC"))) {
                srcpos += 6;
                rhs1 = 0xF;
                rhs2 = 0xC;
           }
           if ((!wordcmp(&src[srcpos],"VMPUTNL"))) {
                srcpos += 7;
                rhs1 = 0xF;
                rhs2 = 0xB;
           }
           if ((!wordcmp(&src[srcpos],"VMCELL"))) {
                srcpos += 6;
                rhs1 = 0xF;
                rhs2 = 0xA;
           }
           if ((!wordcmp(&src[srcpos],"VMADDR"))) {
                srcpos += 6;
                rhs1 = 0xF;
                rhs2 = 0x9;
           }
           if ((!wordcmp(&src[srcpos],"VMBANK"))) {
                srcpos += 6;
                rhs1 = 0xF;
                rhs2 = 0x8;
           }
           if ((!wordcmp(&src[srcpos],"VMTSAVE"))) {
                srcpos += 7;
                rhs1 = 0xF;
                rhs2 = 0x7;
           }
           if ((!wordcmp(&src[srcpos],"VMCYCON"))) {
                srcpos += 7;
                rhs1 = 0xF;
                rhs2 = 0x6;
           }
           if ((!wordcmp(&src[srcpos],"VMCYCEND"))) {
                srcpos += 8;
                rhs1 = 0xF;
                rhs2 = 0x5;
           }
           if ((!wordcmp(&src[srcpos],"LUTADDR"))) {
                srcpos += 7;
                rhs1 = 0xF;
                rhs2 = 0x4;
           }
           if ((!wordcmp(&src[srcpos],"LUTWRV"))) {
                srcpos += 6;
                rhs1 = 0xF;
                rhs2 = 0x3;
           }
      }

      return 0;
}


int combine_signed(int needlhs)
{
   /* RHS1 and RHS2 combine into 8 bit SIGNED*/
   /* Example: BRZ */

   int i,lit;
   char ch;
   int isnum=1;

   if (needlhs) asmerror("Missing LHS register");

   i = parsenum();

   if (i == 0x10000) {
       isnum = 0;
       if (opcode!=0) i=getoffset();
       else i=getlutindex();
   }
                                    /* FIXME:  Both exceeds 7 bit range if negative !!!   */
   if (i != -1)
   {
        lit = i&0xFF;
        if (opcode!=0)
        {
            if (i>0 && i!=lit)
               asmerror("Offset exceeds 8 bits (too positive)");
            if (i<0 && !lit&0x80)
               asmerror("Offset exceeds 8 bits (too negative)");
        }
        else if (isnum)
        {
            lit = i&0b0000000000111111; /* 6 bit */
            if (i>0 && i!=lit)
               asmerror("Offset exceeds 7 bit range (too positive)");
            if (i<0 && !lit&0b100000)
               asmerror("Offset exceeds 7 bit range (too negative)");

            lit |= 0b10000000;
        }

        rhs1 = (lit&0b11110000)>>4;
        rhs2 = lit&0b00001111;
   }
   else if (pass==2)
        asmerror("Pass 2 LUT entry not found (missing @)");
   else {
           rhs1 = 0;
           rhs2 = 0; /* dummy reference */
   }

   return 0;
}

int combine_regs(int needlhs)
{
          /* RHS1 and RHS2 are both register selectors */
          /* Examples: ADD, EOR */

      int i,lit, val;
      char ch;

          rhs1 = getregfield();
          if (needlhs) lhs = rhs1;
          if (rhs1 == -1) asmerror("Unknown RHS1 2reg operand");

          while (space(nextch(0))) srcpos++; /* Skip intermittent space */

          rhs2 = getregfield();
          if (rhs2 == -1) asmerror("Unknown RHS2 2reg operand");

      return 0;
}

int combine_regshort(int needlhs)
{
   /* RHS1 is a register, RHS2 is a short literal */
   /* Example: CPY (signed), LSL (unsigned) */

    int i,lit, val;
    char ch;

    rhs1 = getregfield();
    if (needlhs) lhs = rhs1;
    if (rhs1 == -1) asmerror("Unknown RHS1 1reg operand");

    while (space(nextch(0))) srcpos++; /* Skip intermittent space */

    /* Try short literal */
    i = parsenum();
    if (i!=0x10000) {
        /* Is a literal */
        lit = i&0xF;
        if (i>0 && i!=lit)
            asmerror("Short literal exceeds 4 bits (too positive)");

        if ((opcode==8) && i>0 && i>7)
            asmerror("Short literal exceeds signed range");

        if (i<0 && !lit&0x8)
            asmerror("Short literal exceeds 4 bits (too negative)");
        rhs2 = lit;
    }
    else if ((i=getoffset()) != -1) {
        /* Check if it's a @ relative offset */
        lit = i&0xF;
        if (i>0 && i!=lit)
            asmerror("Branch offset exceeds 4 bits (too positive)");
        if (i<0 && !lit&0x80)
            asmerror("Branch offset exceeds 4 bits (too negative)");
        rhs2 = lit&0b00001111;
        /* printf("Relative offset found: %d\n",i); */
    }

    if (rhs2 == -1) {
        switch (opcode) {
          case 8:
          case 9:
          case 10:
          case 11:
            rhs2 = 0;
            break;

          case 12:
          case 13:
            rhs2 = 1;
            break;
          default:
            if (pass==2)
                asmerror("Pass 2 branch offset not found or invalid");
            else {
               /* printf("Pass 1 branch offset not found or invalid\n"); */
               rhs2 = 0; /* dummy reference */
            }
        }
    }
    return 0;
}

int getshortlit(int i) {
    int lit;
    if (i!=0x10000) {
        /* Is a literal */
        lit = i&0b111;
        if (i>0 && i!=lit)
            asmerror("Short literal exceeds 3 bits (too positive)");
        if (i<0 && !lit&0x4)
            asmerror("Short literal exceeds 3 bits (too negative)");
        printf ("Lit: %d\n",lit);
        return lit;
    }
    else return 0;
}


int inlinedefs(void)
{
   int i,lit, val;
   char ch;

    if (skipspace()) return 1;
    definesymbol();

   while (validpos())
   {
      if (skipspace()) return 1;
      definesymbol();

      if ( (i=parsenum()) != 0x10000 )
      {
          lit = i&0xFFFF;
          if (i>0 && i!=lit)
              asmerror("Literal exceeds 16 bits (too positive)");
          if (i<0 && !lit&0x8000)
              asmerror("Literal exceeds 16 bits (too negative)");
          te_MEM[imgpos++] = lit;
          //printf(" *Compiled literal: %d\n",lit);
      }
      else if (nextch(0)=='"')
      {
          srcpos++;
          i=1;
          while (validpos()) {
              if (nextch(0)=='"') {
                if (nextch(1)!='"') {
                    if (!(i%2)) {
                        //printf("*%04X>", te_MEM[imgpos]);
                        if (!(te_MEM[imgpos]&0x00FF)) te_MEM[imgpos] += 32;
                        //printf("%04X ", te_MEM[imgpos]);
                        imgpos++;
                    }
                    else {
                        //printf("+%04X>", te_MEM[imgpos-1]);
                    }
                    break;
                }
              }
              if (i%2) { /* 3 = ASCII End Of Text */
                  te_MEM[imgpos] = (nextch(0)<<8);
              }
              else {
                  te_MEM[imgpos] = (te_MEM[imgpos]&0xFF00) + nextch(0);
                  //printf("%04X ", te_MEM[imgpos]);
                  imgpos++;
              }
              i++;
              srcpos++;
          }
          srcpos++;
      }
      else if ( (nextch(0) >= 'A' && nextch(0) <= 'Z')
                    && (nextch(1)>='A' && nextch(1)<='Z')
                    && (nextch(2)>='A' && nextch(1)<='Z')
                    && (nextch(3)>='A' && nextch(1)<='Z') ) {
                 for (i=0; i<asympos; i++) {
                   if (!wordcmp( &src[srcpos], asym[i].label)) {
                     te_MEM[imgpos++] = asym[i].val;
                     srcpos+=strlen(asym[i].label);
                     break;
                   }
                 }
                 if (i==asympos) {
                     while (!space(nextch(0))) srcpos++;
                     te_MEM[imgpos++] = 0;
                 }
      }
      else break;
   }
   return 0;
}


void assemble( void)
{
      int needlhs = 0;

      if (inlinedefs() || !validpos()) return;

      /* If anything, the rest of the line is a four-field suite or
         a comment */

      lhs = rhs1 = rhs2 = opcode = optype = -1;

      /* Parse LHS, can be abs/rel register name or a mnemonic,
         if LHS = RHS1 */

      if ( ((opcode=getopcodefield()) != -1) ) needlhs = 1;
      else
      {
          lhs = getregfield();
          if (lhs == -1) asmerror("Unknown left-hand operand");

          /* Parse mnemonic */

          if (skipspace()) return;
          opcode = getopcodefield(); /* Sets optype as side effect */
          if (opcode == -1) asmerror("Unknown opcode mnemonic");
      }

      /* We now have opcode and optype defined. Parsing operands
         is now dependent on optype. */

      //printf("lhs %d opcode %d optype %d\n",lhs, opcode, optype);

      if (skipspace() && opcode!=9) return;

           if (optype == 0) combine_unsigned( needlhs );
      else if (optype == 1) combine_signed( needlhs );
      else if (optype == 2) combine_regs( needlhs );
      else if (optype == 3) combine_regshort( needlhs );
      else asmerror("Unknown optype");

      if (rhs1 == -1) asmerror("Unknown leftover RHS1 operand");
      if (rhs2 == -1) asmerror("Unknown rightover RHS2 operand");

      /* If we've gotten this far, we have a valid instruction. */

      //printf("%04X: L%04d %d %d (%s) %d %d\n", imgpos, linenum(), lhs,
      //    opcode, fields[opcode+16].name, rhs1, rhs2);
      te_MEM[imgpos++] = (opcode<<8) + (lhs<<12) + (rhs1<<4) + rhs2;
}


/*  Parse the source text in memory */

    void parse(void)
    {
        srcpos = 0; /* points to current character in assembly source */
        imgpos = 0; /* points to current insert position in data memory */
        while (validpos())
        {
         inlinedefs();  /* Parses a code label and one or more defs */
         assemble();
        }
    }

///////// PART 2 - SIMULATOR /////////////////////////////////////////////

    void vminp(uint16_t port, uint16_t* val)
    {
        int i,j;
        uint32_t addr;
        char k;
        char *p0, *p1;
        uint16_t* ptr = &te_MEM[*val];
        FILE* f;
        uint32_t length;
        char *buffer;

        switch(port) {
            case 0xFF: /* VMGETS */
                for (j=0;j<72;j++) ptr[0]=' ';
                fgets( (char*) ptr, 72, stdin);
                i=0;
                p0 = (char*) ptr;
                p1 = p0;
                while ( p0[0] != '\n' ) {i++; p0++;}

                p1[i]=' ';
                p1[i+1]='\0';
                p1[i+2]=' '; /* Ensures STRLEN function works w/ VMGETS */

                for (j=0;j<i+1;j+=2) {
                        k = p1[j];
                        p1[j] = p1[j+1];
                        p1[j+1]=k;
                }

                break;

             case 0xFE: /* VMCELL */
                addr = ((vmbank<<16) + vmcell)*2;
                if (addr<srclength) {
                    *val = (src[addr]<<8) + src[addr+1];
                }
                break;
             case 0xFD: /* VMADDR */
                *val = vmaddr;
                break;
             case 0xFC: /* VMBANK */
                *val = vmbank;
                break;
             case 0xFB: /* VMTXTLD */
                f = fopen( "8T0Wide.asm","rb");
                if (f)
                {
                    fseek( f, 0, SEEK_END);
                    length = ftell( f) + 1;
                    fseek( f, 0, SEEK_SET);
                    buffer = malloc (length);
                    if (buffer) {
                      fread (buffer, 1, length-1, f);
                      buffer[length]='\0';
                    }
                    // must now copy/convert to big endian at A000
                    //for (i=0; i<length; i+=2) {
                    //    te_MEM[i+0xA000] = (buffer[i]<<8) + buffer[i+1];
                    //    printf("%c%c", buffer[i], buffer[i+1]);
                    //}
                    //te_MEM[i+0xA000] = '\0';
                    fclose( f);
                    free(buffer);
                }
                break;
             case 0xFA: /* LUTRDV */
                *val = te_LUT[lutaddr];
            }

    }


    void vmout(uint16_t port, uint16_t* val)
    {
      int i,j;
      uint32_t addr;
      uint16_t* ptr = &te_MEM[*val];
        switch(port) {
            case 0xFF: /* VMEXIT */
                //for (i=0;i<20;i++) {
                //    j = te_MEM[0x8050+i];
                //    printf("%c%c",j>>8, j&0xFF);
                //}
                printf("\n(VMEXIT)\n");
                exit(0);
                break;
            case 0xFE: /* VMPRN */
                printf("%04X = %d (%c%c)\n", *val,
                   *val, *val>>8, *val&255);
                break;
            case 0xFD: /* VMPUTS */
                while (ptr[0]) {
                    printf("%c%c", (ptr[0]>>8)&0x7F, ptr[0]&0x7F);
                    ptr++;
                }
                break;
            case 0xFC: /* VMPUTC */
                printf("%c", *val);
                break;
            case 0xFB: /* VMPUTNL */
                printf("\n");
                break;
            case 0xFA: /* VMCELL */
                addr = ((vmbank<<16) + vmcell)*2;
                if (addr<srclength) {
                    src[addr] = *val>>8;
                    src[addr+1] = *val & 0xFF;
                }
                break;
            case 0xF9: /* VMADDR */
                vmaddr = *val;
                break;
            case 0xF8: /* VMBANK */
                vmbank = *val;
                break;
            case 0xF7: /* VMTSAVE */
                // A000
                break;
            case 0xF6: /* VMCYCON */
                printf("\nReset cycle counter\n");
                cycles=0;
                break;
            case 0xF5: /* VMCYCEND */
                printf("Cycle counter read-out: %d\n", cycles);
                break;
            case 0xF4: /* LUTADDR */
                lutaddr = *val;
                break;
            case 0xF3: /* LUTWRV */
                te_LUT[lutaddr] = *val;
                break;
        }
    }




void te_prbin(uint16_t val) {             // Convert 16 bit value to
int i = 32768;                            // binary representation
        while (val || i) {
            printf("%d", val/i ? 1 : 0);
            val %= i;
            i /= 2;
        }
}


uint16_t signednybble(uint16_t nybble)
{
    // Sign-extend four-bit value
    nybble &= 0xF;
    return (nybble & 0b1000) ? -1*((0b1111^nybble)+1) : nybble;
}

uint16_t signedbyte(uint16_t byte)
{
    // Sign-extend eight-bit value
    byte &= 0xFF;
    return (byte & 0x80) ? -1*((0xFF^byte)+1) : byte;
}

void op_cca(void)
{
    // CCA Compute Carry
    uint32_t widesum = (uint32_t) *rhs1ref + (uint32_t) *rhs2ref;
    *lhsref = (widesum > 0xFFFF) ? 1:0;
    if (debug) printf(" CCA ");
}

void op_lod(void)
{
    // LOD Load from Memory
    uint16_t offset = *rhs1ref + signednybble(rhs2op);
    *lhsref = te_MEM[offset & 0xFFFF];
    if (debug) printf(" LOD ");
}

void op_sto(void)
{
    // STO Store into Memory
    uint16_t offset = *rhs1ref + signednybble(rhs2op);
    te_MEM[offset & 0xFFFF] = *lhsref;
    if (debug) printf(" STO ");
}

void op_get(void)
{
    // ADL Copy Register Add Literal
    *lhsref = (*rhs1ref + signednybble(rhs2op));
    if (debug) printf(" ADL ");
}

void op_lsl(void)
{
    // LSL Logical Shift Left
    *lhsref = (*rhs1ref << rhs2op);
    if (debug) printf(" LSL ");
}

void op_lsr(void)
{
    // LSR Logical Shift Right
    *lhsref = (*rhs1ref >> rhs2op);
    if (debug) printf(" LSR ");
}

void op_add(void)
{
    // ADD Add Register to Register
    *lhsref = *rhs1ref + *rhs2ref;
    if (debug) printf(" ADD %04X %04X ", *rhs1ref, *rhs2ref);
}

void op_com(void)
{
    // COM Complement bits and add literal
    *lhsref = (*rhs1ref ^ 0xFFFF) + rhs2op;
    if (debug) printf(" COM ");
}

void op_and(void)
{
    // AND Boolean AND
    *lhsref = *rhs1ref & *rhs2ref;
    if (debug) printf(" AND %04X %04X ", *rhs1ref, *rhs2ref);
}

void op_eor(void)
{
    // EOR Boolean EOR
    *lhsref = *rhs1ref ^ *rhs2ref;
    if (debug) printf(" EOR %04X %04X ", *rhs1ref, *rhs2ref);
}

void op_ior(void)
{
    // IOR Boolean IOR
    *lhsref = *rhs1ref | *rhs2ref;
    if (debug) printf(" IOR %04X %04X ", *rhs1ref, *rhs2ref);
}

void op_bnz(void)
{
    // BNZ Branch if LHS not zero
    int i = signedbyte((rhs1op<<4) + rhs2op) - 1;
    if (*lhsref) reg[IP] += i;
    if (debug) printf(" BNZ %04X? %d ", *lhsref, i);
}

void op_brz(void)
{
    // BRZ Branch if LHS zero
    int i = signedbyte((rhs1op<<4) + rhs2op) - 1;
    if (*lhsref==0) reg[IP] += i;
    if (debug) printf(" BNZ %04X? %d", *lhsref, i);
}

void op_inp(void)
{
    // INP Input
    if (debug) printf(" INP ");
    vminp((rhs1op<<4) + rhs2op, lhsref);
}

void op_out(void)
{
    // OUT Output
    if (debug) printf(" OUT ");
    vmout((rhs1op<<4) + rhs2op, lhsref);
}

void op_lut(void)
{
    // LUT Use look-up table
    uint16_t j, i = (rhs1op<<4) + rhs2op;
    if (i & 0x80) {
            i &= 0x7F;
            j = (i & 0b1000000) ? -1*((0b1111111^j)+1) : i;
            if (debug) printf(" LUT %d ", j);
    }
    else {
        j = lsym[i].val;
        if (debug) printf(" LUT %s = %04X ", lsym[i].label, j);
    }
    *lhsref = j;
}


uint16_t* ref(uint16_t nybble)
{
    if (nybble & 0b1000)
        return &te_MEM[reg[FP] + (nybble & 0b111)];
    else
        return &reg[nybble & 0b0111];
}


void run(void)
{
    uint16_t iw, opcode;
    cycles = 0;
    //flag = 0x40; debug = 1;
    int32_t i, j;
    reg[FP] = 0xFFF8;

    while (1)
    {
/*
          if (reg[IP]==0x3F3) { // Watch out, pre-incremented!
             printf("\n");
             for (i=0x840; i<0x859+32; i++) {
                         printf("%04X (%04X) ", i, te_MEM[i]);
             }
             printf("\n\n");
          }
*/
        cycles++;
        iw = te_MEM[reg[IP]++];

        lhsop = (iw & 0xF000) >> 12;
        opcode = (iw & 0xF00) >> 8;
        rhs1op = (iw & 0xF0) >> 4;
        rhs2op = iw & 0xF;

        lhsref = ref(lhsop);
        rhs1ref = ref(rhs1op);
        rhs2ref = ref(rhs2op);

        if (debug) printf("\n%04X: ", reg[IP]-1);

        switch (opcode)
        {
            case 0:  op_lut(); break;
            case 1:  op_inp(); break;
            case 2:  op_out(); break;
            case 3:  op_cca(); break;
            case 4:  op_add(); break;
            case 5:  op_and(); break;
            case 6:  op_eor(); break;
            case 7:  op_ior(); break;
            case 8:  op_get(); break;
            case 9:  op_com(); break;
            case 10: op_lod(); break;
            case 11: op_sto(); break;
            case 12: op_lsl(); break;
            case 13: op_lsr(); break;
            case 14: op_brz(); break;
            case 15: op_bnz(); break;
        }
    }
}


void exportimg( void)
{
    int i=0, j, k;
    FILE *f = fopen( "8T0img.txt", "wb");
    fprintf( f, "8T0 ASCII Dump\n\n");
    while (i<imgpos+1) {
        fprintf( f, "%04X: ", i);
        for (j=0;j<14;j++) {
            fprintf( f, "%04X ", te_MEM[i+j]);
            if (i+j>=imgpos-1) break;
        }
        fprintf( f, "\n");
        i += 14;
    }
    fprintf( f, "\n");  // te expects double newline
    fclose( f);

    // Export to Logisim (freeware tool by Carl Burch)
    f = fopen( "8T0Logisim.img", "wb");
    fprintf( f, "v2.0 raw\n");
    i=0;
    while (i<imgpos+1) {
       // k = te_MEM[i] & 0xFF;
       // j = te_MEM[i] >> 8;
       // fprintf( f, "%02X %02X\n", j, k);
        fprintf( f, "%04X\n", te_MEM[i]);
        i++;
    }
    fclose( f);
}

/*  Main function */

    int main(int argc, char* argv[])
    {
        uint16_t dict, dict0;
        debug = 0;
        char *s;
        int i,j, len, padlen, pos0;
        for (i=0;i<cellcount;i++) { te_MEM[i] = 0; te_LUT[i] = 0; }
        prhello();
        src = slurp("8t0.asm");

        pass = 1;
        parse();
        asympos2=asympos;
        lsympos2=lsympos;

        pass = 2;
        parse();

        for (i=0;i<8;i++) reg[0]=0;

        // 8T0 LUT label injection
        // imgpos points to top dictionary entry, last cell
        // find DICT label for beginning of top dictionary entry
        dict0 = lsym[lsympos2-2].val; // DICT is penult defined LUT label in 8T0
                                      // TOP is last entry
        for (i=1; i<=lsympos2; i++) {
            //    printf("%s ",lsym[i-1].label);
            //    if (!(i%8)) printf("\n");
                // Populate LUT RAM
                te_LUT[i-1] = lsym[i-1].val;
            pos0 = imgpos;
            dict = imgpos;
            te_MEM[imgpos++] = 6; // type label
            te_MEM[imgpos++] = 1; // subtype lut
            te_MEM[imgpos++] = i; // index
            s = lsym[i-1].label;
            len = strlen(s);
            te_MEM[imgpos++] = len;
            padlen = (len/2)+1;
            // write out label in BIGENDIAN
            for (j=0;j<len;j+=2) {
                if (s[j+1]!='\0') te_MEM[imgpos++] = (s[j]<<8) + s[j+1];
                else te_MEM[imgpos++] = (s[j]<<8) + 32;
            }
            if (!(len%2)) te_MEM[imgpos++] = 0x2020;
            te_MEM[imgpos++] = dict0; // Link back to previous entry
            dict0 = dict;

            // printf(" %04X: ", pos0);
            //for (j=pos0;j<imgpos;j++) {
            //    printf("%04X ",te_MEM[j]);
            //}
            //printf("\n");
        }

        lsym[lsympos2-2].val = dict0;  // write updated DICT ptr
        lsym[lsympos2-1].val = imgpos; // update TOP ptr

        // LUT patching
        for (i=0; i<lsympos2; i++) {
            te_MEM[i] = lsym[i].val;
        }

        printf("LUT %d/128 MEM %d/65536\n", i-1, imgpos);

       // for (i=1; i<=asympos2; i++) {
       //         printf("%s ",asym[i-1].label);
       //         printf("(%04X) ",asym[i-1].val);
       //         if (!(i%8)) printf("\n");
       // }

       // for (i=0x4FC; i<0x4FC + 80; i++) {
       //         printf("%04X (%04X) ", i, te_MEM[i]);
       //}

        exportimg();
        // run();   // commented out Feb 6 16
    }




