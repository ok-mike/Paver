; T2 ADL L1 2 ; 2 is not recognized if ADD
; Silent error if you write T1 ADL 0 !
; T0 REF L3
; ADL @LEXMATCH gives no error
; ADL minus sign doesn't work
; L6 ADL T1 ; Still an error if comment removed
; @REP2
; Implement: can leave conditional reg, use recently used dest register
; L4 REF Fh doesn't work! L4 REF 15 does.
; SLAM function: copy dictionary etc down onto DASM/ASM stuff (WIPE)
; Always prefix REF by @ even numbers
; T1 ADL L1 2             ; 2 is not recognized if ADD

This is the bootstrap firmware "80Zero" for Cyf processor systems.
Copyright 2015 Michael Mangelsdorf, Waldkirch, Germany. All rights reserved.

; Following are 127 place holders for LUT entries
; First LUT entry is a branch to INIT
; All entries get patched in by cyf after assembly

0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0  0 0 0 0 0 0 0

[BOOT F7Fh] ; Corresponds to IP BNZ @INIT
[SCRBUF 8010h] [CINBUF 8050h] [LINBUF 7000] [MSB 8000h] [ASCIIA 65] [ASCII0 48]
[ASCIIALC 97] [TEXT A000h] [BUFFER B000h] [TOP4 F000h] [ATSIGN 64] [NEWLINE 10]
[LSB 1] [LOBYTE 00FFh] [HIBYTE FF00h] [FFFF FFFFh] [FFFE FFFEh] [CLUSTER 4000h]
[STACK 4500h] [SYSTAB 4600h] [FRAME D000h] [LEXBUF 6000h]
[FFF0 FFF0h] [BUFFER1 B400h] [SPACE 2020h] [ASMBUF C000h]
[GTSIGN 62] [LTSIGN 60] [SOURCE E000h] [FOUR 4] [FIVE 5]

[INIT]         SP REF @STACK
               FP REF @FRAME

               T0 REF @DICT
               T1 REF @SYSTAB
               T0 STO T1                 ; Top entry in symbol dictionary

               T0 REF @TOP
               T0 STO T1 1               ; End of top entry (after parfield)

               T0 REF @SOURCE
               T1 REF 0
               L1 REF @ASMBUF
               T2 ADL L1

               L0 ADL IP 1
               IP REF @ASMO

               L0 ADL IP 1
               IP ADL L1

               IP OUT VMEXIT

------------------------------------------------------------------------------

Read in lines of text and dispatch commands.

[CMDLIN]          ADL FP -7*

               L1 REF @LINBUF

@GETCMD        L1 INP VMGETS
               L2 REF @COMPATT
               L3 REF @SCRBUF

@REP           T0 ADL L1
               T1 REF 0
               T2 ADL L3
               T3 LOD L2
                  ADL L2 1
               T3 BRZ @GETCMD

               L0 ADL IP 1
               IP REF @COLLECT

               T2 BRZ @REP
               T3 BRZ @GETCMD

               T0 ADL L3
               T1 ADL T2

               L0 ADL IP 1
               IP ADL T3

               IP BNZ @GETCMD

------------------------------------------------------------------------------

[EXIT]         IP OUT VMEXIT

------------------------------------------------------------------------------

[VMTXTLD]         ADL FP -7*

    L0 REF 1
    L0 OUT VMPRN

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

[VMTXTSV]         ADL FP -7*

    L0 REF 2
    L0 OUT VMPRN

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

[TEST]            ADL FP -7*

               T0 REF @SOURCE
               T1 REF 0
               L1 REF @ASMBUF
               T2 ADL L1

               L0 ADL IP 1
               IP REF @ASMO

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------
; TODO REPLACE MLIST by the inverse of COLLECT, using output patterns!
Input: T0 par string, T1 elements in par string
Return: Formatted output into @BUFFER

[MLIST]           ADL FP -7*

               L2 REF @BUFFER          ; Initial string base address
               L5 REF 4                ; Number of lines

               T2 REF 1                ; Check if called with or without parm
                  COM T2 1
                  ADD T1 T2
               T2 REF @MEMLISTA
               T1 BRZ @GETPARM

               L1 LOD T0 2             ; This is the memory address
               L1 STO T2               ; Store as default address

@GETPARM       L1 LOD T2               ; Load new default address
@REP           L3 REF 0                ; Initial string index

               T0 ADL L2               ; First, print address in hex
               T1 ADL L3
               T2 REF 1                ; Pad with zeros
               T3 REF 16
               T4 ADL L1
               L0 ADL IP 1
               IP REF @NUM2STR
               L3 ADL T0 1             ; Update string index

               T0 ADL L2
               T1 ADL L3
               T2 REF 58               ; ASCII colon
               L0 ADL IP 1
               IP REF @STBYTE
                  ADL L3 1

               T0 ADL L2
               T1 ADL L3
               T2 REF 32               ; ASCII space
               L0 ADL IP 1
               IP REF @STBYTE
                  ADL L3 1

               L4 LOD L1               ; This is the value

               T0 ADL L2               ; Hex output
               T1 ADL L3
               T2 REF 1
               T3 REF 16
               T4 ADL L4
               L0 ADL IP 1
               IP REF @NUM2STR
               L3 ADL T0

               T0 ADL L2
               T1 ADL L3
               T2 REF 32               ; ASCII space
               L0 ADL IP 1
               IP REF @STBYTE
                  ADL L3 1

               T0 ADL L2               ; Decimal output
               T1 ADL L3
               T2 REF 1
               T3 REF 10
               T4 ADL L4
               L0 ADL IP 1
               IP REF @NUM2STR
               L3 ADL T0

               T0 ADL L2
               T1 ADL L3
               T2 REF 32               ; ASCII space
               L0 ADL IP 1
               IP REF @STBYTE
                  ADL L3 1

               T0 ADL L2               ; Decimal output (signed)
               T1 ADL L3
               T2 REF 1
               T3 REF 10
               T4 ADL L4
               L0 ADL IP 1
               IP REF @SNUM2STR
               L3 ADL T0

               T0 ADL L2
               T1 ADL L3
               T2 REF 32               ; ASCII space
               L0 ADL IP 1
               IP REF @STBYTE
                  ADL L3 1

               T0 ADL L2               ; Binary output
               T1 ADL L3
               T2 REF 1
               T3 REF 2
               T4 ADL L4
               L0 ADL IP 1
               IP REF @NUM2STR
               L3 ADL T0

               T0 ADL L2
               T1 ADL L3
               T2 REF 32               ; ASCII space
               L0 ADL IP 1
               IP REF @STBYTE
                  ADL L3 1

               T0 ADL L2               ; Disassembly
               T1 ADL L3
               T2 ADL L4
               L0 ADL IP 1
               IP REF @DASM
               L3 ADL T0

               T0 ADL L2
               L2 OUT VMPUTS
               L2 OUT VMPUTNL

                  ADL L1 1
                  ADL L5 -1
               L5 BNZ @REP


                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Determine string length, address in T0, index in T1, terminator1 in T2,
terminator2 in T3


Return length in T0, last char in T1

[STRLEN]          ADL FP -7*

               L1 REF 0                ; String length in bytes
               L2 COM T2 1
                  COM T3 1
               L3 LSR T1
                  ADD T0 L3
               L3 LOD T0
               L4 REF @LSB
                  AND L4 T1
               L4 BNZ @ODD

@EVEN1         L4 LSR L3 8
               L6 ADL L4
                  ADD L4 L2
               L4 BRZ @EOSTR
               L4 ADD L6 T3
               L4 BRZ @EOSTR
               L5 ADL L6
                  ADL L1 1

@ODD           L4 REF @LOBYTE
                  AND L4 L3
               L6 ADL L4
                  ADD L4 L2
               L4 BRZ @EOSTR
               L4 ADD L6 T3
               L4 BRZ @EOSTR
               L5 ADL L6
                  ADL L1 1

                  ADL T0 1
               L3 LOD T0
               IP BNZ @EVEN1

@EOSTR         T0 ADL L1
               T1 ADL L5

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Compare T0 and T1.
Return T0 is FFFF if T0 greater T1, or 0 if T0 not greater T1.

[AGTB]            ADL FP -3*

               L1 REF @FFFF
               T1 BRZ @DONE
                  COM T1 1
               L2 ADD T1 T0
               L2 BRZ @EQ
               L2 CCA T1 T0
               L2 BNZ @DONE

@EQ            L1 REF 0
@DONE          T0 ADL L1
                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

ASCII character in T0, number base in T1. Return number in T0.
If character valid for number base T1 is FFFF else zero.

[ASC2NUM]         ADL FP -5*

               L1 ADL T0               ; Get the ASCII character
               L4 ADL T1
               L2 REF @ASCII0          ; Subtract the ASCII code for 0 from it
                  COM L2 1
                  ADD L2 L1

               T0 REF 10
               T1 ADL L2
               L0 ADL IP 1
               IP REF @AGTB
               T0 BNZ @DONE

               L2 REF @ASCIIA          ; Not a decimal digit.
                  COM L2 1             ; Try a letter (extended) digit.
                  ADD L2 L1            ; Subtract ASCII T0 from it and add 10
               L3 REF 10
                  ADD L2 L3

