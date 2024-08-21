

Fix trailing semicolon bug


Paver firmware ("8T3")
Copyr. 2015-2020 Michael Mangelsdorf (mim@ok-schalter.de)

This file is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

More information at:
https://ok-schalter.de/static/programming.html

-------------------------------------------------------------------------------

Memory Map:

E000-FFFF: Overlay region

The high-order four bits 12-15 of the current frame key select
1 of 16 'banks' or 'overlays' that are mapped into E000h to FFFFh.
Using the <4-bit-index> OVERLAY instruction, one of the banks is
selected and mapped. The selected overlay is saved/restored together
with the current frame key during JSR/RET.


SD Card structure:


F1 set source markers (use twice)
F2 set target markers (use twice)
F3 store current beach
F4 clear current buffer
F5 Insert beach
F6 Delete beach
HOME toggle buffer
END paste clipboard from VM host
PGUP/PGDN load previous/next beach

-------------------------------------------------------------------------------

;    12345678901234567890

 DEF zop_INIT          0  ; These switch on L/R1 (R2_LOR = 0)
 DEF zop_NEXT          1
 DEF zop_LIT           2
 DEF zop_TXT_SHOWCUR   3
 DEF zop_TXT_HIDECUR   4
 DEF zop_JUMP          10
 DEF zop_KB_reset      12
 DEF zop_TXT_flip      13
 DEF zop_GFX_flip      14
 DEF zop_VM_IDLE       15
 DEF zop_SYNC          17
 DEF zop_NOP           20
 DEF zop_GOTKEY        21

;    12345678901234567890

 DEF dop_SIG           0  ; These switch on R2_LOR
 DEF dop_REF           1
 DEF dop_GFX_ldfg      2
 DEF dop_GFX_stbg      3
 DEF dop_BRA           4
 DEF dop_PAR           6
 DEF dop_PULL          7
 DEF dop_PUSH          9
 DEF dop_RET           10
 DEF dop_VM_rdv        11

;    12345678901234567890

 DEF sop_VM_gets       0  ; These switch on R2_LOR/R1
 DEF sop_VM_exit       1
 DEF sop_VM_prn        2
 DEF sop_VM_putc       3
 DEF sop_VM_puts       7
 DEF sop_VM_argc       8
 DEF sop_VM_argvset    9
 DEF sop_VM_argvget    10
 DEF sop_VM_rdblk      14
 DEF sop_VM_wrblk      15
 DEF sop_VM_HTON       16
 DEF sop_VM_NTOH       17
 DEF sop_VM_flen       18
 DEF sop_VM_fseek      19
 DEF sop_VM_fgetpos    20
 DEF sop_VM_fread      21
 DEF sop_VM_fwrite     22
 DEF sop_VM_fnew       23
 DEF sop_VM_fold       24
 DEF sop_VM_fclose     25
 DEF sop_VM_ready      26

 DEF sop_SET           59
 DEF sop_IRQ_vec       60
 DEF sop_WARM          61
 DEF sop_W_get         62
 DEF sop_POP           63
 DEF sop_DROP          64
 DEF sop_PULL          65
 DEF sop_LODS          66
 DEF sop_STOS          67
 DEF sop_ASR           68
 DEF sop_W_set         69
 DEF sop_TXT_fg        70
 DEF sop_TXT_bg        71
 DEF sop_PER           73
 DEF sop_NYBL          77
 DEF sop_PC_set        81
 DEF sop_PC_get        82
 DEF sop_BYTE          83
 DEF sop_SERVICE       84
 DEF sop_MSB           85
 DEF sop_LSB           86
 DEF sop_NOT           87
 DEF sop_NEG           88
 DEF sop_OVERLAY       90

 DEF sop_BLANKING      91
 DEF sop_IRQ_self      92
 DEF sop_GFX_H         93
 DEF sop_GFX_V         94
 DEF sop_cycles_lo     95
 DEF sop_LED_set       97
 DEF sop_KEYSW_get     98
 DEF sop_CORE_id       99
 DEF sop_TXT_colors    100
 DEF sop_TXT_colorg    101
 DEF sop_TXT_pos_set   102
 DEF sop_TXT_glyphs    103
 DEF sop_TXT_glyphg    104
 DEF sop_TXT_curset    105
 DEF sop_KB_keyc       106
 DEF sop_KB_ctrl       107
 DEF sop_RETI          108
 DEF sop_BGCOL_set     109
 DEF sop_SD_SET_MOSI   110
 DEF sop_SD_GET_MISO   111
 DEF sop_SD_SET_SCLK   112
 DEF sop_SD_SET_CS     113
 DEF sop_CPU_speed     114

 DEF sop_CPU_id        115
 DEF sop_GPIO_rd_a     118
 DEF sop_GPIO_rd_b     119
 DEF sop_GPIO_rd_c     120
 DEF sop_GPIO_rd_d     121
 DEF sop_GPIO_wr_c     122
 DEF sop_GPIO_wr_d     123
 DEF sop_SEG7_set01    124
 DEF sop_SEG7_set23    125
 DEF sop_SEG7_set45    126

 ; Color definitions

 DEF COLOR_black       0000000000000000b        
 DEF COLOR_white       1111111111111111b
 DEF COLOR_red         1111100000000000b
 DEF COLOR_green       0000011111100000b
 DEF COLOR_blue        0000000000011111b

 DEF ASC_space       20h
 DEF ASC_linefeed    10
 DEF ASC_b           62h
 DEF ASC_h           68h
 DEF ASC_plus        2Bh
 DEF ASC_minus       2Dh
 DEF ASC_semicolon   3Bh
 DEF ASC_doublequote 22h
 DEF ASC_singlequote 27h
 DEF ASC_atsign      64
 DEF ASC_less        3Ch
 DEF ASC_greater     3Eh
 DEF ASC_a           61h
 DEF ASC_z           7Ah
 DEF ASC_tab         9
 DEF ASC_0           30h
 DEF ASC_A           65
 DEF ASC_underscore  5Fh
 DEF ASC_paren_open  28h
 DEF ASC_paren_close 29h
 DEF ASC_colon       58
 DEF ASC_dollar      36
 DEF ASC_star        42
 DEF ASC_fwdSlash    47
 DEF ASC_sharp       35
 

 DEF TEA_Runnable   1
 DEF TEA_Utility    2
 DEF TEA_CYF_Symbol 3
 DEF TEA_RDV        4

;    12345678901234567890

 DEF RDV_FUNC_wrPFSFile     5
 DEF RDV_FUNC_rdPFSFile     6

 DEF RDV_VM_ReadsRDVBuf    1
 DEF RDV_VM_Finished       2
 DEF RDV_VM_NeedsStr16     11
 DEF RDV_VM_PullsBlock     13
 DEF RDV_VM_PushesBlk      16


-------------------------------------------------------------------------------

 @COLD JUMP INIT

    ; Table of system parameters
   
    ACEDh
    *TEA_Here TEA_Head
    *PFS_ObjFName 'kernel' 0
    *SYS_ObjPath '/sys'    0
    *SYS_SrcPath '/sys/src/batch' 0


  @BOOT
  0 OVERLAY ; Reset overlay
  E INT 0
  E SOP sop_TXT_pos_set
  E SET :: FFFFh
  E SOP sop_TXT_colors

  L1 SOP sop_KEYSW_get ; Skip loading from SD card if switch set
  L2 INT 1             ; Select switch 0
     AND L1 L2
  L1 ELS >GOTCARD      ; Branch if switch is one
     JUMP :: INIT      ; Branch no return
  @GOTCARD

  E INT 42 ; ASCII *
  E SOP sop_TXT_glyphs

  L1 SET :: 200h  ; Image base address (skip bootloader blocks)
  L4 INT 0        ; First block high order (a 16-bit number!)
  L2 SET :: 2     ; First block low order, skip bootloader (lower 16 bit)
  L3 SET :: 254   ; Number of blocks (64k cells including 8K overlay 0)
  @1 JSR L2 L1 L4 :: SPI_RDBLK
     GET L2 +1
  L3 REP <1

 ; 1 OVERLAY
 ; E INT 65
 ; E SOP sop_TXT_glyphs
 ; L2 SET :: 256   ; First block low order
 ;    JSR L2 :: LDOVL

 ; 2 OVERLAY
 ; E INT 66
 ; E SOP sop_TXT_glyphs
 ; L2 SET :: 288   ; First block low order
 ;    JSR L2 :: LDOVL

 ; 3 OVERLAY
 ; E INT 67
 ; E SOP sop_TXT_glyphs
 ; L2 SET :: 320   ; First block low order
 ;    JSR L2 :: LDOVL

 ; 4 OVERLAY
 ; E INT 68
 ; E SOP sop_TXT_glyphs
 ; L2 SET :: 352   ; First block low order
 ;    JSR L2 :: LDOVL

  0 OVERLAY   ; Reset overlay
  JUMP :: INIT ; Branch no return