@DONE          T0 ADL L4
               T1 ADL L2
               L0 ADL IP 1
               IP REF @AGTB            ; Digit must be smaller than base
               L3 REF 0
               T0 BRZ @SUCC
               L3 REF @FFFF

@SUCC          T0 ADL L2
               T1 ADL L3

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Base address T0, index T1, return char T0

[LDBYTE]          ADL FP -4*

               Since each cell contains two bytes, the cell index from
               the start address is the byte index divided by two.
               We also need to keep track of whether the index is even
               or odd to select the byte within the indexed cell.

               L1 REF @LSB
               L2 AND T1 L1        One if LSB set (odd), else zero (even)
               L1 LSR T1           Divide by 2 to obtain the cell index
               L3 ADD T0 L1        Address of cell that contains the byte
               T0 LOD L3           Get the cell that contains the byte

               L2 BRZ @EVEN

               L2 REF @LOBYTE
                  AND T0 L2
               IP BNZ @SKIP

@EVEN             LSR T0 8         Shift down by 8, high order becomes zero

@SKIP             ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

[UMUL]            ADL FP -6*

               L1 ADL T1
               T1 REF 0                ; Prepare high order shift register
               L2 REF 16               ; Set loop counter to number of bits
               L3 REF 1                ; This is a mask to determine LSB
               L4 REF @MSB

@STEP          L5 AND T0 L3            ; Check if LSB set
               L5 BRZ @NOADD           ; Add only if LSB set
                  ADD T1 L1
@NOADD         L5 AND T1 L3            ; Save this bit, becomes low order MSB
                  LSR T1
                  LSR T0
               L5 BRZ @NOC             ; If high order LSB was clear, done
                  IOR T0 L4            ; Else set low order MSB

@NOC              ADL L2 -1            ; Decrement counter
               L2 BNZ @STEP            ; Repeat multiply step until zero

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Convert unsigned number string.
String pointer T0, index T1, base T2, digits T3
Return number in T0, if error T1 not zero

[STR2NUM]         ADL FP -7*

               L1 ADL T0               ; String pointer
               L2 ADL T1               ; String byte index
               L3 ADL T2               ; Number base
               L4 ADL T3               ; Number of digits to convert
                  ADD L2 L4
                  ADL L2 -1
               L5 REF 1                ; Multiplier
               L6 REF 0                ; Initialise result

@REP1          L5 BRZ @DONE            ; Flag 0 if multiplier too big
               T0 ADL L1
               T1 ADL L2
               L0 ADL IP 1
               IP REF @LDBYTE          ; Get current byte

               T1 ADL L3               ; T0 is already valid by prev call
               L0 ADL IP 1
               IP REF @ASC2NUM         ; Convert and validate ASCII > number

               T1 BRZ @DONE
               T1 ADL L5               ; T0 already set by prev call
               L0 ADL IP 1
               IP REF @UMUL
               T1 BNZ @DONE            ; If the product exceeds 16 bits, fail

               T1 CCA L6 T0            ; Check whether result overflows 16 bit
                  ADD L6 T0            ; Add the digit value to the result
               T1 BNZ @DONE

               T0 ADL L5               ; Multiply the current multiplier by
               T1 ADL L3               ; the base for next order of magnitude
               L0 ADL IP 1
               IP REF @UMUL
               L5 ADL 0
               T1 BNZ @SKIP2           ; Check whether multiplier overflowed
               L5 ADL T0 0

@SKIP2            ADL L2 -1            ; Decrement string index
                  ADL L4 -1            ; Decrement number of digits left
               L4 BNZ @REP1            ; Do next digit

@DONE          T1 ADL L4               ; Store error flag
               T0 ADL L6               ; Store result

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------
;THIS SHOULD RETURN THE NEW INDEX LIKE EVERYONE ELSE
Try to find a decimal, hex or binary number literal in a string.
Wrapper for STR2NUM. String address in T0, index in T1
Return number value in T0, length of number string (0 if error) in T1.

[RECOGNUM]        ADL FP -7*

               L1 ADL T0
               L2 ADL T1
               T2 REF 32
               T3 REF 10
               L0 ADL IP 1
               IP REF @STRLEN
               L3 ADL T0                ; Length of string in bytes

               T0 ADL L1
               T1 ADL L3 -1
                  ADD T1 L2
               L0 ADL IP 1
               IP REF @LDBYTE          ; Get byte before terminator
               L4 ADL T0

               L5 LOD IP 1
               IP BNZ @SKIP
                 "bh"

@SKIP          L6 REF @LOBYTE
                  AND L6 L5            ; L6 is now 'h'
                  LSR L5 8             ; L5 is now 'b'
                  COM L5 1
               T4 ADD L4 L5            ; Subtract 'b'
               L5 ADL L3               ; True length of number literal
               T4 BRZ @BINBASE

                  COM L6 1
               T4 ADD L4 L6            ; Subtract 'h'
               T4 BRZ @HEXBASE
               L6 REF 10               ; Default to decimal
               IP BNZ @SKIP2

@BINBASE       L6 REF 2
               IP BNZ @SHORTEN
@HEXBASE       L6 REF 16
@SHORTEN          ADL L3 -1

@SKIP2         L4 REF 0                ; Assume no minus sign ret val
               T0 ADL L1               ; Test for initial minus sign
               T1 ADL L2
               L0 ADL IP 1
               IP REF @LDBYTE
               T4 REF 45               ; ASCII minus
                  COM T4 1
                  ADD T4 T0
               T4 BNZ @POSIT

                  ADL L2 1             ; Skip the minus sign
                  ADL L3 -1
               L4 REF @FFFF            ; Set sign flag

@POSIT         T0 ADL L1
               T1 ADL L2
               T2 ADL L6
               T3 ADL L3

               L0 ADL IP 1
               IP REF @STR2NUM
               T1 BNZ @ERR

               T1 ADL L5
               L4 BRZ @RET             ; If negative, test validity

               T4 REF @MSB             ; Check if sign bit set
                  AND T4 T0
               T4 BNZ @ERR
                  COM T0 1             ; Two's complement
               IP BNZ @RET

@ERR           T1 REF 0

@RET              ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Addr T0, index T1, byte T2

[STBYTE]          ADL FP -5*

               L1 LSR T1
                  ADD L1 T0
               L2 LOD L1

               L3 REF 1
                  AND L3 T1
               L3 BRZ @EVEN

               L3 REF @HIBYTE
                  AND L3 L2            ; Clear lower order byte
                  IOR L3 T2
               IP BNZ @SKIP

@EVEN          L3 REF @LOBYTE
                  AND L3 L2
                  LSL T2 8
                  IOR L3 T2

@SKIP          L3 STO L1

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

The next function divides two unsigned numbers. The dividend (the number to
be divided) is stored in T0, and the divisor (the number by which T0 is to
be divided) is stored in T1. When the function returns, the quotient is left
in T1, and the modulus (the remainder) is left in T0.


[DIVMOD]          ADL FP -6*       Reserve local variables

               L5 REF 0            Initialise quotient
               L1 REF @MSB
               L2 REF 16           Maximum number of bit shifts
               L3 REF 1            Counter for shifted bits

@SHIFTLEFT     L4 AND L1 T1        Check if divisor MSB set
               L4 BNZ @1REPEAT     If divisor MSB set, break loop
                  LSL T1           Shift divisor left
                  ADL L3 1         Increment bit counter
                  ADL L2 -1        Decrement loop counter
               L2 BNZ @SHIFTLEFT   Repeat until either MSB set or 16 bits

@1REPEAT       L4 COM T1 1
               L2 CCA T0 L4        Carry of subtracting divisor from dividend
                  LSL L5           Shift quotient left
               L2 BRZ @CANT

                  ADD T0 L4        Subtract divisor from dividend
                  ADL L5 1         Set quotient LSB

@CANT             LSR T1           Shift divisor right for next subtraction
                  ADL L3 -1        Decrement counter
               L3 BNZ @1REPEAT

               T1 ADL L5

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Target string address T0, index T1, divisor table ptr T2, number to convert T3,
padding flag T4, return new index T0

[CONVDIG]         ADL FP -7*

               L1 ADL T3
               L2 REF 55
               L3 ADL T0
               L4 ADL T1
               L5 ADL T4
               L6 ADL T2 0

@REPEAT        T0 ADL L1               ; Divide number by current divisor
               T1 LOD L6
               L0 ADL IP 1
               IP REF @DIVMOD
               L1 ADL T0               ; Quotient is the digit to display

               T1 BNZ @STORE           ; If digit is leading zero and
               L5 BRZ @SKIP            ; padding flag not set, suppress output

@STORE         L5 REF @FFFF            ; Clear padding flag, no more zeros

               T4 ADL T1
               T0 ADL T1
               T1 REF 10
               L0 ADL IP 1
               IP REF @AGTB

                  ADD T4 L2            ; Add mapping constant digit >> char
               T0 BNZ @APPEND
               T0 REF 7
                  COM T0 1
                  ADD T4 T0

@APPEND        T2 ADL T4               ; Append byte to number string
               T1 ADL L4
               T0 ADL L3
               L0 ADL IP 1
               IP REF @STBYTE

                  ADL L4 1
@SKIP             ADL L6 1
               L1 BNZ @REPEAT

               T0 ADL L4

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------
Turn padding flag into padding char!
String address T0, index T1, padding flag T2, number base T3, number T4
Base can be 2, 10, or 16, return new index T0

[NUM2STR]         ADL FP -6*

               L1 REF 2            Check if base 2
                  COM L1 1
                  ADD L1 T3
               L1 BNZ @NOT2
               L5 ADL IP 1         Point to table of divisors below
               IP BNZ @DONE

               32768 16384 8192 4096 2048 1024 512 256 128 64 32 16 8 4 2 1

@NOT2          L1 REF 10           Check if base 10
                  COM L1 1
                  ADD L1 T3
               L1 BNZ @NOT10
               L5 ADL IP 1         Point to table of divisors below
               IP BNZ @DONE

               10000 1000 100 10 1

@NOT10         L1 REF 16           Check if base 16
                  COM L1 1
                  ADD L1 T3
               L1 BNZ @ERROR
               L5 ADL IP 1         Point to table of divisors below
               IP BNZ @DONE

               4096 256 16 1

@DONE          L3 REF 0
               T2 BRZ @NOPAD
               L3 REF @FFFF

@NOPAD         T2 ADL L5
               T3 ADL T4
               T4 ADL L3
               L0 ADL IP 1
               IP REF @CONVDIG

@ERROR            ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Wrapper for NUM2STR, prints out a signed number with possible minus sign
String address T0, index T1, padding flag T2, number base T3, number T4
Base can be 2, 10, or 16, return new index T0

[SNUM2STR]        ADL FP -7*

               L1 REF @MSB
                  AND L1 T4
               T4 BRZ @POSIT

               L2 ADL T0
               L3 ADL T1
               L4 ADL T2
               L5 ADL T3
               L6 ADL T4

               T2 REF 45               ; ASCII minus
               L0 ADL IP 1
               IP REF @STBYTE

               T0 ADL L2
               T1 ADL L3 1
               T2 ADL L4
               T3 ADL L5
               T4 ADL L6
                  COM T4 1             ; Two's complement

@POSIT         L0 ADL IP 1
               IP REF @NUM2STR

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Skip space. String address in T0, index in T1
Return current char T0, new index T1

[SKIPSP]          ADL FP -7*

               L1 ADL T0
               L2 ADL T1 0

@REP           T0 ADL L1
               T1 ADL L2
               L0 ADL IP 1
               IP REF @LDBYTE
               T0 BRZ @DONE1

               L0 ADL IP 1
               IP REF @CHECKWS
               T1 BRZ @DONE1

                  ADL L2 1
               IP BNZ @REP

@DONE1         T1 ADL L2
               T2 ADL L3

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Output a string. Address in T4, index in T0.

[PUTS]            ADL FP -5*

               L2 LSR T0 1      ; Compute cell index
                  ADD L2 T4
                  LOD L2        ; Load current cell

               L4 REF @LSB      ; Check if even or odd byte index
                  AND L4 T0
               L4 BNZ @ODD

@EVEN          L3 LSR L2 8
               L3 BRZ @DONE
               L3 OUT VMPUTC
                  ADL T0 1

@ODD           L3 REF @LOBYTE
                  AND L3 L2
               L3 BRZ @DONE
               L3 OUT VMPUTC
                  ADL T0 1
               L2 LSR T0 1      ; Compute cell index
                  ADD L2 T4
                  LOD L2        ; Load current cell
               IP BNZ @EVEN

@DONE             ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Addr1 T0, Index1 T1, Addr2 T2, Index2 T3, Separator T4
Return flag T4
First string can be newline terminated

[STRCMP]          ADL FP -8   ; THIS IS THE ONLY ROUTINE DOING 8

               L1 ADL T0
               L2 ADL T1
               L3 ADL T2
               L4 ADL T3
               L5 COM T4 1

@REP           T0 ADL L1
               T1 ADL L2
               L0 ADL IP 1
               IP REF @LDBYTE
               L6 ADL T0               ; First char in L6

               T0 ADL L3
               T1 ADL L4
               L0 ADL IP 1
               IP REF @LDBYTE          ; Second char in T0

               L7 COM L6 1
                  ADD L7 T0
               L7 BNZ @DIFFR
               L7 ADD T0 L5
                  ADL L2 1
                  ADL L4 1
               L7 BNZ @REP
               IP BNZ @DONE2

@DIFFR         L7 REF 10               ; Check whether both are terminators
                  COM L7 1
                  ADD L7 L6            ; First string char could be newline
               L7 BNZ @NOMATCH
               L7 ADD T0 L5            ; Then second string char is terminator
               L7 BRZ @DONE2

@NOMATCH       L4 REF 0
@DONE2         T4 ADL L4

                  ADL FP 7
                  ADL FP 1
               IP ADL L0

------------------------------------------------------------------------------

Try to find any dictionary entry of given type and return pointers.
Addr T0, index T1, type T2, subtype T3 (or 0 for any subtype), T4 Startentry
Return T0 entryp or 0, T1 parfieldp

[RECOGWRD]        ADL FP -7*

               L1 ADL T4               ; Ptr to first (top) dict entry
               L2 COM T2 1             ; Invert parameters for comparison
               L3 COM T3 1
               L5 ADL T0
               L6 ADL T1 0

@REP2          T4 REF 0                ; Assume look-up fails
               T0 LOD L1 0             ; Load type
               T0 BRZ @FAIL            ; Type 0 means last entry
                  ADD T0 L2
               T0 BNZ @NEXT            ; Types didn't match
               T0 LOD L1 1             ; Load subtype

               L3 BRZ @CHKSTR          ; Subtype request 0 means don't check
                  ADD T0 L3
               T0 BNZ @NEXT            ; Subtypes didn't match

@CHKSTR        T0 ADL L5
               T1 ADL L6
               T2 ADL L1 4             ; Offset to name string of entry
               T3 REF 0                ; Name is aligned
               T4 REF 32
               L0 ADL IP 1
               IP REF @STRCMP

@NEXT          T0 ADL L1
               T2 LOD L1 3             ; Length of name in bytes
               T1 LSR T2               ; Divide by 2 add 1 for alignment
                  ADD L1 T1
                  ADL L1 5
               L4 ADL L1
               T4 BNZ @DONE3           ; branch if look-up success
                  LOD L1
               IP BNZ @REP2

@FAIL          T0 REF 0
@DONE3         T1 ADL L4

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Register T0 addr, T1 index, T2 dict string type
Return T0 type, T1 subtype, T2 entryp/value, T3 new index

[RECOGANY]        ADL FP -7*

               L1 ADL T0
               L2 ADL T1
               L3 ADL T2

               L0 ADL IP 1
               IP REF @RECOGNUM
               T1 BRZ @NONUM

                  ADD L2 T1
               L3 REF @FFFF            ; Type is number
               L4 REF @MSB
                  AND L4 T0            ; Check sign bit
               L4 BNZ @SKIP3           ; Branch if zero, subtype = 8000h
               L4 REF 1                ; Else subtype = 1

@SKIP3         L5 ADL T0               ; Value is number
               T1 BNZ @DONE

@NONUM         T0 ADL L1               ; Look up in dictionary
               T1 ADL L2
               T2 ADL L3               ; Type to look up
               T3 REF 0                ; Match any subtype
               T4 REF @SYSTAB
                  LOD T4 0             ; Ptr to first (top) dict entry
               L0 ADL IP 1
               IP REF @RECOGWRD
               T0 BRZ @NOTFOUND

               L5 ADL T0               ; Value is entryp
               L4 LOD T0 1             ; Subtype found
               T0 BNZ @SKIP

@NOTFOUND      L3 REF @FFFE            ; Type is unmatched string
               L4 REF 0                ; Subtype 0
               L5 ADL L2 0             ; Value is string index

@SKIP          T0 ADL L1               ; Skip either string
               T1 ADL L2
               T2 REF 32
               T3 REF 10
               L0 ADL IP 1
               IP REF @STRLEN
                  ADD L2 T0

@DONE          T0 ADL L3
               T1 ADL L4
               T2 ADL L5
               T3 ADL L2

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Traverses a pattern string, comparing to a source string. Elements matching
the pattern are written (collected) into a destination buffer.

Register T0 addr, T1 index, T2 dest buffer, T3 match string (aligned),
Return succ=n items/fail=0 in T2, T3 succ function or 0, T4 new index
Return T1: FFFF if PATTBRK (more than 4 spaces)