-------------------------------------------------------------------------------

 @LDOVL
  L1 SET :: E000h ; Image base address
  L2 GET A1 ; First block low order (lower 16 bit)
  L3 INT 32 ; Number of blocks (8K cells)
  L4 INT 0  ; First block high order (a 16-bit number!)
  @1 JSR L2 L1 L4 :: SPI_RDBLK
     GET L2 +1
  L3 REP <1
 RET

  @SPIDELAY
  L1 INT 24                  ; Wait for this many iterations
  @1 GET L1 -1               ; Decrement counter
  L1 THN <1                  ; Do remaining iterations
     RET

 @SPISDRESET   L4 INT 0
  L1 INT 1
  L5 INT 8                   ; Repeat once if reset failure
  @2
  L4 SOP sop_SD_SET_CS       ; CS low
     JSR :: SPIDELAY
  L1 SOP sop_SD_SET_MOSI     ; MOSI high
  L1 SOP sop_SD_SET_CS       ; CS high
     JSR :: SPIDELAY
  L2 INT 10                  ; Toggle clock for >74 cycles
  L3 SET :: FFh              ; Dummy byte  -- "SET :: FFh" MUST GO AWAY
  @1 JSR L3 :: SPI_WRBYTE    ; Write dummy byte (MOSI high)
  L2 REP <1
  L4 SOP sop_SD_SET_CS       ; Chip select low (starts byte cnt), issue cmd 0
     JSR :: SPIDELAY         ; Give it time to settle
     JSR L3 :: SPI_WRBYTE    ; Send a dummy byte before cmd, spec refers to NCs
  L3 SET :: 40h              ; Send CMD 0: 40 00 00 00 00 95
     JSR L3 :: SPI_WRBYTE
  L3 INT 0
     JSR L3 :: SPI_WRBYTE
     JSR L3 :: SPI_WRBYTE
     JSR L3 :: SPI_WRBYTE
     JSR L3 :: SPI_WRBYTE
  L3 SET :: 95h              ; CRC
     JSR L3 :: SPI_WRBYTE
     JSR L3 L6 :: SPI_RDRESP ; Read 8 bit response L3
  L6 ELS >3                  ; Branch if no timeout
   L5 REP <2
   @3 RET ; SD card is now in idle mode      

 @SPISDCMD8                  ; Must call this for newer cards
  L4 INT 0
  L1 INT 1
  L7 INT 8
  @1
  L1 SOP sop_SD_SET_CS       ; CS high
     JSR :: SPIDELAY
  L4 SOP sop_SD_SET_CS       ; CS low
     JSR :: SPIDELAY
  L3 SET :: FFh
     JSR L3 :: SPI_WRBYTE    ; Send dummy byte
  L3 SET :: 48h
     JSR L3 :: SPI_WRBYTE    ; CMD8
  L3 INT 0
     JSR L3 :: SPI_WRBYTE
     JSR L3 :: SPI_WRBYTE
  L3 SET :: 01h
     JSR L3 :: SPI_WRBYTE
  L3 SET :: AAh
     JSR L3 :: SPI_WRBYTE
  L3 SET :: 87h              ; CRC
     JSR L3 :: SPI_WRBYTE
     JSR L3 L6 :: SPI_RDRESP
  L6 ELS >3
  L7 REP <1
  @3
  A1 GET L3
 RET

 @SPI_SDCMD                 ; Send SD command A2, 32 bit params A3:A4
  L4 INT 0
  L1 INT 1
  L7 INT 8                   ; Repeat up to 8 times on SPI_RDRESP timeout
  L5 SET :: FFh
  L2 SET :: 40h
  @1
  L1 SOP sop_SD_SET_CS       ; CS high
     JSR :: SPIDELAY
  L4 SOP sop_SD_SET_CS       ; CS low
     JSR :: SPIDELAY
     JSR L5 :: SPI_WRBYTE    ; Send dummy byte
  L3 GET A2
     IOR L3 L2               ; Mask in fixed value
     JSR L3 :: SPI_WRBYTE
  L3 GET A3                  ; Encode high order word
     SHR L3 8
     AND L3 L5
     JSR L3 :: SPI_WRBYTE
  L3 AND A3 L5
     JSR L3 :: SPI_WRBYTE
  L3 GET A4                  ; Encode low order word
     SHR L3 8
     AND L3 L5
     JSR L3 :: SPI_WRBYTE
  L3 AND A4 L5
     JSR L3 :: SPI_WRBYTE
  L3 INT 1                   ; Dummy CRC
     JSR L3 :: SPI_WRBYTE
     JSR L3 L6 :: SPI_RDRESP
  L6 ELS >4
  L7 REP <1
  @4
  A1 GET L3
 RET

   @SPISDINIT                  ; Reset SD card and set SPI mode
     JSR :: SPISDRESET
     JSR L3 :: SPISDCMD8
          JSR L3 L6 :: SPI_RDRESP
          JSR L3 L6 :: SPI_RDRESP
          JSR L3 L6 :: SPI_RDRESP
          JSR L3 L6 :: SPI_RDRESP
  L1 SET :: 512
  @1
  L6 SET :: 55
  L7 INT 0
     JSR L3 L6 L7 L7 :: SPI_SDCMD ; CMD55 "prefix"
  L6 SET :: 41
  L3 SET :: 4000h ; Par select SDHC card
     JSR L3 L6 L3 L7 :: SPI_SDCMD    ; CMD41
  L3 ELS >2
  L1 REP <1
  @2 RET

 @SPI_RDRESP                 ; Read byte until either not FFh or timeout
  L1 SET :: 1024             ; Repeats before timeout
  L3 SET :: FFh
  A2 INT 0                   ; Assume no timeout occurs
  @1 JSR L2 :: SPI_RDBYTE
  A1 GET L2
     SUB L2 L3               ; Compare to FFh
     THN >2                  ; Branch if valid response
  L1 REP <1
  A2 INT 1                   ; Flag timeout
  @2
 RET

 @SPI_WRBYTE                 ; Write 8 bits from A1 to MOSI line, MSB first
  L1 GET A1                  ; Copy A1
  L5 INT 8                   ; Toggle clock 8 times
  L2 INT 1                   ; High value
  L6 INT 0                   ; Low value
  L4 SET :: 8000h            ; MSB mask
     SHL L1 8                ; Shift output byte to MSB position
  @1 L3 AND L1 L4            ; Obtain current MSB
     L6 SOP sop_SD_SET_SCLK  ; Pull clock low
        JSR :: SPIDELAY      ; Let it settle
     L3 SOP sop_SD_SET_MOSI  ; Output current MSB to MOSI
        JSR :: SPIDELAY      ; Give it time to settle
     L2 SOP sop_SD_SET_SCLK  ; Pull clock high
        JSR :: SPIDELAY      ; Let it settle (SD card registers MOSI)
     L6 SOP sop_SD_SET_SCLK  ; Pull clock low (discard MISO result)
        JSR :: SPIDELAY      ; Let it settle
        SHL L1 1             ; Discard current MSB, get next
     L5 REP <1               ; Do remaining bits
 RET

 @SPI_RDBYTE                 ; Read 8 bit into A1 via LSB, write dummy values
  L5 INT 8                   ; Toggle clock 8 times
  L2 INT 1                   ; High value
  L6 INT 0                   ; Low value
  A1 INT 0                   ; Initialize read value
  L4 INT 0                   ; Clear MISO for virtual only
  L2 SOP sop_SD_SET_MOSI     ; Set MOSI high (dummy output)
  @1 L6 SOP sop_SD_SET_SCLK  ; Pull clock low
        JSR :: SPIDELAY      ; Let MOSI and CLK settle
     L2 SOP sop_SD_SET_SCLK  ; Pull clock high
        JSR :: SPIDELAY      ; Let it settle
     L4 SOP sop_SD_GET_MISO  ; Sample MISO line output from card
     L6 SOP sop_SD_SET_SCLK  ; Pull clock low
        JSR :: SPIDELAY      ; Let it settle
        SHL A1 1             ; Make space for current bit
        ADD A1 L4            ; Store current bit
     L5 REP <1               ; Do remaining bits
 RET

 *SPI_RDBLK                  ; Virtual call if VM
  L1 INT 16                  ; Time-out repeat count
  L1 SOP sop_VM_rdblk        ; Set L1 to 0 if VM
  L1 THN >3
     RET
  @3
  L7 GET A1                  ; A1 Block number to read from SD, A2 Data bufptr
  L2 GET A3                  ; A3 High order block number
  @2
     JSR :: SPISDINIT
  L5 INT 17
     JSR L3 L5 L2 L7 :: SPI_SDCMD ; CMD17 Read single block
  L3 ELS >4
  L1 REP <2
  @4 JSR L3 L6 :: SPI_RDRESP ; Receive "data token" FEh
  L1 SET :: 256              ; Word counter, receive 512 bytes
  @1 JSR L3 :: SPI_RDBYTE    ; High order
     JSR L4 :: SPI_RDBYTE    ; Low order
     SHL L3 8
     IOR L3 L4
  L3 STO A2
     GET A2 +1
  L1 REP <1
     JSR L3 L6 :: SPI_RDBYTE  ; Receive 2 byte CRC
     JSR L3 L6 :: SPI_RDBYTE
     RET

  *SPI_WRBLK                  ; Virtual call if VM
  L6 SET :: FFh              ; Byte mask
  L1 INT 16                  ; Time-out repeat count
  L1 SOP sop_VM_wrblk        ; Set L1 to 0 if VM
  L1 THN >3
     RET
  @3
  L7 GET A1                  ; A1 Block number to write to SD, A2 Data bufptr
  L2 GET A3                  ; A3 High order block number
  @2
     JSR :: SPISDINIT
  L5 SET :: 24
     JSR L3 L5 L2 L7 :: SPI_SDCMD ; CMD24 Write single block
  L3 ELS >4
  L1 REP <2
  @4 L3 SET :: FEh
     JSR L3 :: SPI_WRBYTE    ; Write "data token" FEh
  L1 SET :: 256              ; Word counter, write 512 bytes

  @5
  L3 LOD A2
  L4 SHR L3 8
     JSR L4 :: SPI_WRBYTE    ; High order
     AND L3 L6
     JSR L3 :: SPI_WRBYTE    ; Low order
     GET A2 +1
  L1 REP <5
     JSR L3 :: SPI_WRBYTE    ; Send 2 byte CRC
     JSR L3 :: SPI_WRBYTE
     JSR L3 :: SPI_RDBYTE    ; Read "data response" byte
  L1 SET :: 1024             ; Should be 5 (E5 masked => 5)
  @1
  L3 SOP sop_SD_GET_MISO     ; SD card pulls MISO low
  L3 THN >3                  ; until data stored away
  L1 REP <1
  @3
  RET