[COLLECT]        ADL FP -8

               L1 ADL T0
               L2 ADL T1
               L3 ADL T2
               L4 ADL T3
               L5 REF 0

               T0 STO L3               ; First pattern item is base address
                  ADL L3 1

@REP           L6 LOD L4               ; Type to match
                  ADL L4 1
               L6 BRZ @SUCC            ; Zero meaning stop

               T0 ADL L1
               T1 ADL L2
               L0 ADL IP 1             ; Skip leading space, T0 and T1 set
               IP REF @SEPSKIP

               L2 ADL T1               ; Advance string pos
               T1 REF @FFFF            ; Assume pattern broken
               T2 REF 0
               T0 BNZ @DONE2

               T0 ADL L1
               T1 ADL L2
               T2 ADL L6
               L0 ADL IP 1
               IP REF @RECOGANY

                  COM L6 1
                  ADD T0 L6            ; T0 contains type
               T0 BNZ @FAIL            ; Not the required type

               L6 LOD L4               ; Subtype to match
                  ADL L4 1
               L6 BRZ @CHKINDX         ; Don't check subtype if zero
                  COM L6 1
                  ADD L6 T1            ; T1 contains subtype
               L6 BNZ @FAIL            ; Not the required subtype

@CHKINDX       L6 LOD L4               ; Index to check
                  ADL L4 1
               L6 BRZ @SKIP2           ; Don't check index if zero
                  COM L6 1
               T4 LOD T2 2             ; T2 is entryp
                  ADD L6 T4
               L6 BNZ @FAIL            ; Not the required index

@SKIP2         T2 STO L3               ; Store entryp
                  ADL L3 1
                  ADL L5 1
               L2 ADL T3
               IP BNZ @REP

@SUCC          T1 REF 0
               T2 ADL L5
               T2 BNZ @DONE2
@FAIL          T1 REF 0
               T2 REF 0
@DONE2         T4 ADL L2
               T3 LOD L4

                  ADL FP 7
                  ADL FP 1

               IP ADL L0

------------------------------------------------------------------------------

Copy T4 bytes from addr T0, index T1 to addr T2, index T3. No overlap.

[BYTECPY]         ADL FP -6*

               L1 ADL T4
               L2 ADL T0
               L3 ADL T1
               L4 ADL T2
               L5 ADL T3 0

@REP1          T0 ADL L2
               T1 ADL L3
               L0 ADL IP 1
               IP REF @LDBYTE

               T2 ADL T0
               T0 ADL L4
               T1 ADL L5

               L0 ADL IP 1
               IP REF @STBYTE

                  ADL L3 1
                  ADL L5 1
                  ADL L1 -1
               L1 BNZ @REP1

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Function for direct dict look-up
T0 type, T1 subtype, T2 index
Return ptr to name section T0, ptr to parfield or zero T1

[DICTOFFS]        ADL FP -7*

               L1 REF @SYSTAB
                  LOD L1 0             ; This is the starting (top) address
                  COM T0 1             ; Negative of type id etc for comparing
                  COM T1 1
                  COM T2 1

@REP2          L5 ADL L1
               L3 LOD L5 0             ; Offs 0 type, offs 1 subtype, 2 index
               L3 BRZ @FAIL            ; End of dict if type 0

@NEXT          L6 ADL L1 3             ; Length of name for this entry
               L4 LOD L6               ; Following lines skip name
                  LSR L4               ; Divide by 2 add 1 for alignment
                  ADL L4 1
                  ADD L4 L1
                  ADL L4 2
               L1 LOD L4               ; Pointer to previous dict entry
                  ADD L3 T0            ; Check if types match
               L3 BNZ @REP2

               T1 BRZ @CHKINDX         ; Don't check for subtype 0
               L3 LOD L5 1             ; Check if subtypes match
                  ADD L3 T1
               L3 BNZ @REP2

@CHKINDX       L3 LOD L5 2             ; Check if indices match
                  ADD L3 T2
               L3 BNZ @REP2

               T0 ADL L6               ; It's a match
               T1 ADL L4 2
               IP BNZ @DONE3

@FAIL          T0 ADL 0
               T1 ADL 0

@DONE3            ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Copy fully specified string of dictionary entry + space char into a buffer
T0 string base, T1 string index, T2 type, T3 subtype, T4 index
Return new index T0, ptr to parfield or zero T1

[PRENTRY]         ADL FP -7*

               L1 ADL T0
               L2 ADL T1

               T0 ADL T2
               T1 ADL T3
               T2 ADL T4
               L0 ADL IP 1
               IP REF @DICTOFFS

               L6 ADL T1
               T4 LOD T0               ; String length from name section
               L5 ADL L2
                  ADD L2 T4
                  ADL L2 1
                  ADL T0 1             ; Point to first character
               T1 REF 0                ; Dict strings are aligned
               T2 ADL L1
               T3 ADL L5
               L0 ADL IP 1
               IP REF @BYTECPY

               T0 ADL L1
               T1 ADL L2
               T2 REF 32               ; ASCII space
               L0 ADL IP 1
               IP REF @STBYTE

               T0 ADL L2 1
               T1 ADL L6

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

 Print RHS1 and RHS2 for instructions in the same group as REF.
; RHS1 and RHS2 combine to a byte, seven bit number if MSB set, else look-up.

[DASMLUT]         ADL FP -7*

               L1 ADL T0
               L2 ADL T1
               L3 ADL T2

               L4 REF @MSB
                  AND L4 L3
               L4 BRZ @ISLUT

               T2 REF 0
               T3 REF 10
               T4 ADL L4               ; T0 and T1 already set
               L0 ADL IP 1
               IP REF @SNUM2STR
               IP BNZ @DONE

@ISLUT         T2 REF @FFFF            ; Fake code, must look-up
               T3 REF 16
               T4 ADL L3               ; T0 and T1 already set
               L0 ADL IP 1
               IP REF @SNUM2STR

@DONE             ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Print RHS1 and RHS2 for instructions in the same group as INP.
; RHS1 and RHS2 combine to 8 bit unsigned port number.

[DASMINP]         ADL FP -7*

               L1 ADL T0
               L2 ADL T1
               L3 ADL T2

               T2 REF @FFFF
               T3 REF 10
               T4 ADL L3               ; T0 and T1 already set
               L0 ADL IP 1
               IP REF @NUM2STR

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Print RHS1 and RHS2 for instructions in the same group as CCA.
; RHS1 and RHS2 are both registers.

[DASMCCA]         ADL FP -7*

               L1 ADL T0
               L2 ADL T1
               L3 ADL T2
               L4 REF 15

               T0 ADL L1
               T1 ADL L2
               T2 REF 2
               T3 REF 0
               T4 LSR L3 4            ; First nybble is RHS1
               L0 ADL IP 1
               IP REF @PRENTRY
               L2 ADL T0

               T0 ADL L1
               T1 ADL L2
               T2 REF 2
               T3 REF 0
               T4 AND L3 L4           ; First nybble is RHS2
               L0 ADL IP 1
               IP REF @PRENTRY

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Print RHS1 and RHS2 for instructions in the same group as ADL.
; RHS1 is register, RHS2 is signed nybble.

[DASMGET]         ADL FP -7*

               L1 ADL T0
               L2 ADL T1
               L3 ADL T2

               T0 ADL L1
               T1 ADL L2
               T2 REF 2
               T3 REF 0
               T4 LSR L3 4            ; Register
               L0 ADL IP 1
               IP REF @PRENTRY
               L2 ADL T0

               T2 REF @FFFF           ; Signed nybble
               T3 REF 10
               T4 REF 15
                  AND T4 L3
               L0 ADL IP 1
               IP REF @SNUM2STR
               IP BNZ @DONE

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Print RHS1 and RHS2 for instructions in the same group as LSL.
; RHS1 is register, RHS2 is unsigned nybble.

[DASMLSL]         ADL FP -7*

               L1 ADL T0
               L2 ADL T1
               L3 ADL T2

               T0 ADL L1
               T1 ADL L2
               T2 REF 2
               T3 REF 0
               T4 LSR L3 4            ; Register
               L0 ADL IP 1
               IP REF @PRENTRY
               L2 ADL T0

               T2 REF @FFFF           ; Unsigned nybble
               T3 REF 10
               T4 REF 15
                  AND T4 L3
               L0 ADL IP 1
               IP REF @NUM2STR
               IP BNZ @DONE

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Print RHS1 and RHS2 for instructions in the same group as BRZ.
; RHS1 and RHS2 combine to 8 bit signed offset.

[DASMBRZ]         ADL FP -7*

               L1 ADL T0
               L2 ADL T1
               L3 ADL T2

               T2 REF @FFFF
               T3 REF 10
               T4 ADL L3               ; T0 and T1 already set
               L0 ADL IP 1
               IP REF @SNUM2STR

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Formatted output, T0 string base, T1 string index, T2 instruction word
Return updated index T0

[DASM]            ADL FP -7*

               L5 ADL IP 1
               IP BNZ @SKIP

               DASMLUT DASMINP DASMCCA DASMGET DASMLSL DASMBRZ