-------------------------------------------------------------------------------

 @INIT  L1 SET :: FFFFh
        L1 SOP sop_SEG7_set01
        L1 SOP sop_SEG7_set23
        L1 SOP sop_SEG7_set45

        L1 SET :: 000Fh
        L1 SOP sop_BGCOL_set

           JSR L1 :: CLRSCR           ; Set text RAM to blanks, not zeros
           JSR :: SCROLL_CLI
        L1 SET :: COLOR_white
        L1 PER :: TXTCOLOR
         ;  JSR :: 8T3_msg :: 'Paver Cannuccia' 10 0
        L1 SET :: COLOR_green
        L1 PER :: TXTCOLOR

        E SOP sop_CPU_id
        E EQL 1
       DR ELS >SKIP
        E SET :: KBDMAPUS             ; Use straight KBDMAP for VM
        E PER :: KBDMAP
        @SKIP

      ;  4 OVERLAY
      ;     JSR :: EDCLR
      ;    JSR :: EDBUFSWAP
      ;     JSR :: EDCLR
      ;     JSR :: EDBUFSWAP
      ;   0 OVERLAY

        L1 SOP sop_KEYSW_get
        L2 INT 1 ; Switch 0
           AND L1 L2
        L1 ELS >1

           ; SD card stuff

    @1  DR REF :: TEA_Here
           GET DR -1
           LOD DR                    ; Get addr of fake dict entry
        DR SOP sop_PC_set            ; Jump to TEA, no return

-------------------------------------------------------------------------------

 @KBDMAP       KBDMAPDE
 @TXTPOS_BASE  4048            ; 4096 - 48
 @TXTPOS       4048            ; Points to current text buffer cell
 @TXTCOLOR     COLOR_green

-------------------------------------------------------------------------------

Output character E (cooked) into text buffer at TXTPOS, advance by 1

 *8T3_putC

         L1 SET :: TXTPOS
         L2 LOD L1
         L3 GET E
         L3 SOP sop_VM_putc ; Hen if present sets L to 0
         L3 ELS >2

         L3 EQL ASC_tab
         DR ELS >0
            GET L2 +4
         L2 STO L1
            BRA >2

    @0   L3 EQL ASC_linefeed
         DR ELS >1
            JSR :: SCROLL_CLI
            BRA >2

    @1      L4 SET :: TXTCOLOR
            LOD L4
         L2 SOP sop_TXT_pos_set
         L3 SOP sop_TXT_glyphs
         L4 SOP sop_TXT_colors
            GET L2 +1
         L2 STO L1             ; TODO: scroll/reset line if 64 chars

    @2      RET

-------------------------------------------------------------------------------

  *8T3_prStr8                       ; Address in A1
  
  L3 GET A1
     BRA >CPY

  @PR_MSG                           ; Prints a zero terminated byte string
  
       L3 PULL

          @CPY L1 LOD L3
               L1 ELS >END          ; If NULL
               L2 GET L1
                  SHR L1 8          ; L1 is first char
               DR SET :: FFh
                  AND L2 DR         ; L2 is second char

               L1 EQL 3
               DR THN >3            ; If ASC End of Text
                E GET L1
                  JSR :: 8T3_putC

               L2 EQL 3
               DR THN >3            ; If ASC End of Text
                E GET L2
                  JSR :: 8T3_putC

          @3      GET L3 +1
                  BRA <CPY
 
  @END
  RET

------------------------------------------------------------------------------

 *CLEARLIN L6 SET :: 3968   ; From
           L1 SET :: 128    ; Chars
           L2 INT 32
      @CPY L6 SOP sop_TXT_pos_set
           L2 SOP sop_TXT_glyphs
              GET L6 +1
           L1 REP <CPY
           L1 SET :: TXTPOS
           L2 REF :: TXTPOS_BASE
           L2 STO L1
        @DONE RET

-------------------------------------------------------------------------------

 *CLRSCR L4 INT ASC_space
         L3 SET :: 4096   ; Should use sop_TXT_base

    @CPY L3 SOP sop_TXT_pos_set
         L4 SOP sop_TXT_glyphs
         A1 SOP sop_TXT_colors
         L3 REP <CPY
         L3 SOP sop_TXT_pos_set
         L4 SOP sop_TXT_glyphs
         A1 SOP sop_TXT_colors
         RET

-------------------------------------------------------------------------------

 *SCROLL_CLI   
               L1 SET :: 80           ; First column first line (copy to)
               L6 SET :: 80           ; Skip these many characters each line
               L7 SET :: 208          ; First column second line (copy from)

               L3 INT 31              ; Do this many rows
       @CPYO   L2 INT 48              ; Do this many columns per row
       @CPYI   L7 SOP sop_TXT_pos_set
               L4 SOP sop_TXT_glyphg
               L5 SOP sop_TXT_colorg

               L1 SOP sop_TXT_pos_set
               L4 SOP sop_TXT_glyphs
               L5 SOP sop_TXT_colors

                  GET L7 +1
                  GET L1 +1
               L2 REP <CPYI

                  ADD L7 L6
                  ADD L1 L6
               L3 REP <CPYO

         JSR :: CLEARLIN ; Resets TXTPOS to TXTPOS_BASE
 RET

-------------------------------------------------------------------------------

 @INS L6 GET A2                 ; A1 current pos, A2 current max pos
      L5 GET L6 +1

 @CPY L6 SOP sop_TXT_pos_set
      L2 SOP sop_TXT_glyphg     ; Read character
      L3 SOP sop_TXT_colorg

      L5 SOP sop_TXT_pos_set
      L2 SOP sop_TXT_glyphs     ; Write character
      L3 SOP sop_TXT_colors

         GET L5 -1
         GET L6 -1
      A1 LTR L6
      DR THN <CPY

         GET A2 +1              ; New rightmost character
      A1 SOP sop_TXT_pos_set    ; Restore original pos

 @DONE   RET

------------------------------------------------------------------------------

 @DEL             ; A1 position of deleted character, A2 rightmost character
 A1 GTR A2 -1
 DR THN >DONE     ; Won't delete at rightmost character (use backspace)
 L5 GET A1
 L6 GET A1 +1     ; Copy from here
 L1 SET :: 20h       ; ASCII space (black)

  @CPY L6 SOP sop_TXT_pos_set
       L2 SOP sop_TXT_glyphg  ; Read character
       L3 SOP sop_TXT_colorg

       L5 SOP sop_TXT_pos_set
       L2 SOP sop_TXT_glyphs  ; Write character
       L3 SOP sop_TXT_colors

          GET L5 +1
          GET L6 +1
       L6 EQR A2
       DR ELS <CPY

          GET A2 -1          ; New rightmost character
       L6 SOP sop_TXT_pos_set
       L1 SOP sop_TXT_glyphs  ; Replace rightmost character with space
       L1 INT 0
       L1 SOP sop_TXT_colors
       A1 SOP sop_TXT_pos_set    ; Reset original pos

 @DONE    RET

-------------------------------------------------------------------------------

 @GETLINE                 ; A1 return str size
 L6 SET :: TXTCOLOR
    LOD L6
 L1 REF :: TXTPOS_BASE
 L2 REF :: KBDMAP
 L5 REF :: TXTPOS_BASE    ; Current max pos
    GET L5 +1
    JSR :: CLEARLIN
 L1 SOP sop_TXT_curset
    ZOP zop_KB_reset

  @GETC IDLE              ; Implement F4 key: "eat" scroll command lines DOWN
        L3 SOP sop_KB_keyc
           ELS <GETC
           ZOP zop_GOTKEY
        L4 ADD L3 L2 ; Look up keycode in KBDMAP
        L3 LOD L4    ; Keycap char into L3

   @0   L3 EQL 12 ; Cursor left
        DR ELS >1
        DR REF :: TXTPOS_BASE
        DR EQR L1
        DR THN <GETC
           GET L1 -1
        L1 SOP sop_TXT_curset
           BRA <GETC
     
  @1   L3 EQL 14 ; Cursor right
        DR ELS >2
        L5 GTR L1 +1
        DR ELS <GETC
           GET L1 +1
        L1 SOP sop_TXT_curset
   @A      BRA <GETC

   @2   L3 EQL 10 ; Enter
        DR ELS >3
        A1 REF :: TXTPOS_BASE
        A1 SUB L1 A1
           RET ; Return from subroutine

   @3   L3 EQL 8 ; Backspace
        DR ELS >4
        L7 REF :: TXTPOS_BASE
        L7 EQR L1
        DR THN <A
           GET L1 -1
        L1 SOP sop_TXT_curset
           JSR L1 L5 :: DEL
           BRA <A

  @4   L3 EQL 127 ; Del
        DR ELS >5
        L5 GTR L1 +1
        DR ELS <A
           JSR L1 L5 :: DEL
           BRA <A

   @5      JSR L1 L5 :: INS
        L1 SOP sop_TXT_pos_set
           GET L1 +1
        L3 SOP sop_TXT_glyphs
        L6 SOP sop_TXT_colors
        L1 SOP sop_TXT_curset
           BRA <A

-------------------------------------------------------------------------------

 *8T3_prStr16      ; A1 is ptr to zero terminated string
   L7 GET A1
   @C L2 LOD L7
         E GET L2
            JSR :: 8T3_putC
            GET L7 +1
         L2 THN <C
 RET

-------------------------------------------------------------------------------

 *CMD_PUTCS      ; A1 is ptr to counted string
 L7 GET A1
 L1 LOD L7       ; First cell is string length
    GET L7 +1    ; Skip strlen

     @CPY  E LOD L7
            JSR :: 8T3_putC
            GET L7 +1
         L1 REP <CPY
 RET

-------------------------------------------------------------------------------

  *CMD_NCHAR      ; A1 is string ptr, A2 is string length

     @CPY  E LOD A1
            JSR :: 8T3_putC
            GET A1 +1
         A2 REP <CPY
 RET

-------------------------------------------------------------------------------

Use this function for command line input as it communicates well with Hen.

 *8T3_getLine16             ; A1 is ptr to string buffer, at least 64 words

    ZOP zop_TXT_SHOWCUR
 L6 GET A1
 L5 INT 64
  E INT RDV_VM_NeedsStr16
    RDV L6 L5             ; Hen if present sets E to 0
  E ELS >DONE
  
    JSR L5 :: GETLINE     ; Sets L5 to string size
    ZOP zop_TXT_HIDECUR

         L5 ELS >1
         L1 REF :: TXTPOS_BASE
    @CPY L1 SOP sop_TXT_pos_set
         L3 SOP sop_TXT_glyphg
         L3 STO L6
         GET L6 +1
         GET L1 +1
      L5 REP <CPY

   @1 L3 INT 0
      L3 STO L6
       ; JSR :: SCROLL_CLI

 @DONE
 RET

-------------------------------------------------------------------------------

Advance a given string pointer to the next non-space character. Line breaks
are considered non-space.

A1 IN Pointer to string, update

    *8T3_skipSpace
    L6 LOD A1
       GET A1 +1

        L6 EQL ASC_space
        DR THN <8T3_skipSpace

           L6 EQL ASC_tab
           DR THN <8T3_skipSpace

              GET A1 -1

         RET

-------------------------------------------------------------------------------

A1 Advance str16 ptr to next ASCII space
E  Return length

     *8T3_skipWord

                 L1 INT 0
             @1  A1 LODS
                  E EQL ASC_space
                    GET L1 +1 
                 DR ELS <1
     E GET L1              
     RET

-------------------------------------------------------------------------------

A1 IN Pointer to string 1, keep   This string may contain the termination char
A2 IN Pointer to string 2, keep
A3 IN Termination character, keep

E OUT 1:strings are equal / 0:strings are not equal