@SKIP          L1 ADL T0
               L2 ADL T1
               L3 ADL T2
               L4 REF 15

               T0 ADL L1
               T1 ADL L2
               T2 REF 2
               T3 REF 0
               T4 LSR L3 12            ; First nybble is LHS
               L0 ADL IP 1
               IP REF @PRENTRY
               L2 ADL T0

               T0 ADL L1
               T1 ADL L2
               T2 REF 1
               T3 REF @FFFF
               T4 LSR L3 8             ; Next nybble is opcode
                  AND T3 L4
               L0 ADL IP 1
               IP REF @PRENTRY
               L2 ADL T0

               L4 REF @LOBYTE
                  AND L3 L4            ; Remaining byte
               L4 LOD T1               ; Operand type
                  ADD L5 L4            ; Function pointer

               T0 ADL L1
               T1 ADL L2
               T2 ADL L3
               L0 ADL IP 1
               IP LOD L5

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Input T0 ptr to par buffer, T1 no of elements, T2 ptr to dest buffer.
Return new dest ptr T1, error code T2.

[ASMVNUM]         ADL FP -7*

               L1 LOD T0 1              ; This is the parsed numeral
               L1 STO T2
                  ADL T2 1
               T1 ADL T2

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Assemble a string literal if present.
Input source string ptr T0, string pos T1, dest ptr T2
Return chars consumed T0, new dest ptr T1, error code T2

[ASMSTR]          ADL FP -8

               L1 ADL T0
               L2 ADL T1
               L7 ADL T1
               L3 ADL T2
               L5 REF 34               ; ASCII "
                  COM L5 1

               T0 ADL L1
               T1 ADL L2
               L0 ADL IP 1
               IP REF @LDBYTE

               T2 ADD L5 T0            ; Compare to ASCII "
               T2 BNZ @DONE3           ; If different, stop parsing
                  ADL L2 1             ; Skip first "

@REP           T0 ADL L1               ; Get next character
               T1 ADL L2
               L0 ADL IP 1
               IP REF @LDBYTE
               L4 LSL T0 8             ; Shift up first character
               T2 REF 32
                  IOR L4 T2
               T2 ADD L5 T0            ; Compare to ASCII "
                  ADL L2 1             ; Adjust position
               T2 BRZ @DONE3

               T0 ADL L1
               T1 ADL L2
               L0 ADL IP 1
               IP REF @LDBYTE
               T2 ADD L5 T0            ; Compare to ASCII "
                  ADL L2 1             ; Adjust position
               T2 BRZ @DONE2
               T2 REF @HIBYTE
                  AND T4 T2            ; Clear space char in lo byte
                  IOR L4 T0            ; Materialize 2nd character

@COPY          L4 STO L3               ; Copy pair of characters
                  ADL L3 1             ; Adjust dest pt
               IP BNZ @REP

@DONE2         L4 STO L3
                  ADL L3 1

@DONE3            COM L7 1
               T0 ADD L2 L7
               T1 ADL L3

                  ADL FP 7
                  ADL FP 1

               IP ADL L0

------------------------------------------------------------------------------

Input source string ptr T0, string pos T1, dest ptr T2
Return chars consumed T0, new dest ptr T1, error code T2

[ASMLBL]          ADL FP -8

               L1 ADL T0
               L2 ADL T1     ; T-NAMING
               L7 ADL T1
               L3 ADL T2

               T0 ADL L1
               T1 ADL L2
               T2 REF 32
               T3 REF 10

               L0 ADL IP 1
               IP REF @STRLEN
               L4 ADL T0

               T0 ADL L1
               T1 ADL L2
               T2 ADL L3 -1            ; current address is preincremented
               L0 ADL IP 1
               IP REF @FNDLABEL

               ; Do error checking!
               ; Output T0 label entryp
               ; T1 0=valid, 1=not a label, 2=undefined, 3=error

               T2 REF @FFFF
                  ADD T2 T1
               L5 ADL T0
               T0 ADL L2               ; Assume not a label
               T1 ADL L3
               T2 BRZ @NOLABEL

               L6 LOD L5 3             ; Get label value from entryp
                  LSR L6
                  ADL L6 1
                  ADD L5 L6
                  ADL L5 4
                  LOD L5 1             ; L5 is the label value

               L5 STO L3
                  ADL L3 1
               T0 ADD L2 L4
               T1 ADL L3 0
               T2 REF 0
               IP BNZ @DONE

@NOLABEL       T2 REF @FFFF

@DONE             COM L7 1
                  ADD T0 L7

                  ADL FP 7
                  ADL FP 1

               IP ADL L0

------------------------------------------------------------------------------

; T2 comes in with dest ptr, which needs to go out in T1 -- ATTENTION

Input T0 ptr to par buffer, T1 no of elements, T2 ptr to dest buffer.
Return new dest ptr T1, error code T2.

[ASMVBYTE]        ADL FP -7*

               L4 ADL T2

               L1 LOD T0 1             ; First par is entryp LHS
                  LOD L1 2
                  ADL T0 1             ; Fake call with implied LHS
                  ADL L1 -1            ; Index from 0 not 1

@GOTLHS           LSL L1 4             ; LHS done, make room for opcode
               T3 LOD T0 1
                  LOD T3 2
                  ADL T3 -1            ; Index based 1, opcodes from 0
                  IOR L1 T3            ; Copy in opcode from 1st par

                  LSL L1 8             ; Make room for byte
               L2 LOD T0 2             ; Pick up the number argument
               L3 REF @HIBYTE
                  AND L3 L2            ; See if within 8 bits
               T2 REF 0
               L3 BRZ @OK
               T2 REF 1                ; Error code

@OK               IOR L1 L2
               L1 STO L4
                  ADL L4 1
               T1 ADL L4

                  T2 REF 0

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Input T0 ptr to par buffer, T1 no of elements, T2 ptr to dest buffer.
Return new dest ptr T1, error code T2.

[ASMV2REG]        ADL FP -7*

                  COM T1 1             ; Compare number of operands given
               L3 REF 4
                  ADD L3 T1
               L3 BRZ @GOTLHS
               L1 LOD T0 2             ; Second par is entryp RHS1>LHS
                  LOD L1 2
               IP BNZ @IMPLHS
@GOTLHS        L1 LOD T0 1             ; First par is entryp LHS
                  LOD L1 2
                  ADL T0 1             ; Fake call with implied LHS
@IMPLHS           ADL L1 -1            ; Index from 0 not 1

@GOTLHS           LSL L1 4             ; LHS done, make room for opcode
               T3 LOD T0 1
                  LOD T3 2
                  ADL T3 -1            ; Index based 1, opcodes from 0
                  IOR L1 T3            ; Copy in opcode from 1st par

                  LSL L1 4             ; Make room for RHS1 register
               T3 LOD T0 2
                  LOD T3 2
                  IOR L1 T3            ; Copy in RHS1 register

                  LSL L1 4
               L2 LOD T0 3             ; entryp of RHS2 reg
                  LOD L2 2             ; Pick up the second register
                  IOR L1 L2
               L1 STO T2
                  ADL T2 1

                  T1 ADL T2
                  T2 REF 0

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Assemble opcodes for instructions like "T0 ADL T0"
; (Explit LHS, Opcode, RHS1, Implied number)
Input T0 ptr to par buffer, T1 no of elements, T2 ptr to dest buffer.
Return new dest ptr T1, error code T2.

[EORI]            ADL FP -7*

               L4 ADL T2               ; Must go out as T1

               L1 LOD T0 1
                  LOD L1 2
                  ADL L1 -1            ; Adjust reg index

                  LSL L1 4             ; LHS done, make room for opcode
               T3 LOD T0 2
                  LOD T3 2
                  ADL T3 -1            ; Adjust opc index
                  IOR L1 T3            ; Copy in opcode from 1st par

                  LSL L1 4             ; Make room for RHS1 register
               T3 LOD T0 3
                  LOD T3 2
                  ADL T3 -1
                  IOR L1 T3            ; Copy in RHS1 register

                  LSL L1 4             ; Implied arg 0, just shift
               L1 STO L4
                  ADL L4 1

               T1 ADL L4
               T2 REF 0

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Input T0 ptr to par buffer, T1 no of elements, T2 ptr to dest buffer.
Return new dest ptr T1, error code T2.

[EORE]            ADL FP -7*


                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------


Input T0 ptr to par buffer, T1 no of elements, T2 ptr to dest buffer.
Return new dest ptr T1, error code T2.

[ASMV1REG]        ADL FP -7*

               L4 ADL T2               ; Must go out as T1

               T3 COM T1 1             ; Compare number of operands given
               L3 REF 4
                  ADD L3 T3
               L3 BRZ @GOTLHS
               L1 LOD T0 2             ; Second par is entryp RHS1>LHS
                  LOD L1 2
               IP BNZ @IMPLHS