METHOD: Traverse string 1 and compare to string 2 character by character until
either the characters differ (0) or the termination character is found (1).

    *8T3_strCmp
    L1 GET A1   ; Pointer to string 1
    L2 GET A2   ; Pointer to string 2
    L3 INT 1    ; Assume success

    @1 L6 LOD L1
       E LOD L2
          GET L1 +1
          GET L2 +1

          L4 SUB L6  E   ; Compare both characters
             ELS >SUCC
          L3 INT 0       ; Else flag failure
    @SUCC
    SUB L6 A3   ; Compare to termination character
    ELS >TERM   ; If 0, since both characters are equal, both are terminators
    THN <1      ; Else do next character

    @TERM  E GET L3
      RET

-------------------------------------------------------------------------------

Shorten a string by shifting characters left, overwriting the beginning of
the string so that the total length becomes A2 characters.

A1 String base address pointer, keep          ; SHOULD GET A START OFFSET
A2 Requested string length, alter             ; TO BE USED JSR 0000.0000b

 *TRIMLEFT
  L6 GET A1
     JSR L6 L1        ; String length in L1 now
     8T3_strLen16
 
       SUB L1 A2        ; Set L1 to number of character shifts
    L2 ADD L6 L1     ; Set L2 to first character pos to keep
 @1  E LOD L2
     E STO L6
       GET L2 +1
       GET L6 +1
    L1 REP <1
       RET

-------------------------------------------------------------------------------

Shorten a 0 terminated string by removing the first characters on the left.

A1 String base address pointer
A2 Number of characters to remove

 *CUTLEFT
    L1 GET A1
    L2 ADD A1 A2
 @1  E LOD L2
     E STO L1
       GET L2 +1
       GET L1 +1
     E THN <1
       RET

-------------------------------------------------------------------------------

A1 Preserve numeric value to show

  *8T3_hex

          L1 GET E

               E GET A1
                 JSR :: 8T3_prHex
               E INT 104           ; ASCII h
                 JSR :: 8T3_putC
         
               E INT ASC_space
                 JSR :: 8T3_putC

           E GET L1
             RET

-------------------------------------------------------------------------------

A1 Preserve numeric value to show

  *8T3_dec

          L1 GET E

               E GET A1
                 JSR :: 8T3_prUDec
               E INT 100           ; ASCII d
                 JSR :: 8T3_putC
         
               E INT ASC_space
                 JSR :: 8T3_putC

           E GET L1
             RET

-------------------------------------------------------------------------------

  *8T3_msg

        L7 GET E

    @1  L1 PULL
        L1 ELS >5
        L2 GET L1
         E SHR L1 8          ; L1 is first char
           JSR :: 8T3_putC
        DR SET :: FFh
         E AND L2 DR         ; L2 is second char
           JSR :: 8T3_putC
           BRA <1
     
    @5   E GET L7
           RET

-------------------------------------------------------------------------------

  @8T3_showRegs  ; Preserve E

  L1 GET E

     JSR :: 8T3_msg :: 'E:' 0     
     JSR :: 8T3_prSDec

   E GET A1
     JSR :: 8T3_msg :: ' (signed)  A1:' 0 
     JSR :: 8T3_prUDec

   E GET A2
     JSR :: 8T3_msg :: '  A2:' 0 
     JSR :: 8T3_prUDec

   E GET A3
     JSR :: 8T3_msg :: '  A3:' 0 
     JSR :: 8T3_prHex

   E GET A4
     JSR :: 8T3_msg :: '  A4:' 0 
     JSR :: 8T3_prHex
     JSR :: 8T3_msg :: 10 0

   E GET L1  
     RET

-------------------------------------------------------------------------------

Must be aligned. Preserve E.

A1 Preserve buffer address
A2 Preserve byte offset
A3 Preserve byte value (in LSB)

 *8T3_stByte

         L1 GET A1   
         L2 GET A2
            SHR L2 1      ; Divide by two, now CELL offset
            ADD L2 L1     ; Address of CELL in which the byte will be stored
         L3 LOD L2        ; CELL value in which the byte will be stored
         L4 GET A3

         DR INT 1         ; Mask bit 0
            AND DR A2     ; Check if even or odd
         DR ELS >ODD

         DR SET :: FF00h  ; Overwrite LSB
            AND L3 DR     ; Clear LSB of the CELL        
            IOR L3 L4     ; Add the new byte in
            BRA >DONE
    
    @ODD DR SET :: FFh    ; Overwrite MSB
            AND L3 DR     ; Clear MSB of the CELL
            SHL L4 8      ; Shift byte to MSB position
            IOR L3 L4     ; Add in the new byte

  @DONE  L3 STO L2
            RET

-------------------------------------------------------------------------------

Must be aligned. Preserve E.

A1 Preserve buffer address
A2 Preserve byte offset
A3 Return byte value (in LSB)

 *8T3_ldByte

         L1 GET A1
         L2 GET A2
            SHR L2 1    ; Divide by two, now SHORT offset
            ADD L2 L1   ; Address of the SHORT in which the byte is stored
         A3 LOD L2      ; SHORT value in which the byte is stored

         DR INT 1       ; Mask bit 0
            AND DR A2   ; Check if even or odd
         DR ELS >ODD

         DR SET :: FFh  ; Byte is in LSB
            AND A3 DR   ; Clear MSB        
            BRA >DONE

    @ODD    SHR A3 8    ; Byte is in MSB, shift to LSB position

      @DONE RET

-------------------------------------------------------------------------------

A1 Preserve pointer to byte string (src)
A2 Preserve pointer to SHORT string (dest)

 *8T3_toStr16
                L1 GET A1
                L2 GET A2
                L3 INT 0  ; Byte offset

             @1    JSR L1 L3 L4 :: 8T3_ldByte
                L4 ELS >DONE
                L4 STO L2
                   GET L3 +1
                   GET L2 +1
                   BRA <1

          @DONE L4 STO L2
                   RET

-------------------------------------------------------------------------------

Convert a wide character string to byte string, network order
A1 ptr to src, A2 ptr to target
E Return string length

 *8T3_toStr8
              L1 GET A1
              L2 GET A2
              L3 INT 0

          @1  DR LOD L1

                 JSR L2 L3 DR :: 8T3_stByte
                 GET L3 +1
                 GET L1 +1
              DR ELS >Q
                 BRA <1

          @Q   E GET L3
                 RET

-------------------------------------------------------------------------------

Convert register value into number string.

A1 Number to convert, keep
A2 Pointer to divisor table, alter
A3 Output string base address pointer, update
A4 Padding character - if 0, no padding, bit 7 is sign flag, alter

 *NUMBERSTR
 L6 SET :: 7FFFh
 L3 AND A4 L6        ; L3 is the padding character (stripped off sign flag)
 L6 GET A1
 L1 LOD A2           ; Get first divisor for later

 ;A1 THN >0           ; Branch if number non-zero
 ;L5 SET :: ASC_0     ; Simply store ASCII zero + padding and return
 ;L5 STO A3
 ;   GET A3 +1
 ;A4 ELS >A
 ;
 ;@A RET
 @0
 DR SET :: 8000h
  E AND DR A4
 A4 INT 0            ; A4 is now a condition: no leading non-zero digit yet
  E ELS >1           ; If MSB not set, output as unsigned number
  E AND DR L6        ; Test sign bit of number to output
  E ELS >1           ; If set, output a minus sign and negate the number
 DR SET :: FFFFh
 L6 EOR DR L6
    GET L6 +1
    L7 SET :: ASC_minus
    L7 STO A3
       GET A3 +1

 @1    JSR L6 L1 L5 L7 :: 8T3_divMod

       L6 GET L7     ; Remainder becomes new number to convert
       L5 THN >2     ; Store quotient as digit in string if non-0
       A4 THN >2     ; Output anything after leading non-zero
       L3 ELS >4     ; or skip this digit if no padding requested
       L5 GET L3     ; Output padding char instead of digit
          BRA >3     ; Next digit

 @2    A4 INT 1      ; Leading non-zero digit present
       L3 INT 0      ; Disable padding after first significant digit

          JSR L5 :: DIGIT2ASC

 @3    L5 STO A3
          GET A3 +1  ; Advance string pointer for next digit
 @4       GET A2 +1  ; Advance to next divisor
       L1 LOD A2
       L1 THN <1     ; If divisor was not 0, repeat

    RET      

-------------------------------------------------------------------------------

Parse a 0 or SP terminated string representation of a number including optional
minus sign and base suffix (b or h) into a number using STRTONUM.

A1 IN Source address, leave
A2 IN Number result

E OUT 0: Number conversion successful / 1: Conversion error

 *PARSENUM
    JSR L3 :: 8T3_claim
 L6 GET A1
 L1 INT 10                      ; Assume decimal number

 L5 GET L3
  E INT ASC_space               ; Terminate on NULL or Space
    JSR L6 L5 :: 8T3_strCpy
  E INT 0
  E STO L5                      ; Force 0 terminator, not space  
    GET L5 -1
 L7 LOD L5
 L4 SET :: ASC_b
    SUB L4 L7
    THN >1
 L1 INT 2
 L4 INT 0
 L4 STO L5        ; Overwrite b with new 0 terminator
     BRA >2A
  @1
 L7 LOD L5
 L4 SET :: ASC_h
    SUB L4 L7
    THN >2A
 L1 INT 16
 L4 INT 0
 L4 STO L5        ; Overwrite h with new 0 terminator

 @2A
 L5 LOD L3
  E SET :: ASC_plus
    SUB  E L5
 L5 GET L3
  E THN >2B
    GET L5 1      ; SKIP plus sign
    BRA >4

 @2B
 L5 LOD L3
 L4 SET :: ASC_minus
    SUB L4 L5
 L5 GET L3
 L4 THN >4
    GET L5 1      ; SKIP minus sign

 @4
    JSR L5 L1 L7 :: STRTONUM
 L4 THN >@
 DR SET :: FFFFh
 L7 EOR DR L7
    GET L7 1
 @@
 A2 GET L7
    JSR L3 :: 8T3_cede
    RET

-------------------------------------------------------------------------------

Convert a null terminated string (digits + _ only) to a number using ASCTONUM.

A1 IN Source address, leave
A2 IN Number base, leave
A3 IN Number result

E OUT 0: Successful conversion / 1: Conversion error

 *STRTONUM
 L6 GET A1
 L1 GET A2
 A3 INT 0
 L2 INT 1                   ; Initial multiplier

       JSR L6 L3 :: 8T3_strLen16
       ADD L6 L3              ; L6 to END of string (least significant digit)

    @1 GET L6 -1
    L4 LOD L6
    L4 EQU ASC_underscore     ; Ignore any underscores
    DR THN >A
      JSR L4 L1 L4 :: ASCTONUM
    DR INT 1
    E ELS >2

       JSR L2 L4 L4 L5 :: 8T3_uMul   ; Multiply current digit by multiplier
       ADD A3 L4                 ; Add to result
       JSR L2 L1 L2 L5 :: 8T3_uMul   ; Multiply current multiplier by base

 @A L3 REP <1
    DR INT 0
  @2  E GET DR
       RET

-------------------------------------------------------------------------------

This function turns an ASCII representation of a digit into a number value,
for example ASCII 49 = '1' into the number 1.
ASCII character in A1, number base in A2. Return number in A3.
If character valid for number base E is 0 else 1.

E OUT 0: Successful conversion / 1: Conversion error

     *ASCTONUM

            L1 GET A1             ; Copy ASCII character
            L4 GET A2             ; Copy base
            L3 INT 10
            L2 SET :: ASC_0
            L2 SUB L1 L2          ; Subtract the ASCII code for 0 from it
            L2 LTR L3             ; Digit obtained must be smaller than 10
            DR THN >ISDECI

            L2 SET :: ASC_A          ; Not a decimal digit, so try letters
            L2 SUB L1 L2          ; Subtract ASCII "A" from it
               ADD L2 L3          ; Add 10

   @ISDECI  L4 GTR L2             ; Digit must be smaller than base
             E GET DR

            A3 GET L2
               RET

 @DIGIT2ASC ; Digit value in A1, return ASCII code in A1

       A1 GTL 9
       E GET DR
       DR INT 55    ; Mapping constant for ASCII conversion
          ADD A1 DR    ; Add 55 to the digit, preliminary ASCII code
       E THN >1      ; If >9: 55 + 10 = ASCII A
       L1 INT 7     ; If <10 55 - 7 = ASCII 0
          SUB A1 L1   ; Fix ASCII code to be digit between 0 and 9
    @1    RET

-------------------------------------------------------------------------------

Divide two unsigned numbers. Dividend in A1, divisor in A2.
Return quotient in A3, remainder in A4.

 *8T3_divMod  L6 GET A1      ; Copy of dividend
          L1 GET A2      ; Copy of divisor

          A3 INT 0     ; Initialise quotient
          L2 INT 16    ; Maximum number of bit shifts
          L3 INT 1     ; Counter for shifted bits

          L4 SET :: 8000h

    @1    L7 AND L1 L4   ; Check if divisor MSB set
          L7 THN >2      ; If divisor MSB set, break loop
             SHL L1 1    ; Shift divisor left 1 bit
             GET L3 +1   ; Increment bit counter
          L2 REP <1      ; Repeat until either MSB set or 16 bits

    @2       SHL A3 1    ; Shift quotient left 1 bit
          L2 SUB L6 L1   ; Subtract divisor from divd
          DR ELS >3      ; Carry in D
          L6 GET L2      ; Accept subtraction
             GET A3 +1   ; Set quotient SB
    @3       SHR L1 1    ; Shift divisor right for next subtraction
          L3 REP <2

          A4 GET L6
             RET

-------------------------------------------------------------------------------