@GOTLHS        L1 LOD T0 1             ; First par is entryp LHS
                  LOD L1 2
                  ADL T0 1             ; Fake call with implied LHS
@IMPLHS           ADL L1 -1            ; Index from 0 not 1

@GOTLHS           LSL L1 4             ; LHS done, make room for opcode
               T3 LOD T0 1
                  LOD T3 2
                  ADL T3 -1            ; Index based 1, opcodes from 0
                  IOR L1 T3            ; Copy in opcode from 1st par

                  LSL L1 4             ; Make room for RHS1 register
               T3 LOD T0 2
                  LOD T3 2
                  ADL T3 -1
                  IOR L1 T3            ; Copy in RHS1 register

           ;    L2 REF 0
           ;       ADL T1 -3            ; See if implied 0 (RHS1 omitted)
           ;    T1 BRZ @OK

               L2 LOD T0 3             ; Pick up the number argument
               L3 REF @FFF0
                  AND L3 L2            ; See if within 4 bits  --DOESN'T WORK WITH NEGATIVE NUMBERS
               T2 REF 0
               L3 BRZ @OK
               T2 REF 1                ; Error code

@OK               LSL L1 4
               T1 REF 15               ; Force range
                  AND L2 T1
                  IOR L1 L2
               L1 STO L4
                  ADL L4 1
               T1 ADL L4

                  T2 REF 0

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

[ASMVLBL]         ADL FP -7*

               L1 LOD T0 1             ; First par is entryp LHS
                  LOD L1 2
                  ADL T0 1             ; Fake call with implied LHS
                  ADL L1 -1            ; Index from 0 not 1

@GOTLHS           LSL L1 4             ; LHS done, make room for opcode
               T3 LOD T0 1
                  LOD T3 2
                  ADL T3 -1            ; Index based 1, opcodes from 0
                  IOR L1 T3            ; Copy in opcode from 1st par

                  LSL L1 8             ; Make room for byte
               L2 LOD T0 2             ; Pick up the entryp of the label
               L4 LOD L2 2             ; Index is port number
               L5 REF @HIBYTE
                  AND L5 L4            ; See if within 8 bits

               T1 ADL T2               ; SAVE T2 (crosses over with T1)
               T2 REF 0
               L3 BRZ @OK
               T2 REF 1                ; Error code

@OK            L5 REF @LOBYTE
                  AND L4 L5
                  IOR L1 L4
               L1 STO T1
                  ADL T1 1

                  T2 REF 0

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Input T0 ptr to par buffer, T1 no of elements, T2 ptr to dest buffer.
Return new dest ptr T1, error code T2.

[VALRBRA]         ADL FP -7*

               L4 ADL T2

               L1 LOD T0 1             ; First par is entryp LHS
                  LOD L1 2
                  ADL L1 -1            ; Index from 0 not 1

                  LSL L1 4             ; LHS done, make room for opcode
               T3 LOD T0 2
                  LOD T3 2
                  ADL T3 -1            ; Index based 1, opcodes from 0
                  IOR L1 T3            ; Copy in opcode from 1st par

                  LSL L1 8             ; Make room for label value

               T1 LOD T0 3             ; 2nd element unmatched string index
                  LOD T0               ; 0th element string base
               L0 ADL IP 1
               IP REF @FNDLABEL

               L3 REF @FFFF
                  ADD L3 T1
               L3 BRZ @ERR
               L3 REF 3
                  COM L3 1
                  ADD L3 T1
               L3 BRZ @ERR

               T3 LOD T0 3             ; Load label value from parfield
                  LSR T3
                  ADL T3 1
                  ADD T3 T0
                  ADL T3 5
               T0 LOD T3

               L5 COM L4 1
               L2 ADD L5 T0            ; Relative branch: add offset to current
               L3 REF @LOBYTE
                  AND L2 L3
@ERR
@OK               IOR L1 L2

               L1 STO L4
                  ADL L4 1
               T1 ADL L4

               T2 REF 0

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Assemble a pattern if present and advance source string ptr.
Input source string ptr T0, string pos T1, dest ptr T2
Return chars consumed T0, new dest ptr T1, error code T2

[ASMPATT]         ADL FP -8

               L1 ADL T0
               L2 ADL T1
               L7 ADL T1
               L3 ADL T2
               L6 REF @BUFFER1
               L5 REF @BSMPATTS        ; Ptr to array

@REP1          T2 REF @FFFF            ; Assume return value is error
               T1 ADL L3
               T3 LOD L5
               T3 BRZ @END1

                  ADL L5 1             ; Next in array
               T0 ADL L1
               T1 ADL L2
               T2 ADL L6               ; T3 set above with ptr to pattern str
               L0 ADL IP 1
               IP REF @COLLECT         ; Call sets T1 flag

               T1 BNZ @REP1            ; Pattern breaker - too many spaces
               T2 BRZ @REP1            ; Branch if pattern mismatch, next

               L2 ADL T4               ; Matching pattern, advance str ptr

               T0 ADL L6
               T1 ADL T2               ; No of elements in par buffer
               T2 ADL L3               ; Destination ptr for instr word
               L0 ADL IP 1
               IP ADL T3               ; Call pattern validation function

@END1             COM L7 1
               T0 ADD L2 L7            ; T1 and T2 set by validation func

                  ADL FP 7
                  ADL FP 1

               IP ADL L0

------------------------------------------------------------------------------

Input type T0, subtype T1, index T2, str addr T3, str pos T4
Return T0 strlen, T1 parfieldp

[ADDENTRY]        ADL FP -7*

               L2 REF @SYSTAB
               L1 LOD L2               ; Dynamic value of DICT for backlink
                  LOD L2 1             ; Dynamic value of TOP

               T0 STO L2 0             ; Store type, subtype, index
               T1 STO L2 1
               T2 STO L2 2

               L3 ADL T3               ; Save source string info for
               L4 ADL T4               ; call to BYTECPY below

               T0 ADL L3               ; Compute src str length
               T1 ADL L4
               T2 REF 32
               T3 REF 10
               L0 ADL IP 1
               IP REF @STRLEN
               T0 STO L2 3             ; Store len in new label entry
               L5 ADL T0

                  LSR T0               ; Div by 2 add 1, char to cell count
                  ADL T0 1
               L6 LSL T0               ; Index to end of padding for later
               T1 ADL L2 4
               T2 REF @SPACE
@PAD           T2 STO T1               ; Pad cell-wide space
                  ADL T1 1
                  ADL T0 -1
               T0 BNZ @PAD

               T0 ADL L3               ; Copy label into padded region
               T1 ADL L4
               T2 ADL L2 4
               T3 REF 0
               T4 ADL L5
               L0 ADL IP 1
               IP REF @BYTECPY

               L3 ADL L5
               L5 ADD L6 L2            ; L2 is the new DICT ptr
                  ADL L5 1             ; Cell after padded string
               L1 STO L5               ; Store back link
               L1 REF @SYSTAB
               L2 STO L1               ; Update DICT
                  ADL L5 1
               L5 STO L1 1             ; Update TOP
               T0 ADL L3
               T1 ADL L5 -1

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Input str ptr T0, pos T1, T2 current addr
Output T0 label entryp, T1 0=valid, 1=not a label, 2=undefined, 3=error

[FNDLABEL]        ADL FP -7*

               L1 ADL T0
               L2 ADL T1 1            ; Skip presumed < or > char
               L3 ADL T2               ; L3 is current address

               ; Assume entry values are strictly ordered

               L4 REF 0                ; L4 closest smaller
               L5 REF 0                ; L5 closest larger

@REPL          T0 ADL L1               ; Check if label defined
               T1 ADL L2
               T2 REF 6
               T3 REF 0
               T4 REF @SYSTAB
                  LOD T4 0             ; Ptr to first (top) dict entry
               L0 ADL IP 1
               IP REF @RECOGWRD        ; Return T0 entryp or 0, T1 parfieldp
               T0 BRZ @BREAK

               T2 LOD T1 1
                  COM T2 1
                  CCA T2 L3            ; Compare found to current address
               T2 BNZ @SUCCL           ; Success if found is less
               L5 ADL T0               ; Until then, improve closest larger
               T4 LOD T1
               T4 BNZ @REPL            ; If not beginning of dict, continue

@SUCCL         L4 ADL T0 0
@BREAK                                 ; L4 L5 now valid or 0
               T0 ADL L1
               T1 ADL L2 -1            ; Recover presumed < or > char
               L0 ADL IP 1
               IP REF @LDBYTE
               T1 REF @GTSIGN          ; ASCII greater-than
                  COM T1 1
               T3 ADD T1 T0
               T3 BNZ @CHECKLT

               T0 REF 0                ; Assume undefined
               T1 REF 2
               L5 BRZ @END

               T0 ADL L5
               T1 REF 0
               IP BNZ @END

@CHECKLT       T1 REF @LTSIGN          ; ASCII less-than
                  COM T1 1
               L6 ADD T1 T0

               T0 REF 0                ; Assume not a label
               T1 REF 1
               L6 BNZ @END

               T0 REF 0                ; Assume error
               T1 REF 3
               L4 BRZ @END

               T0 ADL L4
               T1 REF 0