Divide 32-bit unsigned by 32 bit unsigned.
Dividend in A1 (high order) A2, divisor in A3 (high order) A4.
Return quotient in A1 (high order) A2.
Return remainder in A3 (high order) A4.

 *8T3_divMod32

          L1 INT 0       ; Initialise quotient (high)
          L2 INT 0       ; Initialise quotient (low)
          L3 INT 32      ; Maximum number of bit shifts
          L4 INT 1       ; Counter for shifted bits
          L5 SET :: 8000h

    @1    L7 AND A3 L5   ; Check if divisor (high) MSB set
          L7 THN >2      ; If divisor MSB set, break loop
             SHL A3 1    ; Shift divisor (high) left 1 bit
          DR AND A4 L5   ; Check if shift carry
             SHL A4 1    ; Shift divisor (low) left 1 bit
          DR ELS >X      ; Branch if no shift carry
             GET A3 +1   ; Add shift carry
    @X       GET L4 +1   ; Increment bit counter
          L3 REP <1      ; Repeat until either MSB set or counter zero

    @2       SHL L1 1    ; Shift quotient left 1 bit (high)
          DR AND L2 L5   ; Check if shift carry
             SHL L2 1    ; Shift quotient left 1 bit (low)
          DR ELS >W      ; Branch if no shift carry
             GET L1 +1   ; Add shift carry

   @W     L6 SUB A1 A3   ; Subtract divisor from dividend (high)
           E IOR A1 A3
           E ELS >U      ; Skip if dividend and divisor (high) zero
          DR ELS >3      ; Branch if carry clear (divisor greater than div'd)
    @U    L7 SUB A2 A4   ; Subtract divisor from dividend (low)
          DR ELS >3      ; Branch if carry clear (divisor greater than div'd)
    @V    A1 GET L6      ; Accept subtraction (high)
          A2 GET L7      ; Accept subtraction (low)
             GET L2 +1   ; Set quotient LSB

    @3    DR INT 1       ; LSB mask
             AND DR A3   ; Check if shift carry
             SHR A3 1    ; Shift divisor (high) right for next subtraction
             SHR A4 1    ; Shift divisor (low) right for next subtraction
          DR ELS >Y      ; Branch if no shift carry
             ADD A4 L5   ; Add shift carry
    @Y    L4 REP <2

          A3 GET A1
          A4 GET A2
          A1 GET L1
          A2 GET L2

             RET

-------------------------------------------------------------------------------

Multiply two unsigned numbers A1 and A2. Return low order
result in A3, high order in A4.

 *8T3_uMul  L6 GET A1       ; Copy of multiplier, leave A1
            L1 GET A2       ; Copy of multiplicand, leave A2
            L4 INT 1
            L5 SET :: 8000h

            A3 GET L6       ; Initialise low order result with multiplier
            A4 INT 0        ; Initialise A4 to 0, will become high order result
            L2 INT 16       ; Repeat 16 times = 16 bits

     @LOOP  L7 AND A3 L4    ; Test if bit 0 of the multiplier is set
            L7 ELS >1       ; Skip adding the multiplicand if bit not set
               ADD A4 L1    ; Add multiplicand
        @1  L3 AND A4 L4    ; Check if bit 0 of the high order result is set
               SHR A4 1     ; Shift high order result right 1 bit
               SHR A3 1     ; Shift low order result right 1 bit
            L3 ELS >2       ; Skip importing bit if it was 0
               IOR A3 L5    ; Import bit shifted out from high order
        @2
            L2 REP <LOOP    ; Repeat
               RET

-------------------------------------------------------------------------------

Requires separator literal after JSR

A1 Preserve str8 pointer
A2 Return length in bytes

       *8T3_strLen8

            L1 GET A1
            L2 INT 0
            L3 PULL

       @1      JSR L1 L2 DR :: 8T3_ldByte
            DR EQR L3
            DR THN >Q
               GET L2 +1
               BRA <1

       @Q   A2 GET L2
       RET

-------------------------------------------------------------------------------

Return size of 0 terminated cell string.

A1 Source address, leave
A2 String size result

 *8T3_strLen16
 L6 GET A1
 A2 INT 0
 @1 L7 LOD L6
    ELS >2
    GET L6 1
    GET A2 1
        BRA <1
 @2 RET

-------------------------------------------------------------------------------

 @ORDER ; Bring A1 A2 to ascending order
     A2 GTR A1
     DR THN >QUIT
     DR GET A1
     A1 GET A2
     A2 GET DR
 @QUIT
 RET

-------------------------------------------------------------------------------

 @CPFROMTO ; Copy str at addr A1 to A2 into buffer at A3
    A1 EQR A2
    DR THN >QUIT
    A1 LODS
    A3 STOS
    A1 EQR A2
    DR ELS <CPFROMTO
    DR INT 0
    DR STO A3
 @QUIT
 RET

-------------------------------------------------------------------------------

 @CPNONULL ; Copy str at A1 to buffer at A2, exclude final NULL
    L2 GET A2
 @1 A1 LODS
    E ELS >QUIT
    L2 STOS
       BRA <1
 @QUIT
 RET

------------------------------------------------------------------------------

Copy terminated string within RAM, terminator symbol in E, do not go past
end of string. Return flag in E whether null character found.
A1 Src addr, A2 Dest addr

 *8T3_strCpy   L1 INT 1    ; Assume NULL found
               L2 GET E

          @A   A1 LODS
               A2 STOS
               E ELS >B
               E EQR L2
               DR ELS <A
               L1 INT 0    ; Reset NULL flag

          @B      GET A1 -1  ; Undo pre-increment
                  GET A2 -1
               E GET L1
                  RET

-------------------------------------------------------------------------------

 *NCONVBUF  BUF 18

 *POW2DESC 32768 16384 8192 4096 2048 1024 512 256 128 64 32 16 8 4 2 1 0

 *POW10DESC 10000 1000 100 10 1 0

 *POW16DESC 4096 256 16 1 0

 @KBDMAPUS

 00h 01h 02h 03h 04h 05h 06h 07h 08h 09h 0Ah 0Bh 0Ch 0Dh 0Eh 0Fh
 10h 11h 12h 13h 14h 15h 16h 17h 18h 19h 1Ah 1Bh 1Ch 1Dh 1Eh 1Fh
 20h 21h 22h 23h 24h 25h 26h 27h 28h 29h 2Ah 2Bh 2Ch 2Dh 2Eh 2Fh
 30h 31h 32h 33h 34h 35h 36h 37h 38h 39h 3Ah 3Bh 3Ch 3Dh 3Eh 3Fh
 40h 41h 42h 43h 44h 45h 46h 47h 48h 49h 4Ah 4Bh 4Ch 4Dh 4Eh 4Fh
 50h 51h 52h 53h 54h 55h 56h 57h 58h 59h 5Ah 5Bh 5Ch 5Dh 5Eh 5Fh
 60h 61h 62h 63h 64h 65h 66h 67h 68h 69h 6Ah 6Bh 6Ch 6Dh 6Eh 6Fh
 70h 71h 72h 73h 74h 75h 76h 77h 78h 79h 7Ah 7Bh 7Ch 7Dh 7Eh 7Fh
 80h 81h 82h 83h 84h 85h 86h 87h 88h 89h 8Ah 8Bh 8Ch 8Dh 8Eh 8Fh
 90h 91h 92h 93h 94h 95h 96h 97h 98h 99h 9Ah 9Bh 9Ch 9Dh 9Eh 9Fh
 A1h A2h A3h A4h A4h A5h A6h A7h A8h A9h AAh ABh ACh ADh AEh AFh
 B0h B1h B2h B3h B4h B5h B6h B7h B8h B9h BAh BBh BCh BDh BEh BFh
 C0h C1h C2h C3h C4h C5h C6h C7h C8h C9h CAh CBh CCh CDh CEh CFh
 D0h D1h D2h D3h D4h D5h D6h D7h D8h D9h DAh DBh DCh DDh DEh DFh
 E0h E1h E2h E3h E4h E5h E6h E7h E8h E9h EAh EBh ECh EDh EEh EFh
 F0h F1h F2h F3h F4h F5h F6h F7h F8h F9h FAh FBh FCh FDh FEh FFh

 @KBDMAPDE

 ; Map US to German keyboard layout, redirected values in decimal
 ; This works as follows:
 ; Keycodes are mapped to ASCII US kb layout by FPGA,
 ; and those ASCII are then mapped to German kb ASCII by this table

 00h 01h 02h 03h 04h 05h 06h 60  08h 09h 0Ah 0Bh 0Ch 0Dh 0Eh 62
 10h 11h 12h 13h 14h 15h 16h 17h 18h 19h 1Ah 1Bh 1Ch 1Dh 62  60
 20h 21h 93  64  24h 25h 47  125 41  61  40  96  59  2Dh 58  95
 30h 31h 32h 33h 34h 35h 36h 37h 38h 39h 91  123 44  46  46  45
 34  41h 42h 43h 44h 45h 46h 47h 48h 49h 4Ah 4Bh 4Ch 4Dh 4Eh 4Fh
 50h 51h 52h 53h 54h 55h 56h 57h 58h 90  89  252 96  43  38  63
 60h 61h 62h 63h 64h 65h 66h 67h 68h 69h 6Ah 6Bh 6Ch 6Dh 6Eh 6Fh
 70h 71h 72h 73h 74h 75h 76h 77h 78h 122 121 220 35  42  7Eh 7Fh
 80h 81h 82h 83h 84h 85h 86h 87h 88h 89h 8Ah 8Bh 8Ch 8Dh 8Eh 8Fh
 90h 91h 92h 93h 94h 95h 96h 97h 98h 99h 9Ah 9Bh 9Ch 9Dh 9Eh 9Fh
 A1h A2h A3h A4h A4h A5h A6h A7h A8h A9h AAh ABh ACh ADh AEh AFh
 B0h B1h B2h B3h B4h B5h B6h B7h B8h B9h BAh BBh BCh BDh BEh BFh
 C0h C1h C2h C3h C4h C5h C6h C7h C8h C9h CAh CBh CCh CDh CEh CFh
 D0h D1h D2h D3h D4h D5h D6h D7h D8h D9h DAh DBh DCh DDh DEh DFh
 E0h E1h E2h E3h E4h E5h E6h E7h E8h E9h EAh EBh ECh EDh EEh EFh
 F0h F1h F2h F3h F4h F5h F6h F7h F8h F9h FAh FBh FCh FDh FEh FFh

-------------------------------------------------------------------------------

 *8T3_prHex    ; Print number in E as hexadecimal

 L6 GET E

     L1 SET :: POW16DESC
     L2 SET :: NCONVBUF
     L3 SET :: 30h                          ; Pad with 0s (30h) unsigned
        JSR L6 L1 L2 L3 :: NUMBERSTR
     L3 INT 0
     L3 STO L2
     L2 SET :: NCONVBUF
        JSR L2 :: 8T3_prStr16
 
    RET

-------------------------------------------------------------------------------

 *8T3_prUDec   ; Print number in E as unsigned decimal

 L6 GET E

     L1 SET :: POW10DESC
     L2 SET :: NCONVBUF
     L3 SET :: 8000h                       ; No padding, reset sign bit
        JSR L6 L1 L2 L3 :: NUMBERSTR
     L3 INT 0
     L3 STO L2
     L2 SET :: NCONVBUF
        JSR L2 :: 8T3_prStr16
 
    RET

-------------------------------------------------------------------------------

 *8T3_prSDec   ; Print number in E as signed decimal

 L6 GET E

     L1 SET :: POW10DESC
     L2 SET :: NCONVBUF
     L3 SET :: 8000h                       ; No padding, sign bit 7
        JSR L6 L1 L2 L3 :: NUMBERSTR
     L3 INT 0
     L3 STO L2
     L2 SET :: NCONVBUF
        JSR L2 :: 8T3_prStr16

    RET

-------------------------------------------------------------------------------

Set up irq driven editor

    @H_CMD_EDIT   ; Pass in beach number in A1


     ; Register and enable an interrupt handler for keyboard events
     6 IRQ-VEC :: IRQ_ED_HANDLER ; Register handler
    DR INT 0
    E SET :: 128 ; bit 7
     2 SERVICE ; Enable KB intr
     ; Loop until ESC key pressed (irq handler sets EDITING to 0)
     ; All keys are handled by kb interrupt handler
     ; 4 OVERLAY
     L7 GET A1
     L6 REF :: EDBEACH
     L7 PER :: EDBEACH
     L6 EQR L7
     DR THN >1

       E REF :: EDCUR          ; Reset cursor to top left
       DR INT 0
       DR STO E

   @1   JSR :: EDLDBEACH
        JSR :: EDUPDATE
     E INT 1
     E PER :: EDITING
        ZOP zop_TXT_SHOWCUR

     @WAITESC ZOP zop_VM_IDLE ; without this line must press ESC twice, why
           E REF :: EDITING
           E THN <WAITESC
       ZOP zop_TXT_HIDECUR
       RET

-------------------------------------------------------------------------------

   @IRQ_ED_HANDLER
        L1 REF :: KBDMAP
        L2 SOP sop_KB_keyc
           ZOP zop_GOTKEY
        L3 ADD L1 L2 ; Look up keycode in KBDMAP
           LOD L3    ; Keycap char into L3
        L3 EQL 27 ; Escape key
        DR THN >QUITED
       ;  4 OVERLAY ; Switch to 8K Editor overlay
           JSR L3 :: EDKEYHANDLER
           JSR :: EDUPDATE ; Each keypress updates editor screen
         0 RETI
     @QUITED
    DR INT 0
    DR PER :: EDITING ; Clear waiting flag
    E SET :: 128 ; bit 7
     1 SERVICE ; Disable KB intr
    L1 REF :: TXTPOS
    L1 SOP sop_TXT_curset
   0 RETI      

-------------------------------------------------------------------------------

 @BEACH_TO_BLOCK
   L1 REF :: BEACHBASE
   L2 SHL A1 3          ; Multiply by 8
      SHL A1 1          ; Multiply by 2
      ADD A1 L2         ; Multiply by 10
      ADD A1 L1         ; Add to first block index of beach region
 RET

-------------------------------------------------------------------------------

A1 Preserve str8 ptr
A2 Preserve char count, includes NULL terminator

   *8T3_chop

       L1 GET A1
       L2 INT 0
       L4 GET A2

      @1     JSR L1 L2 L3 :: 8T3_ldByte     ; Skip to NULL
             GET L2 +1
          L3 THN <1
             GET L2 -1

          L3 INT 0
      @2     JSR L1 L2 L3 :: 8T3_stByte     ; Remove L4 trailing chars
          L2 ELS >END
             GET L2 -1
          L4 REP <2

   @END
   RET

-------------------------------------------------------------------------------

 @8T3_BlocksPool 8000h   ; Beginning of allocation pool
 @8T3_BlocksCount 10h    ; Size of region = BlocksBase + BlocksCount * 256
 @8T3_BlocksInfo BUF 10h ; Reference count for each block, zero means free

------------------------------------------------------------------------------

  *8T3_claim  ; Return base addr of 256 cell buffer in A1, or zero
  
  L1 REF :: 8T3_BlocksCount
  L2 SET :: 8T3_BlocksInfo
  L3 SET :: 256
  A1 REF :: 8T3_BlocksPool

  L7 GET E

  @1  E LOD L2       ; Check ref count
      E ELS >FOUND

        GET L2 +1    ; Next in pool  
        ADD A1 L3    
     L1 REP <1
     A1 INT 0
        JSR :: 8T3_msg :: 'Claim failed!' 10 0

      E GET L7  
        RET
  
  @FOUND  E INT 1    ; Reserve block A1
          E STO L2
          
          E GET L7
            RET

-------------------------------------------------------------------------------

  *8T3_cede  ; Decrease ref count of block with base addr A1

  L1 REF :: 8T3_BlocksCount
  L2 SET :: 8T3_BlocksInfo
  L3 SET :: 256
  L4 REF :: 8T3_BlocksPool

  L7 GET E

  @1  A1 EQR L4
      DR THN >FOUND
         GET L2 +1
         ADD L4 L3
      L1 REP <1
      L1 GET A1
      A1 INT 0
         JSR :: 8T3_msg :: 'Cede failed for base addr ' 0
         JSR L1 :: 8T3_hex

       E GET L7  
         RET

  @FOUND  E LOD L2    ; Decrement ref count if not 0 yet
          E ELS >2
            GET E -1
          E STO L2
       @2  

          E GET L7
            RET

-------------------------------------------------------------------------------

Display on grand terminal, break line/s after 80

A1 Preserve str8 ptr
A2 Advance str8 byte offs to NL
A3 Preserve max chars

  *8T3_granPrLine

         L1 GET A1
         L2 GET A2    ; Byte offset
         L3 INT 80
         
         L4 INT 0  
    @0      JSR L1 L2 L3 :: 8T3_ldByte
          E GET L3  
            JSR :: 8T3_putC
            GET L2 +1
         L2 GTR A3
         DR THN >FAIL

          E EQL ASC_linefeed
         DR THN >SUCC
          E ELS >FAIL

            GET L4 +1
         L4 EQR L3
         DR ELS <0
         L4 INT 0
            BRA <0
  
  @SUCC   E INT 1
         A2 GET L2
            RET

  @FAIL   E INT 0
         A2 GET L2
            RET

-------------------------------------------------------------------------------

A1 Preserve buffer
A2 Preserve cell count

  *8T3_clearMem

              L3 GET A1
              DR GET A2

               E INT 0
           @2  E STO L3
                 GET L3 +1
              DR REP <2            

                 RET