@END
                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Advance T1 to next newline or null char of str, whichever comes first
Input str ptr T0, pos T1
Output str ptr T0, new pos T1, last char T2

[SEEKNL]          ADL FP -7*

               L1 ADL T0
               L2 ADL T1 -1

@REP2             ADL L2 1
               T0 ADL L1
               T1 ADL L2
               L0 ADL IP 1
               IP REF @LDBYTE

               T2 ADL T0
               T2 BRZ @DONE1           ; If null then done

               L5 REF 10
                  COM L5 1
                  ADD L5 T0            ; Check if ASCII newline
               L5 BNZ @REP2

@DONE1         T0 ADL L1
               T1 ADL L2

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Input str ptr T0, pos T1
Output pattern break flag T0, new pos T1, last char T2

[SEPSKIP]         ADL FP -7*

               L1 ADL T0
               L2 ADL T1 -1
               L3 REF @FFFF
               L4 REF 0

@REP1             ADL L2 1
                  ADL L3 1
               T0 ADL L1
               T1 ADL L2
               L0 ADL IP 1
               IP REF @LDBYTE

               L6 ADL T0               ; Save current char as ret val
               L0 ADL IP 1
               IP REF @CHECKWS
               T1 BRZ @DONE            ; Stop if not whitespace

               L5 REF 4
                  COM L5 1
                  ADD L5 L3
               L5 BRZ @SKIPLN

               L5 REF 2
                  COM L5 1
                  ADD L5 L3
               L5 BNZ @REP1
               L4 REF @FFFF            ; Set pattern break flag
               IP BNZ @REP1            ; Always

@SKIPLN        T0 ADL L1
               T1 ADL L2
               L0 ADL IP 1
               IP REF @SEEKNL
               L2 ADL T1
               L6 ADL T2 0             ; Last char - line terminator or NULL

@DONE          T0 ADL L4
               T1 ADL L2
               T2 ADL L6

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Skip space, parse label name and if present, create dictionary entry and
advance str pos to after the label name.
Return NULLFOUND flag T4

[DEFLABEL]        ADL FP -7*

               L1 ADL T0
               L2 ADL T1
               L3 ADL T2
               L0 ADL IP 1
               IP REF @SKIPSP          ; Skip whitespace
               L2 ADL T1
               T0 BNZ @GOOD

               T4 REF @FFFF            ; NULL char end of assembly detected
               IP BNZ @DONE2

@GOOD          T1 REF @ATSIGN          ; Label must begin with @
                  COM T1 1
                  ADD T0 T1
               T0 BNZ @DONE2

                  ADL L2 1             ; Skip @ sign
               T0 ADL L1               ; Check if label exists w/same value
               T1 ADL L2               ; from first pass, then skip creation
               T2 REF 6
               T3 REF 0
               T4 REF @SYSTAB
                  LOD T4 0             ; Ptr to first (top) dict entry
               L0 ADL IP 1
               IP REF @RECOGWRD        ; Return T0 entryp or 0, T1 parfieldp
               T0 BRZ @NEWENTRY
               T0 LOD T1 1
                  COM T0 1
                  ADD T0 L3            ; Compare to current address
               T0 BRZ @SKIPLBL         ; If same, don't create new label

@NEWENTRY      T0 REF 6
               T1 REF 1
               T2 REF 1
               T3 ADL L1
               T4 ADL L2
               L0 ADL IP 1
               IP REF @ADDENTRY
               L3 STO T1 1             ; Store current addr as lbl val
                  ADL T1 2
               T0 REF @SYSTAB
               T1 STO T0 1             ; Update TOP

@SKIPLBL       T0 ADL L1               ; Skip label string in source
               T1 ADL L2
               T2 REF 32
               T3 REF 10
               L0 ADL IP 1
               IP REF @STRLEN
                  ADD L2 T0

               T4 REF 0                ; No NULL char encountered
@DONE2         T1 ADL L2

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Inner loop of assembler, assemble 1 line of text
Input str ptr T0, str pos T1, object code insert ptr, T2
Output NULLFOUND flag T4, new pos T1, new insert ptr T2, error T3

[ASMI]            ADL FP -7*

               L1 ADL T0
               L2 ADL T1
               L3 ADL T2
               L4 REF 0                ; No NULL char encountered
               L5 REF 0                ; Assume no error
               L6 REF 0

@REP              COM L6 1
                  ADD L6 L2
               L6 BRZ @DONE            ; Skip line if no match
               L6 ADL L2

               T0 ADL L1
               T1 ADL L2
               L0 ADL IP 1
               IP REF @SEPSKIP
               L2 ADL T1               ; Adjust string pos
               T2 BRZ @ISNULL          ; If last char NULL, stop

                  COM T2 1
               T2 REF @NEWLINE         ; Check if ASCII newline
               T2 BRZ @DONE

               T0 ADL L1
               T1 ADL L2
               T2 ADL L3
               L0 ADL IP 1
               IP REF @ASMPATT         ; Assemble an instruction if present
               L3 ADL T1               ; Adjust new dest pos
                  ADD L2 T0            ; Adjust string pos
               T0 BNZ @REP

               T0 ADL L1
               T1 ADL L2
               T2 ADL L3
               L0 ADL IP 1
               IP REF @ASMSTR          ; Assemble a string literal if present
               L3 ADL T1               ; Adjust new dest pos
                  ADD L2 T0            ; Adjust string pos
               T0 BNZ @REP

               T0 ADL L1
               T1 ADL L2
               T2 ADL L3
               L0 ADL IP 1
               IP REF @ASMLBL          ; Assemble a label reference if present
               L3 ADL T1               ; Adjust new dest pos
                  ADD L2 T0            ; Adjust string pos
               IP BNZ @REP

@ISNULL        L4 REF @FFFF

@DONE          T4 ADL L4
               T1 ADL L2
               T2 ADL L3
               T3 ADL L5

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

This is the top level routine of a two-pass native assembler for Sonne-16.
Assembly proceeds by parsing lines of text. Source text must be a NULL
terminated string.
Input source string ptr T0, string pos T1  ; object code in ASMBUF
Return error code T0

[ASMO]        ADL FP -7*

               L1 ADL T0               ; Ptr to base of assembly source
               L5 ADL T1               ; Char index pos offset from base ptr

               L6 REF 2                ; Assembly pass counter
@PASS          L2 ADL L5               ; Reset pos to beginning of source text
               L3 REF @ASMBUF          ; Reset object code buffer ptr
               L4 REF 1                ; Source line counter

@LINE          T0 ADL L1               ; Pos beginning of new line
               T1 ADL L2
               L0 ADL IP 1
               IP REF @LDBYTE          ; Get 1st character of line into T0

               L0 ADL IP 1
               IP REF @CHECKWS         ; Check if whitespace char
               T1 BRZ @NEXTLINE        ; Skip entire line - comment

               T0 ADL L1
               T1 ADL L2
               T2 ADL L3
               L0 ADL IP 1
               IP REF @DEFLABEL        ; SKIPSP not SEPSKIP
               L2 ADL T1
               T4 BNZ @DONE3           ; Next pass if NULL char encountered

               T0 ADL L1
               T1 ADL L2
               T2 ADL L3
               L0 ADL IP 1
               IP REF @ASMI            ; Assemble inline elements
               L2 ADL T1
               L3 ADL T2
               T4 BNZ @DONE3           ; Next pass if NULL char encountered

@NEXTLINE      T0 ADL L1               ; Skip ahead until newline
               T1 ADL L2
               L0 ADL IP 1
               IP REF @SEEKNL
               L2 ADL T1 1             ; Skip line terminator
               T2 BRZ @DONE3           ; Next pass if NULL char encountered

                  ADL L4 1             ; Increment line number
               IP BNZ @LINE

@DONE3            ADL L6 -1
               L6 BNZ @PASS

               T0 REF 0

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Check if char at strpos is whitespace.
Input char T0
Output flag T1

[CHECKWS]         ADL FP -7*

               L2 REF 0                ; Assume none-whitespace

               L1 REF 32               ; ASCII space
                  COM L1 1
                  ADD L1 T0
               L1 BNZ @NEXT1

               L2 REF @FFFF            ; Set whitespace flag
               IP BNZ @DONE2

@NEXT1         L1 REF 9                ; ASCII tab
                  COM L1 1
                  ADD L1 T0
               L1 BNZ @DONE2

               L2 REF @FFFF            ; Set whitespace flag

@DONE2         T1 ADL L2

                  ADL FP *
               IP ADL L0

------------------------------------------------------------------------------

Global system variables (must be RAM, or are these offsets to SYSTAB?)

[MEMLISTA] 0                           ; Implied address for memory listing

------------------------------------------------------------------------------

String table  (Use STRMSG to display using index)

@BAAB00 "CYF 8T0 ready." 0
@BAAB01 "This is a sample text" 0
@BAAB02 "Gruds" 32 0

[STRTAB]  BAAB00 BAAB01 BAAB02

[SEPCHARS]  1 32       ; Space            ; Structure used in SEPSKIP
            1 Ah       ; \n Unix
            1 Dh       ; \r Apple
            2 Dh Ah    ; \r\n Windows
            1 9        ; Tab
            0

------------------------------------------------------------------------------

Command patterns    ; type, subtype (0 if any), index (0 if any), 0, funcptr
                    ; 0 is end of pattern, -1 number, -2 unknown string
                    ; funcptr args:
                    ; T0=dest buffer, T1=number of items in dest buffer

; Order these so that shorter patterns *follow* equivalent longer patterns ??

@AAAC00   3 1 1   3 2 1            0 EXIT     ; vm exit
@AAAC01   3 1 1   3 2 4   3 2 2    0 VMTXTLD  ; vm text load
@AAAC02   3 1 1   3 2 4   3 2 3    0 VMTXTSV  ; vm text save
@AAAC03   3 2 5                    0 TEST     ; test
@AAAC04   3 1 3   3 2 6  -1 0 0    0 VMTXTLD  ; mem list number
@AAAC05   3 1 3   3 2 6            0 VMTXTSV  ; mem list

[COMPATT] AAAC00 AAAC01 AAAC02 AAAC03 AAAC04 AAAC05 0

; The following are patterns for assembly instructions used in ASMINSTR.
; They start with the mnemonic, not the optional LHS operand.
; Subtype for numbers: 0 = don't care, 1 = positive, 8000h = negative

; Number literals
                                              ; Example
@AAAD00  -1 0 0                   0 ASMVNUM   ; 12h

; Short forms (implied LHS)
                                              ; Example
@AAAD01   1 3 0   2 0 0   2 0 0   0 ASMV2REG  ; ADD T1 T2
@AAAD02   1 4 0   2 0 0  -1 0 0   0 ASMV1REG  ; ADL T1 -2
@AAAD03   1 4 0   2 0 0           0 ASMV1REG  ; ADL T1
@AAAD04   1 5 0   2 1 0  -1 0 0   0 ASMV1REG  ; LSL T1 2
@AAAD05   1 6 0  -1 0 0           0 ASMVBYTE  ; BRZ -41
@AAAD06   1 6 0  -2 0 0           0 VALRBRA   ; BRZ BLABEL

; Long forms
                                                      ; Example
@AAAD07   2 0 0   1 1 0  -1 1 0           0 ASMVBYTE  ; T0 REF 250
@AAAD08   2 0 0   1 2 0  -1 1 0           0 ASMVBYTE  ; T0 INP 250
@AAAD09   2 0 0   1 3 0   2 0 0   2 0 0   0 ASMV2REG  ; T0 ADD T1 T2
@AAAD10   2 0 0   1 4 0   2 0 0  -1 0 0   0 ASMV1REG  ; T0 ADL T1 -2
@AAAD11   2 0 0   1 4 0   2 0 0           0 EORI      ; Changing subroutine NAME! causes cyf to hang, why? VAL1REI does
@AAAD12   2 0 0   1 5 0   2 1 0  -1 0 0   0 ASMV1REG  ; T0 LSL T1 2
@AAAD13   2 0 0   1 6 0  -1 0 0           0 ASMVBYTE  ; T0 BRZ -41
@AAAD14   2 0 0   1 1 0   6 1 0           0 ASMVLBL   ; T0 REF LLABEL
@AAAD15   2 0 0   1 2 2   5 1 0           0 ASMVLBL   ; T0 INP ILABEL
@AAAD16   2 0 0   1 2 3   5 2 0           0 ASMVLBL   ; T0 OUT OLABEL
@AAAD17   2 0 0   1 6 0  -2 0 0           0 VALRBRA   ; T0 BRZ BLABEL

[BSMPATTS] AAAD00 AAAD01 AAAD02 AAAD03 AAAD04 AAAD05 AAAD06 AAAD07
           AAAD08 AAAD09 AAAD10 AAAD11 AAAD12 AAAD13 AAAD14 AAAD15
           AAAD16 AAAD17 0

------------------------------------------------------------------------------

Dictionary.
Type, subtype, index, length, label, link-back, optional parameters

@AAAA00  0

; Type 1 are mnemonics

@AAAA01  1 1 1  3  "REF "  AAAA00
@AAAA02  1 2 2  3  "INP "  AAAA01
@AAAA03  1 2 3  3  "OUT "  AAAA02
@AAAA04  1 3 4  3  "CCA "  AAAA03
@AAAA05  1 3 5  3  "ADD "  AAAA04
@AAAA06  1 3 6  3  "AND "  AAAA05
@AAAA07  1 3 7  3  "EOR "  AAAA06
@AAAA08  1 3 8  3  "IOR "  AAAA07
@AAAA09  1 4 9  3  "ADL "  AAAA08
@AAAA10  1 4 10 3  "COM "  AAAA09
@AAAA11  1 4 11 3  "LOD "  AAAA10
@AAAA12  1 4 12 3  "STO "  AAAA11
@AAAA13  1 5 13 3  "LSL "  AAAA12
@AAAA14  1 5 14 3  "LSR "  AAAA13
@AAAA15  1 6 15 3  "BRZ "  AAAA14
@AAAA16  1 6 16 3  "BNZ "  AAAA15

; Type 2 are registers

@AAAA17  2 1 1  2  "IP  "  AAAA16
@AAAA18  2 1 2  2  "FP  "  AAAA17
@AAAA19  2 1 3  2  "SP  "  AAAA18
@AAAA20  2 1 4  2  "T0  "  AAAA19
@AAAA21  2 1 5  2  "T1  "  AAAA20
@AAAA22  2 1 6  2  "T2  "  AAAA21
@AAAA23  2 1 7  2  "T3  "  AAAA22
@AAAA24  2 1 8  2  "T4  "  AAAA23
@AAAA25  2 1 9  2  "L0  "  AAAA24
@AAAA26  2 1 10 2  "L1  "  AAAA25
@AAAA27  2 1 11 2  "L2  "  AAAA26
@AAAA28  2 1 12 2  "L3  "  AAAA27
@AAAA29  2 1 13 2  "L4  "  AAAA28
@AAAA30  2 1 14 2  "L5  "  AAAA29
@AAAA31  2 1 15 2  "L6  "  AAAA30
@AAAA32  2 1 16 2  "L7  "  AAAA31

; Type 3 are keyboard commands

@AAAA33  3 1 1  2  "vm  "    AAAA32
@AAAA34  3 1 2  2  "te  "    AAAA33
@AAAA35  3 1 3  3  "mem "    AAAA34
@AAAA36  3 2 1  4  "exit  "  AAAA35
@AAAA37  3 2 2  4  "load  "  AAAA36
@AAAA38  3 2 3  4  "save  "  AAAA37
@AAAA39  3 2 4  4  "text  "  AAAA38
@AAAA40  3 2 5  4  "test  "  AAAA39
@AAAA41  3 2 6  4  "list  "  AAAA40

; Type 4 are control symbols

@AAAB00  4 1 1  1  ". " AAAA41
@AAAB01  4 2 1  1  "( " AAAB00
@AAAB02  4 2 2  1  ") " AAAB01

; Type 5 are labels, subtype 1 input ports

@AAAB03  5 1 255  6 "VMGETS  "  AAAB02
@AAAB04  5 1 254  6 "VMCELL  "  AAAB03
@AAAB05  5 1 253  6 "VMADDR  "  AAAB04
@AAAB06  5 1 252  6 "VMBANK  "  AAAB05
@AAAB07  5 1 251  7 "VMTXTLD "  AAAB06
@AAAB08  5 1 250  6 "LUTRDV  "  AAAB07

; Subtype 2 output ports

@AAAB09  5 2 255  6 "VMEXIT  "    AAAB08
@AAAB10  5 2 254  5 "VMPRN "      AAAB09
@AAAB11  5 2 253  6 "VMPUTS  "    AAAB10
@AAAB12  5 2 252  6 "VMPUTC  "    AAAB11
@AAAB13  5 2 251  7 "VMPUTNL "    AAAB12
@AAAB14  5 2 250  6 "VMCELL  "    AAAB13
@AAAB15  5 2 249  6 "VMADDR  "    AAAB14
@AAAB16  5 2 248  6 "VMBANK  "    AAAB15
@AAAB17  5 2 247  7 "VMTSAVE "    AAAB16
@AAAB18  5 2 246  7 "VMCYCON "    AAAB17
@AAAB19  5 2 245  8 "VMCYCEND  "  AAAB18
@AAAB20  5 2 244  7 "LUTADDR "    AAAB19
@AAAB21  5 2 243  6 "LUTWRV  "    AAAB20

; Type 6 are branch targets

@AAAB22  6 2 1  4 "FFFF  "        AAAB21  EEh

[DICT]

@AAAB23  6 2 1  3 "REP "          AAAB22  13h

[TOP]






