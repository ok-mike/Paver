

Scratchpad for notes...



                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   

Write anything here : )                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       


******** 
 
Aerosol 
Copyr. 2015-18 Michael Mangelsdorf (mim@ok-schalter.de) 
 
This file is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
 
More information can be found at: 
 
http://ok-schalter.de/poppy 

********                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
Memory Map:
 
0000-5120dec Bootloader+Hole buffer
5120dec - 6FFF Assembler + Forth System 
7000-EFFF Symbol Table 

ovl.3 F000-FFEF Allocation Buffer (Token buffer size 7EFh) SPACE_PTR 


SD Card structure:
 
Block 0-735 Live image 
(64kw + 15*8kw overlays = 184kw)
(184kw = 368kb = 736 blocks @ 512 bytes)

Block 736- 8T3 source file 
Beach buffers (999 beaches)


F1 set source markers (use twice)
F2 set target markers (use twice)
F3 store current beach
F4 clear current buffer
F5 Insert beach
F6 Delete beach
HOME toggle buffer
END paste clipboard from VM host
PGUP/PGDN load previous/next beach                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
  @BOOT 
  0 OVERLAY ; Reset overlay 
  E INT 0 
  E SOP sop_TXT_pos_set 
  E SET :: FFFFh 
  E SOP sop_TXT_colors 
 
  L1 SOP sop_KEYSW_get ; Skip loading from SD card if switch set 
  L2 INT 1 ; Select switch 0 
     AND L1 L2 
  L1 ELS >GOTCARD ; Branch if switch is one 
     JUMP :: INIT ; Branch no return 
  @GOTCARD 
 
  E INT 42 ; ASCII * 
  E SOP sop_TXT_glyphs 
 
  L1 SET :: 200h ; Image base address (skip bootloader blocks) 
  L4 INT 0      ; First block high order (a 16-bit number!) 
  L2 SET :: 2   ; First block low order, skip bootloader (lower 16 bit) 
  L3 SET :: 254 ; Number of blocks (64k cells including 8K overlay 0) 
  @1 JSR L2 L1 L4 :: SPI_RDBLK 
     GET L2 +1 
  L3 REP <1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               

  1 OVERLAY 
  E INT 65 
  E SOP sop_TXT_glyphs 
  L2 SET :: 256   ; First block low order 
     JSR L2 :: LDOVL 
 
  2 OVERLAY 
  E INT 66 
  E SOP sop_TXT_glyphs 
  L2 SET :: 288   ; First block low order 
     JSR L2 :: LDOVL 
 
  3 OVERLAY 
  E INT 67 
  E SOP sop_TXT_glyphs 
  L2 SET :: 320   ; First block low order 
     JSR L2 :: LDOVL  
 
  4 OVERLAY 
  E INT 68 
  E SOP sop_TXT_glyphs 
  L2 SET :: 352   ; First block low order 
     JSR L2 :: LDOVL  
 
  0 OVERLAY   ; Reset overlay 
  JUMP :: INIT ; Branch no return                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             


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
  L1 INT 12                  ; Wait for this many iterations 
  @1 GET L1 -1               ; Decrement counter 
  L1 THN <1                  ; Do remaining iterations 
     RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
 @SPISDRESET 
  L4 INT 0 
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
   @3 RET                    ; SD card is now in idle mode                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
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

     ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

      ; Continued


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
  L3 SET :: 4000h                    ; Par select SDHC card 
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
 @SPI_WRBYTE                 ; Write 8 bits from A1 out to MOSI line, MSB first  
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
 $SPI_RDBLK                  ; Virtual call if VM 
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

  $SPI_WRBLK                  ; Virtual call if VM 
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

 ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       

    ; Continued

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

******************************************************************************  
End of bootloader

 $STRBUF_L0 ; Hole
 ORG 5120 ; 80*32*2 multi-purpose buffer  (1400h)
 
*******************************************************************************                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                


 @INIT  L1 SET :: FFFFh 
        L1 SOP sop_SEG7_set01 
        L1 SOP sop_SEG7_set23 
        L1 SOP sop_SEG7_set45 
 
        L1 SET :: 000Fh 
        L1 SOP sop_BGCOL_set 
 
           JSR L1 :: CLRSCR ; Set text RAM to blanks, not zeros 
           JSR :: SCROLL_CLI 
        L1 SET :: COLOR_white 
        L1 PER :: TXTCOLOR 
           JSR :: PR_MSG :: STR_MyMSG1 
        L1 SET :: COLOR_green 
        L1 PER :: TXTCOLOR 
 
         E SOP sop_SYSID 
         E EQL 1 
        DR ELS >SKIP 
         E SET :: KBDMAPUS ; Use straight KBDMAP for VM 
         E PER :: KBDMAP 
        @SKIP 

      ; Continue                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
        ; Continue

        4 OVERLAY  
           JSR :: EDCLR 
           JSR :: EDBUFSWAP 
           JSR :: EDCLR 
           JSR :: EDBUFSWAP 
         0 OVERLAY   
 
        L1 SOP sop_KEYSW_get 
        L2 INT 1 ; Switch 0 
           AND L1 L2 
        L1 ELS >1 
 
           ; SD card stuff

        @1 JSR :: FMC_ABORT   ; Call Forth interpreter 


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
 @DPBUF 0 0 0 0 0 0 0 0 0 

 @KBDMAP KBDMAPDE 
 @TXTPOS_BASE 4048 ; 4096 - 48 

 0 0 0 0 0

 @TXTPOS 4048 ; Points to current text buffer cell 
 @TXTCOLOR COLOR_green                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
Output character E (cooked) into text buffer at TXTPOS, advance by 1 
 
 $PUTC   L1 SET :: TXTPOS 
         L2 LOD L1 
         L3 GET E 
         L3 SOP sop_VM_putc ; Hen if present sets E to 0 
         L3 ELS >2 
 
         L3 EQL 10 
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
 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               

 $PRBYTSTR ; Address in A1 
  L3 GET A1 
     BRA >CPY 
 
 $PR_MSG ; Prints a zero terminated byte string 
   3 OVERLAY 
  L3 CALLER 
     @CPY L1 LOD L3 
       L1 ELS >A ; If NULL 
       L2 GET L1 
          SHR L1 8 ; L1 is first char 
       DR SET :: FFh 
          AND L2 DR ; L2 is second char 
 
       L1 EQL 3 
       DR THN >3 ; If ASC End of Text 
        E GET L1 
          JSR :: PUTC 
 
       L2 EQL 3 
       DR THN >3 ; If ASC End of Text 
        E GET L2 
          JSR :: PUTC 
 
     @3   GET L3 +1 
          BRA <CPY 
     @A 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
 $CLEARLIN L6 SET :: 3968   ; From 
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
 
 
 
 $CLRSCR L4 INT ASC_space 
         L3 SET :: 4096   ; Should use sop_TXT_base 
 
    @CPY L3 SOP sop_TXT_pos_set 
         L4 SOP sop_TXT_glyphs 
         A1 SOP sop_TXT_colors 
         L3 REP <CPY 
         RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     

 $SCROLL_CLI   L1 SET :: 80           ; First column first line (copy to) 
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

 @INS L6 GET A2             ; A1 current pos, A2 current max pos 
      L5 GET L6 +1 
 
 @CPY L6 SOP sop_TXT_pos_set 
      L2 SOP sop_TXT_glyphg  ; Read character 
      L3 SOP sop_TXT_colorg 
 
      L5 SOP sop_TXT_pos_set 
      L2 SOP sop_TXT_glyphs  ; Write character 
      L3 SOP sop_TXT_colors 
 
         GET L5 -1 
         GET L6 -1 
      A1 LTR L6 
      DR THN <CPY 
 
         GET A2 +1          ; New rightmost character 
      A1 SOP sop_TXT_pos_set    ; Restore original pos 
 
 @DONE   RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  

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

 $GETLINE   ; A1 return str size 
 L6 SET :: TXTCOLOR 
    LOD L6 
 L1 REF :: TXTPOS_BASE 
 L2 REF :: KBDMAP 
 L5 REF :: TXTPOS_BASE ; Current max pos 
    GET L5 +1 
    JSR :: CLEARLIN 
 L1 SOP sop_TXT_curset 
    ZOP zop_KB_reset 
 
  @GETC IDLE                ; Implement F4 key: "eat" scroll command lines DOWN 
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

    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
    ; Continued

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

  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

       ; Continued

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


     ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
   ; Continued

 $CMD_PUTSZ      ; A1 is ptr to zero terminated string 
 
    @CPY L2 LOD A1 
          E GET L2 
            JSR :: PUTC 
            GET A1 +1 
         L2 THN <CPY 
 RET 
 
 
 
 $CMD_PUTCS      ; A1 is ptr to counted string 
 L1 LOD A1       ; First cell is string length 
    GET A1 +1    ; Skip strlen 
 
     @CPY E LOD A1 
            JSR :: PUTC 
            GET A1 +1 
         L1 REP <CPY 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           

  $CMD_NCHAR      ; A1 is string ptr, A2 is string length 
 
     @CPY E LOD A1 
            JSR :: PUTC 
            GET A1 +1 
         A2 REP <CPY 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   

Use this function for command line input as it communicates well with hen. 
 
 $CMD_GETL       ; A1 is ptr to string buffer, at least 64 words 
 
    ZOP zop_TXT_SHOWCUR 
 L6 GET A1 
 L6 SOP sop_VM_gets  ; Hen if present sets L6 to 0 
 L6 ELS >DONE 
    JSR L5 :: GETLINE  ; Sets L5 to string size 
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
         JSR :: SCROLL_CLI 
 
 @DONE 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

Advance a given string pointer to the next line break, then skip any number of 
consecutive line breaks (empty lines), too. Do not move past end of string. 
Returns a flag indicating whether null terminator was reached. 
 
A1 IN Pointer to string, update       THIS FUNCTION NOT USED, TEST 
 
    @SKIPCOMMENT 
    L6 LOD A1 
       ELS >NULL 
       GET A1 +1 
 
        L6 EQL ASC_linefeed      ; Unix \n 
        DR ELS <SKIPCOMMENT 
 
    @1 
    L6 LOD A1                    ; Now skip successive line breaks 
       ELS >NULL 
       GET A1 +1 
 
        L6 EQL SET :: ASC_linefeed 
        DR THN <1 
           E INT 0 
              ELS >2 
 
    @NULL E INT 1 
    @2    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 


Advance a given string pointer to the next non-space character. Line breaks 
are considered non-space. 
 
A1 IN Pointer to string, update 
 
    $SKIPSPACE 
    L6 LOD A1 
       GET A1 +1 
 
        L6 EQL ASC_space 
        DR THN <SKIPSPACE 
 
           L6 EQL ASC_tab 
           DR THN <SKIPSPACE 
 
              GET A1 -1 
 
         RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
A1 IN Pointer to string 1, keep 
A2 IN Pointer to string 2, keep 
A3 IN Termination character, keep 
 
E OUT 1:strings are equal / 0:strings are not equal 
 
METHOD: Traverse string 1 and compare to string 2 character by character until 
either the characters differ (0) or the termination character is found (1). 
 
    $STRCMP 
    L1 GET A1     ; Pointer to string 1 
    L2 GET A2     ; Pointer to string 2 
    L3 INT 1    ; Assume success 
 
    @1 L6 LOD L1 
       E LOD L2 
          GET L1 +1 
          GET L2 +1 
 
          L4 SUB L6 E     ; Compare both characters 
             ELS >SUCC 
             L3 INT 0   ; Else flag failure 
    @SUCC 
    SUB L6 A3     ; Compare to termination character 
    ELS >TERM   ; If 0, since both characters are equal, both are terminators 
    THN <1      ; Else do next character 
 
    @TERM 
    E GET L3 
      RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        


Shorten a string by shifting characters left, overwriting the beginning of 
the string so that the total length becomes A2 characters. 
 
A1 String base address pointer, keep          ; SHOULD GET A START OFFSET 
A2 Requested string length, alter             ; TO BE USED JSR 0000.0000b 
 
 @TRIMLEFT 
 L6 GET A1 
 JSR L6 L1        ; String length in L1 now 
 STRLEN 
 SUB L1 A2        ; Set L1 to number of character shifts 
 L2 ADD L6 L1     ; Set L2 to first character pos to keep 
 @1 E LOD L2 
    E STO L6 
    GET L2 +1 
    GET L6 +1 
 L1 REP <1 
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             

Shorten a 0 terminated string by removing the first characters on the left. 
 
A1 String base address pointer 
A2 Number of characters to remove 
 
 @CUTLEFT 
 L1 GET A1 
 L2 ADD A1 A2 
 @1 E LOD L2 
    E STO L1 
       GET L2 +1 
       GET L1 +1 
    E THN <1 
      RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            

Convert register value into number string. 
 
A1 Number to convert, keep 
A2 Pointer to divisor table, alter 
A3 Output string base address pointer, update 
A4 Padding character - if 0, no padding, bit 7 is sign flag, alter 
 
 $NUMBERSTR 
 L6 SET :: 7FFFh 
 L3 AND A4 L6        ; L3 is the padding character (stripped off sign flag) 
 L6 GET A1 
 L1 LOD A2           ; Get first divisor for later 
 
 A1 THN >0           ; Branch if number non-zero 
 L5 SET :: ASC_0     ; Simply store ASCII zero and return 
 L5 STO A3 
    GET A3 +1 
    RET

   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             

    ; Continued

 @0 
 DR SET :: 8000h 
  E AND DR A4 
 A4 INT 0          ; A4 is now a condition: no leading non-zero digit yet 
  E ELS >1           ; If MSB not set, output as unsigned number 
  E AND DR L6         ; Test sign bit of number to output 
  E ELS >1           ; If set, output a minus sign and negate the number 
 DR SET :: FFFFh 
 L6 EOR DR L6 
    GET L6 +1 
    L7 SET :: ASC_minus 
    L7 STO A3 
       GET A3 +1 
 
 @1    JSR L6 L1 L5 L7 :: DIVMOD 
 
       L6 GET L7     ; Remainder becomes new number to convert 
       L5 THN >2     ; Store quotient as digit in string if non-0 
       A4 THN >2     ; Output anything after leading non-zero 
       L3 ELS >4     ; or skip this digit if no padding requested 
       L5 GET L3     ; Output padding char instead of digit 
          BRA >3     ; Next digit


    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
   ; Continued

 @2    A4 INT 1    ; Leading non-zero digit present 
       L3 INT 0    ; Disable padding after first significant digit 
 
          JSR L5 :: DIGIT2ASC 
 
 @3    L5 STO A3 
          GET A3 +1  ; Advance string pointer for next digit 
 @4       GET A2 +1  ; Advance to next divisor 
       L1 LOD A2 
       L1 THN <1     ; If divisor was not 0, repeat 
 
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 

Parse a 0 terminated string representation of a number including optional 
minus sign and base suffix (b or h) into a number using STRTONUM. 
 
A1 IN Source address, leave 
A2 IN Number result 
 
E OUT 0: Number conversion successful / 1: Conversion error 
 
 $PARSENUM 
 L3 SET :: STRBUF_MUD 
 L6 GET A1 
 L1 SET :: ASC_linefeed    ; Assume decimal number 
 
 L5 GET L3 
 E INT 0 
    JSR L6 L5 :: STRCPY 
    GET L5 -1

   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
     ; Continued

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
    SUB E L5 
 L5 GET L3 
 E THN >2B 
    GET L5 1      ; SKIP plus sign 
     BRA >4

   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            

   ; Continued

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
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    


Convert a null terminated string (digits + _ only) to a number using ASCTONUM. 
 
A1 IN Source address, leave 
A2 IN Number base, leave 
A3 IN Number result 
 
E OUT 0: Successful conversion / 1: Conversion error 
 
 $STRTONUM 
 L6 GET A1 
 L1 GET A2 
 A3 INT 0 
 L2 INT 1                   ; Initial multiplier 
 
       JSR L6 L3 :: STRLEN 
       ADD L6 L3              ; L6 to END of string (least significant digit) 
 
    @1 GET L6 -1 
    L4 LOD L6 
    L4 EQU ASC_underscore     ; Ignore any underscores 
    DR THN >A 
 
   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            

   ; Continued

      JSR L4 L1 L4 :: ASCTONUM 
    DR INT 1 
     E ELS >2 
 
       JSR L2 L4 L4 L5 :: UMUL   ; Multiply current digit by multiplier 
       ADD A3 L4                 ; Add to result 
       JSR L2 L1 L2 L5 :: UMUL   ; Multiply current multiplier by base 
 
 @A L3 REP <1 
    DR INT 0 
  @2 E GET DR 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     

This function turns an ASCII representation of a digit into a number value, 
for example ASCII 49 = '1' into the number 1. 
ASCII character in A1, number base in A2. Return number in A3. 
If character valid for number base E is 0 else 1. 
 
E OUT 0: Successful conversion / 1: Conversion error 
 
     $ASCTONUM 
 
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
Divide two unsigned numbers. Dividend in A1, divisor in A2. 
Return quotient in A3, remainder in A4. 
 
 $DIVMOD  L6 GET A1      ; Copy of dividend 
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

Divide 32-bit unsigned by 32 bit unsigned. 
Dividend in A1 (high order) A2, divisor in A3 (high order) A4. 
Return quotient in A1 (high order) A2. 
Return remainder in A3 (high order) A4. 
 
 $DIVMOD32 
 
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

   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      

           ; Continued

   @W    L6 SUB A1 A3   ; Subtract divisor from dividend (high) 
           E IOR A1 A3 
           E ELS >U      ; Skip if dividend and divisor (high) zero 
          DR ELS >3      ; Branch if carry clear (divisor greater than div'd) 
    @U    L7 SUB A2 A4   ; Subtract divisor from dividend (low) 
          DR ELS >3      ; Branch if carry clear (divisor greater than div'd) 
    @V    A1 GET L6      ; Accept subtraction (high) 
          A2 GET L7      ; Accept subtraction (low) 
             GET L2 +1   ; Set quotient LSB 
 
    @3    DR INT 1       ; LSB mask 
             AND DR A3    ; Check if shift carry 
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

Multiply two unsigned numbers A1 and A2. Return low order 
result in A3, high order in A4. 
 
 $UMUL  L6 GET A1       ; Copy of multiplier, leave A1 
        L1 GET A2       ; Copy of multiplicand, leave A2 
                        ; Don't use A1 or A2 as they may coincide with A3 or A4 
        L4 INT 1 
        L5 SET :: 8000h 
 
        A3 GET L6       ; Initialise low order result with multiplier 
        A4 INT 0      ; Initialise A4 to 0, will become high order result 
        L2 INT 16     ; Repeat 16 times = 16 bits 
 
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
Return size of 0 terminated string. 
 
A1 Source address, leave 
A2 String size result 
 
 $STRLEN 
 L6 GET A1 
 A2 INT 0 
 @1 L7 LOD L6 
    ELS >2 
    GET L6 1 
    GET A2 1 
        BRA <1 
 @2 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
 $ORDER ; Bring A1 A2 to ascending order
     A2 GTR A1
     DR THN >QUIT
     DR GET A1
     A1 GET A2
     A2 GET DR
 @QUIT
 RET


 $CPFROMTO ; Copy str at addr A1 to A2 into buffer at A3
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

 $CPNONULL ; Copy str at A1 to buffer at A2, exclude final NULL
    L2 GET A2
 @1 A1 LODS
    DR ELS >QUIT
    L2 STOS
       BRA <1
 @QUIT
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
Copy terminated string within RAM, terminator symbol in E, do not go past 
end of string. Return flag in E whether null character found. 
A1 Src addr, A2 Dest addr 
 
 $STRCPY   L1 INT 1    ; Assume NULL found 
 
      @A   A1 LODS 
           A2 STOS 
           DR ELS >B 
           DR EQR E 
           DR ELS <A 
 
           L1 INT 0    ; Reset NULL flag 
      @B      GET A1 -1  ; Undo pre-increment 
              GET A2 -1 
            E GET L1 
              RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
Copy a string from a card block to RAM. 
Copy until character in E or NULL is found. 
Terminate target string with NULL. 
Return flag in E wether NULL character found. 
 
E Termination character (overwrite) 
A1 Source block number low order (update) 
A2 Char pos within block (update) 
A3 Target str ptr (update) 
A4 Source block number high order (update) 
 
 @BLKSTR    L1 GET A1 
            L2 GET A2 
            L3 SET :: 256 
            L7 GET E 
            ; TODO A1/A4 does not carry 
 
      @0    L4 SET :: 6000h               ; Block buffer 
            L6 GET L4 
            L5 GET A4                     ; Blk num high order 
               JSR L1 L4 L5 :: SPI_RDBLK  ; Blk num low order, DBuf 

   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

     ; Continued

      @1    L5 ADD L6 L2                  ; L5 now ptr to src str 
            DR LOD L5 
            DR STO A3 
            L5 GET DR 
               GET A3 +1 
               GET L2 +1 
            L2 EQR L3 
            DR ELS >X 
            L2 INT 0 
               GET L1 +1 
      @X     E INT 1                    ; Prepare NULL flag 
            L5 ELS >2                     ; Branch if NULL 
             E INT 0 
            L5 EQR L7 
            DR THN >2                     ; Branch if terminator 
            L2 ELS <0 
               BRA <1 
 @2 
 GET A3 -1 
 A1 GET L1 
 A2 GET L2 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
Write a RAM region to SD card. 
 
A1 From blk number low order 
A2 Start at mem addr 
A3 Number of words 
A4 From blk number high 
 
 @STRBLK    L1 GET A1 
            L2 GET A2 
            L3 SET :: 256 
            L4 GET A4 
            ; TODO A1/A4 does not carry 
 
       @1      SUB A3 L3 
            DR ELS >2 
               JSR L1 L2 L4 :: SPI_WRBLK    ; Blk num, DBuf, blk num high 
               GET L1 +1 
                 BRA <1 
 
       @2      JSR L1 L2 L4 :: SPI_WRBLK    ; Blk num, DBuf, blk num high 
 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
Convert a wide character string to byte string, network order 
A1 ptr to src, A2 ptr to target 
 
 $TOBSTR 
 
    L2 INT 3     ; ASCII end-text 
 @1 
    A1 LODS 
    DR BYTE      ; Low order byte into D 
    L1 SHL DR 8 
       IOR L1 L2 ; Provide str terminator for NULL case 
    DR ELS >2    ; NULL found 
    A1 LODS 
    DR BYTE 
       IOR DR L1 
    DR ELS >2 
    A2 STOS 
       BRA <1 
  @2 DR INT 0 
    A2 STOS      ; String terminator 
       RET 
 
Convert a byte string to wide character string, network order 
A1 ptr to src, A2 ptr to target 
 
 @TOWSTR 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              

 $POW2DESC 32768 16384 8192 4096 2048 1024 512 256 128 64 32 16 8 4 2 1 0 
 
 $POW10DESC 10000 1000 100 10 1 0 
 
 $POW16DESC 4096 256 16 1 0 
 
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

 $BEACHBASE 736   ; First block of beach region
 $SYSBASE   738   ; First block of system source code
 $SYMTAB    7000h ; Addr of beginning of symbol table = 112 blocks * 256
 $SYMINSPOS 7000h ; Addr of end of symbol table

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
 ; ID values mapped to ZOP instruction 
 
 DEF zop_INIT          0 ; These switch on L/R1 (R2_LOR = 0) 
 DEF zop_NEXT          1 
 DEF zop_SWAP          2 
 DEF zop_TXT_SHOWCUR   3 
 DEF zop_TXT_HIDECUR   4 
 DEF zop_GFX_over      5 
 DEF zop_STALL         6 
 DEF zop_RET           7 
 DEF zop_THREAD        8 
 DEF zop_DOCOL         9 
 DEF zop_JUMP          10 
 DEF zop_IP_COND       11 
 DEF zop_KB_reset      12 
 DEF zop_TXT_flip      13 
 DEF zop_GFX_flip      14 
 DEF zop_VM_IDLE       15 
 DEF zop_SYNC          17 
 DEF zop_NOP           20 
 DEF zop_GOTKEY        21                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
 DEF dop_SIG      0 ; These switch on R2_LOR 
 DEF dop_REF      1 
 DEF dop_GFX_LD   2 
 DEF dop_GFX_ST   3 
 DEF dop_BRA      4 
 DEF dop_PEEK     5 
 DEF dop_PAR      6 
 DEF dop_PULL     7 
 DEF dop_GFX_THRU 8 
 DEF dop_FRLD     9 
 DEF dop_FRST     10                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
 DEF sop_VM_gets       0 
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
 DEF sop_SET           59  ; These all switch on R2_LOR/R1 
 DEF sop_IRQ_vec       60 
 DEF sop_IP_POP        61 
 DEF sop_W_GET         62 
 DEF sop_POP           63 
 DEF sop_PUSH          64 
 DEF sop_CALLER        65 
 DEF sop_LODS          66 
 DEF sop_STOS          67 
 DEF sop_VIA           68 
 DEF sop_ONEHOT        69 
 DEF sop_TXT_base      70 
 DEF sop_GFX_base      71 
 DEF sop_EXEC          72 
 DEF sop_PER           73 
 DEF sop_IP_GET        75 
 DEF sop_IP_SET        76 
 DEF sop_NYBL          77 
 DEF sop_LIT           78 
 DEF sop_DROP          79 
 DEF sop_PICK          80 
 DEF sop_GO            81 
 DEF sop_PC_GET        82 
 DEF sop_BYTE          83 
 DEF sop_SERVICE       84 
 DEF sop_MSB           85 
 DEF sop_LSB           86 
 DEF sop_NOT           87 
 DEF sop_NEG           88 
 DEF sop_OVERLAY       90                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
 DEF sop_BLANKING      91 
 DEF sop_IRQ_self      92 
 DEF sop_GFX_H         93 ; Set H starting pos 
 DEF sop_GFX_V         94 
 DEF sop_cycles_lo     95 
 DEF sop_cycles_hi     96 
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
 DEF sop_PERIOD        114                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    


 DEF sop_SYSID         115 
 DEF sop_GPIO_rd_a     118 
 DEF sop_GPIO_rd_b     119 
 DEF sop_GPIO_rd_c     120 
 DEF sop_GPIO_rd_d     121 
 DEF sop_GPIO_wr_c     122 
 DEF sop_GPIO_wr_d     123 
 DEF sop_SEG7_set01    124 
 DEF sop_SEG7_set23    125 
 DEF sop_SEG7_set45    126                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
 ; Hardwired instructions for FORTH subsystem 
 
 DEF instr_NEXT  0001h 
 DEF instr_DOCOL 0009h 
 DEF instr_STALL 0006h 
 
 ; Color definitions 
 
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
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
 DEF TYS_symsize     22 
 DEF TYS_tokensize   64 
 DEF TYS_buffersize  7EFh                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
 @CMD_DICT 
 
 >CMD_PATTERNS ; Associated pattern table 
 
 9 1 1 1h "test"      0 0 0 0 0 0 0 0 
 9 2 1 1h "sasm"      0 0 0 0 0 0 0 0 
 9 3 1 1h "import"        0 0 0 0 0 0 
 9 4 1 1h "export"        0 0 0 0 0 0 
 9 5 1 1h "te"    0 0 0 0 0 0 0 0 0 0 
 
 0 ; End marker 
 
Command patterns (each of size 7)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
 @CMD_PATTERNS 
 
;Type Subtype Charge (Group Index), 0 = ANY, Group<8 match any index 
 
;TOKTYPREG=1 TOKTYPOPC=2 TOKTYPNUM=3 TOKTYPSTR=4 TOKTYPWRD=5 
;TOKTYPLAB=6 TOKTYPREF=7 8=Directives 
 
 1119h 0000h 0000h 0000h 0000h 0000h  1 >H_CMD_TEST 
 1129h 0000h 0000h 0000h 0000h 0000h  2 >H_CMD_SASM 
 1139h 0000h 0000h 0000h 0000h 0000h  3 >H_CMD_IMPORT 
 1149h 0000h 0000h 0000h 0000h 0000h  4 >H_CMD_EXPORT 
 1159h 0203h 0000h 0000h 0000h 0000h  5 >H_CMD_EDIT 
 
 0 ; End marker                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
 @1  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0  0   ; 18 word buffer 
 
 $PRHEX ; Print number in E 
 
 L6 GET E 
 L1 SET :: POW16DESC 
 L2 SET :: <1 
 L3 SET :: 30h ; No padding, sign bit 7 
    JSR L6 L1 L2 L3 :: NUMBERSTR 
 L3 INT 0 
 L3 STO L2 
 L2 SET :: <1 
    JSR L2 :: CMD_PUTSZ 
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
 @1  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0  0   ; 18 word buffer 
 
 $PRNUM ; Print number in E 
 
 L6 GET E 
 L1 SET :: POW10DESC 
 L2 SET :: <1 
 L3 SET :: 8000h ; No padding, sign bit 7 
    JSR L6 L1 L2 L3 :: NUMBERSTR 
 L3 INT 0 
 L3 STO L2 
 L2 SET :: <1 
    JSR L2 :: CMD_PUTSZ 
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
The following is a handler function for a console command. 
Export the file 8T3.asm from card. 
 
    @1 "Pattern matched: 'export' " 0 
    @2 "8T3.asm" 0 
    @H_CMD_EXPORT 
    L6 SET :: TYS_tokensize 
 
    L5 SET :: <1 
       JSR L5 :: CMD_PUTSZ 
       JSR :: SCROLL_CLI 
 
               L1 SET :: <2 
               L1 SOP sop_VM_fnew 
               L2 SET :: 736 ; First block of source region on card 
               L7 INT 0       ; First block high order  


     ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      

     ; Continued

      @NXTBLK  L4 REF :: FMC_BUFFERS 
                  JSR L2 L4 L7 :: SPI_RDBLK 
               L5 SET :: 256 ; Buffer size in words 
               L4 REF :: FMC_BUFFERS 
            @3 L4 LODS 
               DR ELS >4 
               DR SOP sop_VM_fwrite 
               L5 REP <3 
                  GET L2 +1 
                  BRA <NXTBLK 
 
            @4 DR SOP sop_VM_fwrite ; Write NULL 
               L1 SOP sop_VM_fgetpos 
               L1 SOP sop_VM_fclose 
 
       ADD A1 L6      ; Advance by 1 token 
     E INT 1          ; Return value 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
The following is a handler function for a console command. 
Import the file 8T3.asm to a hard-wired block on card. 
 
    @1 "Pattern matched: 'import' " 0 
    @2 "8T3.asm" 0 
    @H_CMD_IMPORT 
    L6 SET :: TYS_tokensize 
 
    L5 SET :: <1 
       JSR L5 :: CMD_PUTSZ 
       JSR :: SCROLL_CLI 
 
               L1 SET :: <2 
               L1 SOP sop_VM_fold 
               L2 SET :: 1024 ; First block of target region on card 
               L7 INT 0       ; First block high order  


    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              

     ; Continued


     @NXTBLK  L4 REF :: FMC_BUFFERS 
               L5 SET :: 256 ; Buffer size in words 
            @3  E SOP sop_VM_fread ; Fill block buffer 
               DR EQL 1 
               DR ELS >4 ; End of file 
                E STO L4 
                  GET L4 +1 
               L5 REP <3 
               L4 REF :: FMC_BUFFERS 
                  JSR L2 L4 L7 :: SPI_WRBLK    ; Blk num, DBuf, blk num high 
                  GET L2 +1 
                  BRA <NXTBLK 
 
            @4  E STO L4 ; Write NULL 
               L4 REF :: FMC_BUFFERS 
                  JSR L2 L4 L7 :: SPI_WRBLK    ; Blk num, DBuf, blk num high 
 
               L1 SOP sop_VM_flen 
               L1 SOP sop_VM_fclose 
 
       ADD A1 L6      ; Advance by 1 token 
     E INT 1          ; Return value 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
The following is a handler function for a console command. 
 
    @1 "Pattern matched: 'sasm'" 0 
    @H_CMD_SASM 
    L6 SET :: TYS_tokensize 
 
    L5 SET :: <1 
       JSR L5 :: CMD_PUTSZ 
       JSR :: SCROLL_CLI 
 
       ZOP zop_TXT_HIDECUR 
     0 OVERLAY                 ; Force correct OVERLAY bank for ASM subsys    
     L1 INT 0                  ; Assemble from address 0
     L2 REF :: SYSBASE         ; Assemble system source code from this block 
       JSR L1 L1 L2 L1 :: SASM
       ZOP zop_TXT_SHOWCUR 
 
       ADD A1 L6      ; Advance by 1 token 
     E INT 1          ; Return value 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
The following is a test handler function for a console command. 
 
    @1 "Pattern matched: 'test'" 0 
    @H_CMD_TEST 
    L6 SET :: TYS_tokensize 
 
    L5 SET :: <1 
       JSR L5 :: CMD_PUTSZ 
       JSR :: SCROLL_CLI 
       JSR L7 :: CLEARLIN 

 
       L1 SET :: 0h
       L2 SET :: OOLONG
       L7 GET L2
       L3 SET :: 2490 ; Beach 249
       L4 REF :: BEACHBASE
          ADD L3 L4
       L4 INT 1 ; ASM mode memory
          JSR L1 L2 L3 L4 :: SASM
          JSR :: OOLONG
 
       ADD A1 L6      ; Advance by 1 token 
     E INT 1          ; Return value 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
The following is a handler function for a console command. 
 
    @1 "Pattern matched: 'te n'" 0 
    @EDITING 0 
    @H_CMD_EDIT 
    L6 SET :: TYS_tokensize 

    L1 GET A1
    L2 INT 1 
    L3 INT 3 
       JSR L1 L2 L3 :: TYS_INFO    ; E has beach number 
       ADD A1 L6 ; Skip beach number argument
    L7 GET E

    L5 SET :: <1 
       JSR L5 :: CMD_PUTSZ 
       JSR :: SCROLL_CLI 
       JSR :: CLEARLIN 
 
     ; Register and enable an interrupt handler for keyboard events 
     6 IRQ-VEC :: IRQ_ED_HANDLER ; Register handler 
    DR INT 0 
     E SET :: 128 ; bit 7 
     2 SERVICE ; Enable KB intr 
 
     ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
     ; Continued

    ; Loop until ESC key pressed (irq handler sets EDITING to 0) 
     ; All keys are handled by kb interrupt handler 
     4 OVERLAY  
     L7 PER :: EDBEACH
        JSR :: EDLDBEACH
        JSR :: EDUPDATE 
      E INT 1 
      E PER :: EDITING 
        ZOP zop_TXT_SHOWCUR 
     
     @WAITESC ZOP zop_VM_IDLE ; without this line must press ESC twice, why
            E REF :: EDITING 
            E THN <WAITESC 
     
       ZOP zop_TXT_HIDECUR 
 
       ADD A1 L6      ; Advance by 1 token 
     E INT 1          ; Return value 
       RET 

    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
 ; Continued
 
   @IRQ_ED_HANDLER 
        L1 REF :: KBDMAP          
        L2 SOP sop_KB_keyc 
           ZOP zop_GOTKEY 
        L3 ADD L1 L2 ; Look up keycode in KBDMAP 
           LOD L3    ; Keycap char into L3 
        L3 EQL 27 ; Escape key 
        DR THN >QUITED 
         4 OVERLAY ; Switch to 8K Editor overlay 
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
 @FMC_BUFFERS   6000h     ; Base of buffer region (1k each) 
 @EBUF     6000h ; Edit buffer ptr 

 @STRBUF_MUD 0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
             0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0 
             0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
             0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0

   @FMC_ABORT 
               L4 SET :: STRBUF_L0 
                  JSR L4 :: CMD_GETL  
               L4 SET :: CMD_DICT 
                  JSR L4 L5 L4 :: 8T3_PARSE ; Handler function result code E 
                E EQL 7Fh 
                  JUMP :: FMC_ABORT

 $OOLONG                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
The rest of the source file shares address space E000h - FFFFh. 
The high-order four bits 12-15 of the current frame key select 
1 of 16 'banks' or 'overlays' that are mapped into E000h to FFFFh. 
Using the <4-bit-index> OVERLAY instruction, one of the banks is 
selected and mapped. The selected overlay is saved/restored together 
with the current frame key during JSR/RET. 



=== OVERLAY BANK 0 / ASSEMBLER ==============================================
 
  ORG E000h ; Pad to OVERLAY base address 0 (0E000h) 
 
The first bank contains a native, self-hosting assembler and pattern matcher. 
The following batch of functions do 2-pass assembly, symbol table management 
and pattern matching. 
Each assembly pattern writes object code by means of the WROBJ function into 
a block buffer. If the buffer is full, it is flushed to the card image. 
In this way, the assembler pass can generate more than 64k object code 
to include overlays. 
 
 @ASMMODE    0
 @ASMPASS    1
 @ASMLINE    1

 @SPACE_PTR  FFEFh ; Allocation stack pointer used by CLAIM/CEDE


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
 @SASM   L1 GET A1           ; Unneeded was C000h object code buffer
         L3 GET A2           ; Start at offset 0 
         L4 GET A3           ; First source block 
         DR GET A4           ; Assembler mode (0=SD card / 1=memory)
         DR PER :: ASMMODE

         L7 INT 0            ; Start at first char in block
 
            JSR L4 L7 L1 L3 :: ASM_BLKASM 
 
          E INT 10 
            JSR :: PUTC ; Newline 
          E GET L3 
            SUB E A2
            JSR :: PRHEX 
            JSR :: PR_MSG :: STR_ObjCSize ; ... words generated  

            JSR :: PR_MSG :: STR_SymMax ; Symtab at ... 
          E REF :: SYMINSPOS
         L7 GET E
            JSR :: PRHEX 
          E INT 10 
            JSR :: PUTC 


    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
      ; Continued

         L1 REF :: ASMMODE
         L1 THN >NOFLUSH ; Don't flush if memory target
          
         L1 REF :: BLKN 
         L2 INT 0 
         L3 REF :: FMC_BUFFERS 
          E SET :: 1024 
            ADD L3 E 
            JSR L1 L3 L2 :: SPI_WRBLK ; Flush object code buffer 
 @NOFLUSH
            JSR :: PR_MSG :: STR_CullTo
         L6 GET L7
            JSR L7 :: STCULL  ; Cull symbol table (leave only $ labels)
         L7 PER :: SYMINSPOS  ; Update symbol table size           
          E REF :: SYMTAB
         L7 STO E +3          ; Patch dummy entry with table size

      @1 L7 EQR L6            ; Loop zero out culled portion           
         DR THN >2
         DR INT 0      
         L7 STOS
            BRA <1
 
     ; Continue                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
     ; Continue

      @2    JSR :: STPERSIST ; Graft symbol table into card image
          E REF :: SYMINSPOS
            JSR :: PRHEX
          E INT 10
            JSR :: PUTC

            RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
    @STCULL                    ; A1 symbol table max addr
        L1 REF :: SYMTAB       ; Beginning of symbol table
        L3 SET :: TYS_symsize

     @1 L1 EQR A1              ; Check if last symbol
        DR THN >QUIT       
        L2 LOD L1 +0           ; Check symbol type   
        L2 ELS >QUIT           ; End of table 
        L2 EQL 6               ; Labels (@ and $)  
        DR ELS >CULL           ; Reject other types
        L2 LOD L1 +1           ; Check subtype
        L2 ELS >CULL           ; Reject @ labels 
     @KEEP ADD L1 L3
           BRA <1           
     @QUIT RET  
  
  @CULL L4 GET L1
        L5 ADD L4 L3           ; Remove this entry by shifting into it
        L7 GET A1
           SUB A1 L3
   @CUT L5 EQR L7
        DR THN <1
        L5 LODS
        L4 STOS
           BRA <CUT
     
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
 @STPERSIST ; Copy symbol table into card image

        L1 REF :: SYMTAB
        L2 REF :: SYMINSPOS

        L3 SHR L1 8 ; Divide by 256 = block index on card
        L4 SUB L2 L1
           SHR L4 8
           GET L4 +1 ; Symtab size in blocks

        DR INT 0 ; High order block index (16-bit)        
     @1    JSR L3 L1 DR :: SPI_WRBLK
           GET L3 +1
        L4 REP <1 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
    @RESETASM ; Reset state per pass 
    
             E REF :: ASMMODE
             E THN >MEM

            L6 REF :: SYMTAB
            L7 GET L6 
             E SET :: TYS_symsize  ; Create dummy entry persistent label
            DR INT 0
         @1 L6 STOS                ; Loop zero out dummy entry
             E REP <1
            L6 PER :: SYMINSPOS    ; Reset insert index in symbol table
             E INT 6h
             E STO L7 +0           ; Make it a fake $ label
             E INT 1               ; Index value will receive
             E STO L7 +1           ; final table size
               BRA >DONE
     
       @MEM  E REF :: SYMTAB
               LOD E +3         ; Persistent symbol table size  
             E PER :: SYMINSPOS ; Patch back the size
       
      @DONE L1 SET :: 0 
            L1 PER :: BLKN ; First object code block on card 
            L1 INT 0 
            L1 PER :: >BUFPOS ; Set buffer index to 0
               
               RET
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
This is the highest level function of the assembler, it assembles the source 
text twice. The second pass is necessary to resolve forward references. 
The text is copied and assembled line by line. 
 
A1 IN String to assemble, first block number 
A2 IN String to assemble, block offset 
A3 IN Base 
A4 IN Effective 
 
          ; Following are state variables for the assembler 
    0     ; Two-state byte counter for dive instruction 
    0000h ; Current dive instruction 
    0     ; Previous LHS, accessed by handler functions 
 
    @ASM_BLKASM 
   DR INT 1
   DR PER :: ASMPASS 

  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
    ; Continued

    @PASS    E REF :: ASMPASS 
               JSR :: PRNUM 
             E INT 32 
               JSR :: PUTC 
 
            L1 GET A1 ; Source text low block number
            L2 GET A2 ; Char pos within this block 
            L3 GET A3 ; Obj code base address
            L4 GET A4 ; Current obj code address
 
            E INT 1
            E PER :: ASMLINE   
            JSR :: RESETASM

     ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
    ; Continued
 
    @LINE   L5 SET :: STRBUF_L0    ; Copy 1 line of source text into buffer 
            L6 INT 0               ; Block number high order 
             E SET :: ASC_linefeed ; Separator
               JSR L1 L2 L5 L6 :: BLKSTR  ; lowblk, charpos, buf, highblk
            L6 INT 0 
            L6 STO L5              ; Terminate string by 0 
            L5 GET E               ; Save NULL flag result 
             E SET :: STRBUF_L0    ; Source lines must begin space char 
               LOD E 
             E EQL ASC_space 
            DR ELS >1 
            L6 SET :: ASM_TOKS ; Structure containing pattern handler ptrs
               JSR L3 L4 L6 :: 8T3_PARSE 
             E REF :: ASMLINE
               GET E +1
             E PER :: ASMLINE
        @1  L5 ELS <LINE 

     E REF :: ASMPASS
       GET E +1
     E PER :: ASMPASS
     E EQL 3
    DR ELS <PASS 

     @2 
    A3 GET L3 
    A4 GET L4 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
This function is called by pattern handler functions for each cell of
object code generated. Depending on mode, write object code cell to
memory target address or into SD card buffer.

  @WRCODE ; A1 Addr, A2 Obj code

         E REF :: ASMPASS
         E EQL 1
        DR THN >SKIP ; No code gen during first pass

        L1 REF :: ASMMODE
        L1 THN >MEM 
  @CARD L2 GET A2
           JSR L2 :: WROBJ
           RET
  @MEM  A2 STO A1

  @SKIP    RET



                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

Write out a data value to a block buffer. Flush the buffer if full. 
Data value in A1. 
 
    @BUFPOS 0 ; local statics 
    @BLKN 0 
    @WROBJ 
               L1 REF :: FMC_BUFFERS 
                E SET :: 1024 
                  ADD L1 E ; Pick 2nd buffer (first used for source access) 
               L3 REF L5 :: <BUFPOS 
               L4 ADD L3 L1 
               A1 STO L4 
               L6 SET :: 255 ; Buffer full position 
                  SUB L6 L3 
               L6 ELS >FLUSHB 
                  GET L3 +1 
               L3 STO L5 
                  RET 
 
     @FLUSHB   L2 REF L6 :: BLKN             ; Block low order 
               L7 INT 0                      ; Block high order 
               L7 STO L5                     ; Reset BUFPOS to 0 
                  JSR L2 L1 L7 :: SPI_WRBLK  ; Blk num, DBuf, blk num high 
                  GET L2 +1 
               L2 STO L6 
                  RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 

    @8T3_PARSE                       ; A1/A2 payload, A3 ptr to dictionary
 
    L4 SET :: STRBUF_L0              ; Expects string in STRBUF_L0 
    DR SET :: TYS_buffersize         ; Allocate a chunk of memory 
    L7 SET :: SPACE_PTR              ; in high memory region 
    L6 LOD L7                        ; This is where individual tokens 
       SUB L6 DR                      ; are placed for the words and 
    L6 STO L7                        ; numbers on the command line 
 
    L1 INT 0 
    L1 STO L6                        ; Mark token buffer empty 
    L1 GET L6 
       JSR L6 L4 :: ASM_TOKENIZE     ; Create token for each word, number, etc
    L5 SET :: TYS_tokensize          ; Size of token structure 
 
    @DOTOKEN                         ; Now determine token type 
    E LOD L1                         ; Type in E 
    E ELS >MATCH                     ; Type 0 means end of list 

    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
      ; Continued

           E EQL 4  ; If string 
          DR THN >1 
 
               L2 GET A3 +1 
               JSR L1 L2 :: IF_DICT 
               E THN >1 
 
               JSR L1 :: IF_LABELDEF 
               E THN >1 
 
               JSR L1 :: IF_LABELREF 
               E THN >1 
 
                      JSR L1 :: IF_NUM 
                      E THN >1 
 
                            JSR L1 :: IF_WORD 
 
    @1 ADD L1 L5                    ; Point to next token 
       BRA <DOTOKEN                 ; Repeat for all tokens

     ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                


    
    ; Continued

    ; Now go through the list of defined token patterns, and if the 
    ; command line matches a pattern, call the associated handler function 
    ; a pointer to this function is part of the pattern definition 
    ; If no handler function is called (no matching patterns!) L3 = 0 
 
    @MATCH                          ; Match token seq, call pattern handler 
    L1 GET A1                       ; Now used as handler payloads 
    L5 GET A2 
 
    @NEXT 
    L3 LOD A3                       ; Pointer to pattern table 
       JSR L6 L3 L1 L5 :: TYSMATCH  ; Pattern handler return code in E 
    L3 ELS >DONE                    ; None of the patterns matched 
    L4 LOD L6                       ; Handler change L6, skips matched pattern
       THN <NEXT             ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           

     ; Continued


 
    @DONE                            ; Free the memory space that was reserved 
    DR SET :: TYS_buffersize 
    L6 LOD L7                        ; For the list of tokens 
       ADD L6 DR 
    L6 STO L7 
 
    A1 GET L1                        ; Hand these back 
    A2 GET L5 
       RET ; E has handler return code, 7Fh for no match                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
This function creates a list of token structures, each corresponding 
to a contiguous, non-whitespace "word" in the current line of source text. 
 
A1 IN Pointer to empty token buffer 
A2 IN Pointer to input line 
 
    @ASM_TOKENIZE 
    L1 GET A2             ; This buffer contains the source line to tokenize 
    L2 GET A1             ; Base pointer for the token buffer 
    L3 GET L2 
 
    @NEWTOKEN 
    L3 GET L2 
       JSR L1 :: SKIPSPACE ; Advance L1 to next non-space char 
        
   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  ; Continued 


    L6 LOD L1 
       ELS >CLOSE 
    L6 EQL ASC_semicolon  ; Check if beginning of ; comment 
    L6 INT 0              ; Fake 0 as if end of line reached 
    DR THN >CLOSE 
    L6 SET :: FFFFh       ; Force a non-0 type 
    L6 STO L2 +0 
       GET L2 +4          ; Skip type, subtype, group, index 
 
       JSR L1 L2 :: IF_STRING   ; Handle "...", advance L1 and L2 
       JSR L1 L2 :: IF_BYTESTR  ; Handle '...', advance L1 and L2 
 
     E EQL 1 
    DR THN >CLOSE       ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
    ; Continued

 
    @1 L6 LOD L1 
       L6 ELS >CLOSE      ; Null character, close token sequence 
       L6 EQL ASC_space   ; Compare to space character 
       DR THN >CLOSE      ; Finalize current token 
       L6 STO L2 
          GET L1 +1 
          GET L2 +1 
           BRA <1 
 
    @CLOSE 
    L4 INT 0 
    L4 STO L2             ; Store string terminator 
    L4 SET :: TYS_tokensize 
    L2 ADD L3 L4          ; Make L2 point to next token structure 
    L6 THN <NEWTOKEN      ; Line string closed by null char 
    L6 STO L2             ; Terminate token sequence (type 0 marker) 
 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            


The function matches tokens against patterns from the current token onwards. 
It returns a pointer to the next token to be matched in A1. 
 
A1 IN Ptr to token, update 
A2 IN Ptr to pattern structure, change 
A3 IN Handler payload 1, update 
A4 IN Handler payload 2, update 
 
    @TYSMATCH     L2 GET A1 
                  L3 GET A2 
                  L7 INT 0  ; Best match length so far 
                  A2 INT 0  ; Best match pattern pointer so far 
                  L6 LOD L3 
                  L1 GET L3 
                  L4 INT 0  ; Current match length  


     ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

   ; Continued


    @NEXT 
       JSR L6 L2         ; Comparison result in E 
       >CHECK_TOKEN 
    DR SET :: TYS_tokensize 
       ADD L2 DR          ; Point to next token 
     E ELS >FAIL         ; Token doesn't match - try next pattern 
 
       GET L4 +1         ; Add to match length 
       GET L3 +1         ; Assume pattern not finished yet, check next element
    L6 LOD L3 
    L6 ELS >SUCC         ; End of pattern: success but try to find longer 
     E LOD L2 
       THN <NEXT         ; Check if no more tokens (token type 0) 
                         ; Fall through to fail, not enough tokens for pattern


   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
    ; Continued


    @FAIL L2 GET A1       ; Restart at first token 
          L4 INT 0        ; Reset match length 
             GET L1 +7    ; Point to next pattern 
             GET L1 +1 
          L3 GET L1       ; Fresh pointer to current pattern 
          L6 LOD L3       ; If first element is non-0, check pattern 
             THN <NEXT 
          L7 THN >BEST    ; If a matching pattern was found 
          A2 INT 0        ; Result code: No matching pattern 
           E SET :: 7Fh   ; Fake a handler return code (no match) 
               BRA >DONE 
 
    @SUCC L6 SUB L7 L4    ; See if longer than previous match 
          DR THN <FAIL 
          L7 GET L4       ; Store as new best match 
          A2 GET L1 
             BRA <FAIL         ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             

   ; Continued


    @BEST L4 GET A3       ; Pass in payload 1 
          L5 GET A4       ; Pass in payload 2 
           E INT 1        ; Sanitize handler return code to "normal" 
          L3 LOD A2 +6    ; Get handler ID (if handler for several) 
          DR LOD A2 +7    ; Get pointer to pattern handler 
 
             JSR L2 L4 L5 L3 :: 0  ; JSR address in D 
 
          A1 GET L2       ; A1 now points to *next* token to be matched 
          A3 GET L4       ; Update payload 1 
          A4 GET L5       ; Update payload 2 
 
       @DONE RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    


This is a helper function for TYSMATCH. It matches one token against one 
pattern element. 
 
A1 IN Current pattern element 
A2 IN Pointer to token 
 
    @CHECK_TOKEN 
    L1 INT 15 
    L2 GET A1 
    L3 GET A2 
 
    E AND L2 L1   ; Check expected type 
      SHR L2 4 
    E ELS >0      ; Type 0: match any type 
   L4 LOD L3 +0   ; Compare to token element type 
      SUB E L4 
    E THN >FAIL   ; Pattern fails, types don't match for current element 
 
 @0 E AND L2 L1   ; Check expected subtype 
      SHR L2 4 
    E ELS >1      ; Subtype 0: match any subtype 
   L4 LOD L3 +1   ; Compare to token element subtype 
      SUB E L4 
    E THN >FAIL   ; Pattern fails, subtypes don't match   


   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    


   ; Continued

 @1 E AND L2 L1   ; Check expected group 
      SHR L2 4 
    E ELS >2      ; Group 0: match any group but not any index 
   L4 LOD L3 +2   ; Compare to token element group 
      SUB E L4 
    E THN >FAIL   ; Pattern fails, groups don't match 
   L6 INT 8 
   L6 AND E L6    ; Check if negative (8-D) 
   L6 ELS >CONT   ; Group 1-7: match any index 
 
 @2 E AND L2 L1   ; Check expected index 
   L4 LOD L3 +3   ; Compare to token element index 
      SUB E L4 
      THN >FAIL   ; Pattern fails, indices don't match 
 
 @CONT E INT 1 
         RET 
 
 @FAIL E INT 0 
         RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
This is a subordinate function used by ASM_TOKENIZE. It tests whether the 
current character during tokenization is an inch-mark (") indicating the 
beginning of a string literal. In this case, the token must not break at 
a space character, but runs until the trailing ("). 
 
A1 IN Pointer to current character of the source text line, update 
A2 IN Pointer to string entry of current token, update 
 
E OUT 0: No group found, continue / 1: Found a group, close token 
 
    @IF_STRING 
    L4 INT 0 ; Assume no group found 
    L2 LOD A1 
       ELS >DONE ; If string terminator (null), let caller handle it 
 
       L2 EQL ASC_doublequote ; Test if " 
       DR ELS >DONE 
 
          GET A1 +1 ; Skip " 
        E INT 4 
       L5 GET A2 -4 
        E STO L5    ; Set token type to string 
        E INT 1 
       L5 GET A2 -2 
        E STO L5    ; Set group to 1  SHOULD THIS NOT SeT SUBTYPE?  


     ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
    ; Continued
 
 
    @FOUND L4 INT 1 
    @COPY 
       L2 LOD A1 
          ELS >DONE ; Test if line end 
 
       L2 EQL ASC_doublequote ; Test if " 
       DR THN >FIX 
 
       L2 STO A2 
          GET A1 +1 
          GET A2 +1 
            BRA <COPY 
 
    @FIX GET A1 +1 ; Skip trailing " 
    @DONE 
    E GET L4 
      RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
This is a subordinate function used by ASM_TOKENIZE. It tests whether the 
current character during tokenization is (') indicating the 
beginning of a string literal. In this case, the token must not break at 
a space character, but runs until the trailing ('). 
 
A1 IN Pointer to current character of the source text line, update 
A2 IN Pointer to string entry of current token, update 
 
E OUT 0: No group found, continue / 1: Found a group, close token 
 
    @IF_BYTESTR 
    L4 INT 0 ; Assume no group found 
    L2 LOD A1 
       ELS >DONE ; If string terminator (null), let caller handle it 
 
       L2 EQL ASC_singlequote ; Test if opening ' 
       DR ELS >DONE 
 
          GET A1 +1 ; Skip ' 
        E INT 4 
       L5 GET A2 -4 
        E STO L5    ; Set token type to string 
        E INT 1 
       L5 GET A2 -2 
        E STO L5    ; Set group to 1  SHOULD THIS NOT SeT SUBTYPE?  

   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            


   ; Continued


    @FOUND L4 INT 1 
    @COPY 
       L2 LOD A1               ; First char 
          ELS >DONE            ; Test if line end 
       L2 EQL ASC_singlequote  ; Test if closing ' 
       DR THN >FIX 
          GET A1 +1 
 
       DR INT 3 
          SHL L2 8             ; If missing 2nd char, use ASC 3 (End of Text) 
          IOR L2 DR 
       L3 LOD A1               ; Second char 
       L3 ELS >DONE            ; Test if line end 
       L3 EQL ASC_singlequote  ; Test if closing ' 
       DR THN >A 
          GET A1 +1   


     ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
     ; Continued


       DR SET :: FF00h         ; Clear lower nibble (ASC 3 set above) 
          AND L2 DR 
          IOR L2 L3 
       L2 STO A2 
          GET A2 +1 
            BRA <COPY 
 
    @A L2 STO A2               ; Flush incomplete cell 
          GET A2 +1 
 
    @FIX GET A1 +1 ; Skip trailing ' 
    @DONE 
    E GET L4 
      RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
This is a subordinate function used by ASM_EVALUATE. It tests whether the 
given token is a number (-123, 4Eh). 
 
A1 IN Pointer to current token 
 
E OUT 0: Not recognized / 1: Recognized 
 
    @IF_NUM 
    L1 GET A1 +4                ; Pointer to string in current token 
       JSR L1 L2 :: PARSENUM 
     E THN >FAIL 
 
    L2 STO A1 +3        ; Store the number as token "index" 
     E INT 3 
     E STO A1 +0        ; Set token type to number 
     E INT 2 
     E STO A1 +2        ; Set group to 2 (same as DEF numbers) 
    L7 INT 1            ; Number was found 
 
        BRA >SUCC 
 
    @FAIL L7 INT 0 
    @SUCC 
    E GET L7 
      RET      

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
This is a subordinate function used by ASM_EVALUATE. It tests whether the 
given token is a register or opcode mnemonic (L6, ADD). 
 
A1 IN Pointer to current token, A2 ptr to dictionary 
 
E OUT 0: Not recognized / 1: Recognized 
 
    @IF_DICT 
    L1 GET A2 
    L3 GET L1 
    L4 GET A1 +4 
    L5 INT 12      ; Size of string buffer in dictionary entry 
 
    @1 L2 LOD L3                        ; Type 0 means end of table 
          ELS >FAIL 
          GET L3 +4                     ; Skip numbers (4 cells) 
       L6 INT 0 
          JSR L3 L4 L6 :: STRCMP 
        E THN >FOUND 
          ADD L3 L5 
          THN <1  


   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         

  ; Continued

    @FAIL 
    E INT 0 
        BRA >DONE 
 
    @FOUND 
    E INT 1 
 
   L7 SET :: TYS_tokensize ; Copy trailing two words from DICT to end of token
      GET L7 -6            ; -4 since pre-incremented -2 picks penult item 
      GET L5 -2 
      ADD L7 L4 
      ADD L5 L3 
   L6 LOD L5     ; Copy penult word 
   L6 STO L7 
   L6 LOD L5 +1  ; Copy last word 
   L6 STO L7 +1    

  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
    ; Continued

 
      GET L3 -4 
      GET L4 -4 
 
   L6 LOD L3 0 
   L6 STO L4 0 
 
   L6 LOD L3 1 
   L6 STO L4 1 
 
   L6 LOD L3 2 
   L6 STO L4 2 
 
   L6 LOD L3 3 
   L6 STO L4 3 
 
    @DONE 
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
This is a subordinate function used by ASM_EVALUATE. It tests whether the 
given token is a label definition (@LABEL, $LABEL). 
 
A1 IN Pointer to current token 
 
E OUT 0: Not recognized / 1: Recognized 
 
    @IF_LABELDEF 
 
    L1 LOD A1 +4
    L7 INT 0              ; Assume subtype = @ 
    L1 EQL ASC_atsign     ; First char of label definition must be "@" 
    DR THN >1
    L7 INT 1              ; Assume subtype = $
    L1 EQL ASC_dollar     ; or dollar sign
    DR ELS >FAIL 
 
 @1 L1 GET A1 +4 
    L2 INT 1 
       JSR L1 L2 :: CUTLEFT    ; Remove "@/$" character 
     
    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

   ; Continued
 
    L6 INT 6 
    L6 STO A1        ; Set token type 
    L7 STO A1 +1     ; Set token subtype 
    L6 INT 1 
    L6 STO A1 +2     ; Set token group 
 
    E INT 1 
        BRA >DONE 
 
    @FAIL E INT 0 
    @DONE 
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    



























Creates a new symbol table entry, copying data from the token parameter. 
 
A1 IN Token pointer, keep! 
 
    @NEWSYMBOL 
    L4 GET A1 
    L2 SET :: TYS_symsize ; Max symbol table entry size 
    L3 GET L2 
    L5 REF :: SYMINSPOS 
    L7 GET L5 
 
    @COPY 
    L6 LOD L4 
    L6 STO L5 
       GET L4 +1 
       GET L5 +1 
    L2 REP <COPY 
 
       ADD L7 L3     ; Point to next entry 
 
    L7 PER :: SYMINSPOS 
    L6 INT 0 
    L5 GET L7 -1 
    L6 STO L5     ; Force string terminator (runaway token may be longer) 
 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         





























Symbol table look-up, return value in E. 
A1 IN Token pointer 
A2 OUT Pointer to symbol entry 
E OUT 0: Not found / 1: Found 
 
    @GETSYMBOL 
    L2 SET :: TYS_symsize ; Max symbol table entry size 
    L4 INT 0 
    L5 GET A1 +4 
 
    L1 REF  :: SYMTAB 
       @1 L3 LOD L1 
             ELS >FAIL 
 
          @COMPARE 
          L7 GET L1 +4       ; Prepare STRCMP arg 
             JSR L7 L5 L4 
             STRCMP 
             ADD L1 L2       ; Point to next symbol 
          E ELS <1        ; E STRCMP result code 
          A2 GET L7 -4 
              BRA >SUCC 
 
    @FAIL E INT 0 
    @SUCC  RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           A1 IN Pointer to current token  
E OUT 0: Not recognized / 1: Recognized  
  
    @IF_LABELREF  
    L1 GET A1  
    L7 INT 7          ; Default type 7 
    L5 INT 1          ; Default cut 1 char 

    L2 LOD L1 +4  
    L2 EQL ASC_less   ; First char must be "<" or ">"  
    DR ELS >2         ; else check if  ">" 
    L2 LOD L1 +5  
    L2 EQL ASC_less   ; If repeated, relative REF (type F)    
    DR ELS >1         ; else abs REF (default type 7) 
    L7 INT Fh 
    L5 INT 2          ; Cut 2 chars 
 @1 L6 INT 1  
    L6 STO A1 +1      ; Set token subtype (backward ref)  
       BRA >COMMON  
  
 @2 L2 EQL ASC_greater ; Check if ">" 
    DR ELS >FAIL  
    L2 LOD L1 +5 
    L2 EQL ASC_greater ; If repeated, relative REF (type F) 
    DR ELS >3          ; else abs REF (default type 7) 
    L7 INT Fh 
    L5 INT 2 
 @3 L6 INT 2  
    L6 STO A1 +1       ; Set token subtype (forward ref)    
   
 ; Continue                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
 ; Continued 
 
      @COMMON  
      GET L1 +3
      ADD L1 L5   
      JSR L1 L5 :: CUTLEFT ; Remove the "<" or ">" characters  
   L7 STO A1               ; Set token type  
                           ; Subtype set above  
   L6 INT 1  
   L6 STO A1 +2            ; Set token group  
    E INT 1  
      BRA >DONE  
  
    @FAIL E INT 0  
    @DONE  
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
Given the current assembly 
address (Effective), it searches for the nearest matching symbol in the given 
direction "<" or ">". It stores the (absolute) distance in the token. 
 
A1 IN Pointer to token 
A2 IN Base 
A3 IN Effective 
 
;A4 OUT Pointer to best match symbol 
E OUT Best absolute displacement found 
 
    @NEAREST 
    L2 SET :: FFFFh        ; Best distance infinite so far 
    L7 LOD A1 +1           ; Type of reference, 1:"<" and 2:">" 
    L3 GET A1 +4           ; Point to token string 
    L1 REF :: SYMTAB       ; L1 is pointer to first symbol in table   


   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
     ; Continued


    @NEXT                  ; L1 points to beginning of current symbol 
    L6 LOD L1              ; Check if end of symbol table 
    L6 ELS >DONE 
       GET L1 +4           ; Skip to string part 
    E INT 6 
       SUB E L6 
       THN >DIFFER       ; Has to be a label entry 
 
       L6 INT 0            ; Compare 0 terminated strings 
          JSR L1 L3 L6 
          STRCMP 
       E ELS >DIFFER 
 
       L5 GET L1 -1 
       L5 LOD L5          ; Get the reference address from symbol index 
       L6 INT 1 
          SUB L6 L7 
       L6 THN >FWD


   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
     ; Continued

 
                 L6 SUB A3 L5     ; Test if really before 
                 L4 SUB L5 A3 
                     BRA >1 
 
          @FWD   L6 SUB L5 A3     ; Test if really after 
                 L4 SUB A3 L5 
          @1 
 
          E GET DR        ; Check last subtr carry 
          A3 ELS >SUCC 
          E THN >DIFFER 
 
          @SUCC 
          E SUB L6 L2     ; Compare to current best distance 
          E GET DR 
          E THN >DIFFER

   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
   ; Continued

 
 
       L2 GET L6           ; Update closest distance 
       A4 GET L1 -4        ; Keep a pointer to it 
 
    @DIFFER 
    E SET :: TYS_symsize 
    GET L1 -4              ; Reset to beginning 
    ADD L1 E              ; Point to next entry 
        BRA <NEXT 
 
    @DONE 
    E GET L2 
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
This is a subordinate function used by ASM_EVALUATE. It sets the token type 
to "word" meaning an unrecognized string (SOMETHING), and finds out the mixed 
case subtype used in DEFs etc. 
 
A1 IN Pointer to current token 
 
    @IF_WORD 
    E LOD A1 
 
    E EQL 4          ; Strings are special, recognized in IF_STRING 
   DR THN >DONE 
 
    L2 GET A1 +4 
    L3 INT 1       ; Assume no lower case present 
    L4 SET :: ASC_a 
       GET L4 -1 
    L5 SET :: ASC_z 
       GET L5 +1 
    L7 SET :: ASC_underscore 
 
    
  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

  ; Continued

    @NEXT 
    L1 LOD L2 
       GET L2 +1 
    L1 ELS >SUBTYPE 
    E SUB L1 L7 
       ELS >1 
 
    E SUB L4 L1 
   DR THN <NEXT 
    E SUB L1 L5 
   DR THN <NEXT 
 
    @1 
    L3 INT 2       ; Mixed case or lower case 
 
    @SUBTYPE 
    L6 INT 5 
    L6 STO A1        ; Set token type 
    L3 STO A1 +1     ; Set token subtype 
    L3 INT 2       ; Group 2 
    L3 STO A1 +2     ; Set token group 
 
    @DONE 
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    


The following structure is the ASM dictionary. This structure is used by 
the pattern matcher for recognizing instruction and register mnemonics. 
 
 
 @ASM_TOKS 
 
 >ASM_PATTS   ; The final two words (pos 15,16) are copied into the token 
              ; during IF_DICT matching 
 
 1 1 1 0h "TOS" 0     0 0 0 0 0 0 0 0 
 1 1 1 1h "E" 0 0 0   0 0 0 0 0 0 0 0 
 1 1 1 2h "SP"  0 0   0 0 0 0 0 0 0 0 
 1 1 1 3h "DP"  0 0   0 0 0 0 0 0 0 0 
 
 1 3 1 4h "A1"  0 0   0 0 0 0 0 0 0 0 
 1 3 1 5h "A2"  0 0   0 0 0 0 0 0 0 0 
 1 3 1 6h "A3"  0 0   0 0 0 0 0 0 0 0 
 1 3 1 7h "A4"  0 0   0 0 0 0 0 0 0 0 
 
 1 4 1 8h "DR"  0 0   0 0 0 0 0 0 0 0 
 1 4 1 9h "L1"  0 0   0 0 0 0 0 0 0 0 
 1 4 1 Ah "L2"  0 0   0 0 0 0 0 0 0 0 
 1 4 1 Bh "L3"  0 0   0 0 0 0 0 0 0 0 
 1 4 1 Ch "L4"  0 0   0 0 0 0 0 0 0 0 
 1 4 1 Dh "L5"  0 0   0 0 0 0 0 0 0 0 
 1 4 1 Eh "L6"  0 0   0 0 0 0 0 0 0 0 
 1 4 1 Fh "L7"  0 0   0 0 0 0 0 0 0 0                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
 8 1 1 1h "DEF" 0     0 0 0 0 0 0 0 0 
 8 1 1 2h "::"  0 0   0 0 0 0 0 0 0 0 
 8 2 1 1h "ORG" 0     0 0 0 0 0 0 0 0 
 8 3 1 1h "END."      0 0 0 0 0 0 0 0 ; Was for divecode 
 8 4 1 1h "BANK"      0 0 0 0 0 0 0 0 
 
 9 6 1 0h "ZOP" 0     0 0 0 0 0 0 0 0 
 9 2 1 0h "SOP" 0     0 0 0 0 0 0 0 80h 
 9 4 1 1h "ELS" 0     0 0 0 0 0 0 0 0 
 9 4 1 1h "THN" 0     0 0 0 0 0 0 0 80h 
 9 4 1 2h "REP" 0     0 0 0 0 0 0 0 0 
 9 2 1 2h "LTL" 0     0 0 0 0 0 0 0 80h 
 9 2 1 3h "EQL" 0     0 0 0 0 0 0 0 0 
 9 2 1 3h "GTL" 0     0 0 0 0 0 0 0 80h 
 
 9 2 1 4h "INT" 0     0 0 0 0 0 0 0 0 
 9 1 1 4h "LTR" 0     0 0 0 0 0 0 0 8 
 9 1 1 5h "EQR" 0     0 0 0 0 0 0 0 0 
 9 1 1 5h "GTR" 0     0 0 0 0 0 0 0 8 
 9 1 1 6h "LOD" 0     0 0 0 0 0 0 0 0 
 9 1 1 6h "STO" 0     0 0 0 0 0 0 0 8 
 9 1 1 7h "SHL" 0     0 0 0 0 0 0 0 0 
 9 1 1 7h "SHR" 0     0 0 0 0 0 0 0 8                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
 9 5 1 8h "JSR" 0     0 0 0 0 0 0 0 0 
 9 7 1 9h "DOP" 0     0 0 0 0 0 0 0 0 
 9 1 1 Ah "GET" 0     0 0 0 0 0 0 0 0 
 9 3 1 Bh "AND" 0     0 0 0 0 0 0 0 0 
 9 3 1 Ch "IOR" 0     0 0 0 0 0 0 0 0 
 9 3 1 Dh "EOR" 0     0 0 0 0 0 0 0 0 
 9 3 1 Eh "ADD" 0     0 0 0 0 0 0 0 0 
 9 3 1 Fh "SUB" 0     0 0 0 0 0 0 0 0                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
 ; Following IDs map to SOP instruction switch 
 
 Ah 6 1 0 "SET" 0     0 0 0 0 0 0 0 sop_SET 
 Ah 6 1 0 "PER" 0     0 0 0 0 0 0 0 sop_PER 
 Ah 6 1 0 "PUSH"      0 0 0 0 0 0 0 sop_PUSH 
 Ah 6 1 0 "POP" 0     0 0 0 0 0 0 0 sop_POP 
 Ah 6 1 0 "EXEC"      0 0 0 0 0 0 0 sop_EXEC 
 Ah 6 1 0 "GO" 0    0 0 0 0 0 0 0 0 sop_GO 
 Ah 6 1 0 "PC-GET"        0 0 0 0 0 sop_PC_GET 
 Ah 6 1 0 "VIA" 0     0 0 0 0 0 0 0 sop_VIA 
 Ah 6 1 0 "IP-GET"        0 0 0 0 0 sop_IP_GET 
 Ah 6 1 0 "IP-SET"        0 0 0 0 0 sop_IP_SET 
 Ah 6 1 0 "IP-POP"        0 0 0 0 0 sop_IP_POP 
 Ah 6 1 0 "CALLER"        0 0 0 0 0 sop_CALLER 
 Ah 6 1 0 "W-GET"       0 0 0 0 0 0 sop_W_GET 
 Ah 6 1 0 "MSB" 0     0 0 0 0 0 0 0 sop_MSB 
 Ah 6 1 0 "LSB" 0     0 0 0 0 0 0 0 sop_LSB 
 Ah 6 1 0 "NOT" 0     0 0 0 0 0 0 0 sop_NOT 
 Ah 6 1 0 "NEG" 0     0 0 0 0 0 0 0 sop_NEG 
 Ah 6 1 0 "BYTE"      0 0 0 0 0 0 0 sop_BYTE 
 Ah 6 1 0 "NYBL"      0 0 0 0 0 0 0 sop_NYBL                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

 Ah 6 1 0 "PICK"      0 0 0 0 0 0 0 sop_PICK 
 Ah 6 1 0 "DROP"      0 0 0 0 0 0 0 sop_DROP 
 Ah 6 1 0 "LIT" 0     0 0 0 0 0 0 0 sop_LIT 
 Ah 6 1 0 "ONEHOT"        0 0 0 0 0 sop_ONEHOT 
 Ah 6 1 0 "IRQ-VEC"         0 0 0 0 sop_IRQ_vec 
 Ah 6 1 0 "RETI"      0 0 0 0 0 0 0 sop_RETI 
 Ah 6 1 0 "STOS"      0 0 0 0 0 0 0 sop_STOS 
 Ah 6 1 0 "LODS"      0 0 0 0 0 0 0 sop_LODS 
 Ah 6 1 0 "SERVICE"         0 0 0 0 sop_SERVICE 
 Ah 6 1 0 "OVERLAY"         0 0 0 0 sop_OVERLAY 
 
 ; Following IDs map to ZOP instruction switch 
 
 Bh 6 1 0h "RET" 0    0 0 0 0 0 0 0 zop_RET 
 Bh 6 1 0h "NEXT"     0 0 0 0 0 0 0 zop_NEXT 
 Bh 6 1 0h "SWAP"     0 0 0 0 0 0 0 zop_SWAP 
 Bh 6 1 0h "CLAIM"      0 0 0 0 0 0 zop_CLAIM 
 Bh 6 1 0h "CEDE"     0 0 0 0 0 0 0 zop_CEDE 
 Bh 6 1 0h "STALL"      0 0 0 0 0 0 zop_STALL 
 Bh 6 1 0h "THREAD"       0 0 0 0 0 zop_THREAD 
 Bh 6 1 0h "DOCOL"      0 0 0 0 0 0 zop_DOCOL 
 Bh 6 1 0h "JUMP"     0 0 0 0 0 0 0 zop_JUMP 
 Bh 6 1 0h "IP-COND"        0 0 0 0 zop_IP_COND 
 Bh 6 1 0h "NOP" 0    0 0 0 0 0 0 0 zop_NOP 
 Bh 6 1 0h "IDLE"     0 0 0 0 0 0 0 zop_VM_IDLE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

 
 Bh 6 1 9h "REF" 0    0 0 0 0 0 0 dop_REF       0 
 Bh 6 1 9h "BRA" 0    0 0 0 0 0 0 dop_BRA       0 
 Bh 6 1 9h "PEEK"     0 0 0 0 0 0 dop_PEEK      0 
 Bh 6 1 9h "PULL"     0 0 0 0 0 0 dop_PULL      0 
 Bh 6 1 9h "GFX-LD"       0 0 0 0 dop_GFX_LD    0 
 Bh 6 1 9h "GFX-ST"       0 0 0 0 dop_GFX_ST    0 
 Bh 6 1 9h "GFX-THRU"         0 0 dop_GFX_THRU  0 
 
 Ch 1 1 0h "NOP."        0 0 0 0 0 0 0   00h ; Was for divecode 
 Ch 1 1 0h "EMERGE."           0 0 0 0   01h 
 
 0 ; End marker                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    


 
The following structure are the assembler patterns (each of size 7) used 
by the pattern matcher. 

How do these work? Patterns are matched for each token found in the
input line. A pattern match calls the corresponding handler with a pointer
to the current token and the current assembler address, both of which the
handler can update. In particular, it should advance to the next token
following the pattern.

 @ASM_PATTS 
 
Type Subtype Charge (Group Index), 0 = ANY, Group<8 match any index 
 
TOKTYPREG=1 TOKTYPOPC=2 TOKTYPNUM=3 TOKTYPSTR=4 TOKTYPWRD=5 
TOKTYPLAB=6 TOKTYPREF=7 8=Directives 
 
 0107h 0000h 0000h 0000h 0000h 0000h  1 H_REF      ; Match <LABEL, >LABEL 
 0106h 0000h 0000h 0000h 0000h 0000h  2 H_LABEL    ; Match @LABEL 
 0205h 0000h 0000h 0000h 0000h 0000h  3 H_WORD     ; Match isolated WORDs 
 0104h 0000h 0000h 0000h 0000h 0000h  4 H_STRING   ; Match "Bla bla..." 
 0203h 0000h 0000h 0000h 0000h 0000h  5 H_NUMBER   ; Match 123 
 1118h 0225h 0203h 0000h 0000h 0000h  6 H_DEF      ; Match DEF Mixed 123 
 2118h 0000h 0000h 0000h 0000h 0000h  7 H_BREAK    ; Match :: break pattern 
 1128h 0203h 0000h 0000h 0000h 0000h  8 H_ORG      ; Match ORG 1000h 
 1138h 0000h 0000h 0000h 0000h 0000h  9 H_END      ; Match END 
 1148h 0000h 0000h 0000h 0000h 0000h 10 H_BANK     ; Match BANK
 010Fh 0000h 0000h 0000h 0000h 0000h 11 H_REL      ; Match <<LABEL, >>LABEL                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
 0159h 0000h 0000h 0000h 0000h 0000h 18 H_PATT05   ; JSR 
 0159h 0141h 0000h 0000h 0000h 0000h 19 H_PATT06   ; JSR L6 
 0159h 0141h 0141h 0000h 0000h 0000h 20 H_PATT07   ; JSR L6 L6 
 0159h 0141h 0141h 0141h 0000h 0000h 21 H_PATT08   ; JSR L6 L6 L6 
 0159h 0141h 0141h 0141h 0141h 0000h 22 H_PATT09   ; JSR L6 L6 L6 L6 
 
 0101h 0119h 0101h 0200h 0000h 0000h 13 H_NYBBLE   ; Full 
 0119h 0101h 0200h 0000h 0000h 0000h 14 H_NYBBLE   ; Missing L 
 0101h 0119h 0101h 0000h 0000h 0000h 15 H_NYBBLE   ; Missing R2 
 0119h 0101h 0000h 0000h 0000h 0000h 16 H_NYBBLE   ; Missing both 
 0101h 0129h 0200h 0000h 0000h 0000h 17 H_BYTE     ; Full 
 0101h 0139h 0101h 0101h 0000h 0000h 18 H_REGS     ; Full 
 0101h 0139h 0101h 0201h 0000h 0000h 19 H_REGS     ; Full masked 
 0139h 0101h 0101h 0000h 0000h 0000h 20 H_REGS     ; Missing L 
 0139h 0101h 0201h 0000h 0000h 0000h 21 H_REGS     ; Missing L masked 
 0101h 0149h 0107h 0000h 0000h 0000h 22 H_BRA      ; Full                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    


 
 0149h 0107h 0000h 0000h 0000h 0000h 23 H_BRA      ; Missing L 
 0101h 0129h 0000h 0000h 0000h 0000h 24 H_BYTE     ; 
 0101h 0129h 0101h 0225h 0000h 0000h 25 H_CPU      ; reg SOP reg label 
 0169h 0200h 0000h 0000h 0000h 0000h 26 H_EXT_SIG  ; ZOP ZOP (ZOP + code) 
 016Bh 0000h 0000h 0000h 0000h 0000h 27 H_EXT_SIG  ; ZOP ZOP (name) 
 016Bh 0107h 0000h 0000h 0000h 0000h 28 H_EXT_BRA  ; ZOP branch 
 0101h 016Ah 0000h 0000h 0000h 0000h 29 H_CPU_MAP  ; SOP mapped opcodes 
 0101h 016Bh 0101h 0000h 0000h 0000h 30 H_EXT_2REG ; ZOP mapped codes 2reg 
 0101h 016Bh 0000h 0000h 0000h 0000h 31 H_EXT_2REG ; ZOP mapped codes 1reg 
 0200h 0179h 0101h 0200h 0000h 0000h 32 H_PAR      ; DOP instruction 
 0200h 0179h 0101h 0000h 0000h 0000h 33 H_PAR      ; DOP instruction implied 
 0101h 016Bh 0200h 0000h 0000h 0000h 30 H_EXT_2REG ; ZOP mapped codes use 30! 
 0200h 016Ah 0000h 0000h 0000h 0000h 24 H_CPU_MAP  ; SOP mapped codes use 29! 
 011Ch 0000h 0000h 0000h 0000h 0000h 34 H_DIVE     ; DIVECODE instruction 
 
 0 ; End of pattern list                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
The following batch of functions each handle a specific pattern, for example 
register, instruction name, register. 
 
******************************************************************************* 
 
This is a helper for the pattern handler functions. It advances the token ptr 
a given number of tokens, which typically corresponds to the number of tokens 
matched. It tries to not go past the end of the token buffer. 
 
A1 IN Pointer to token, update 
A2 IN Number of tokens to skip 
 
    @TYS_SKIP 
    L6 SET :: TYS_tokensize 
 
    @NEXT 
    E LOD A1 
    E ELS >DONE 
 
    ADD A1 L6 
 A2 REP <NEXT 
 
    @DONE 
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
This is a helper for the pattern handler functions. It retrieves a value from 
one of the downstream tokens in the pattern, typically subtype or index. 
 
A1 IN Pointer to token buffer 
A2 IN Number of tokens to skip 
A3 IN Offset from where to retrieve 
 
A2 OUT Pointer to requested token 
 
E OUT Requested value 
 
    @TYS_INFO 
    L6 SET :: TYS_tokensize 
    L1 GET A1 
 
    @NEXT 
    E LOD L1 
       ELS >DONE 
 
       ADD L1 L6 
    A2 REP <NEXT 
 
    A2 GET L1 
       ADD L1 A3 
    E LOD L1 
 
    @DONE 
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            

Helper function for pattern handlers. Looks up the token and either returns the
value directly for numbers, or looks up the value in symbol table for words. 
 
A1 IN Token pointer 
A2 OUT Number value 
 
    @TYS_MIXED 
    L2 GET A1 
 
    E LOD A1         ; Load token type 
    E EQL 5 
   DR THN >MIXED   ; Test if number or Mixed 
 
      LOD L2 +3      ; Get slot 3 NUM 
        BRA >COMMON 
 
    @MIXED 
       JSR L2 L2 
       GETSYMBOL 
       LOD L2 +3 
 
    @COMMON 
    A2 GET L2 
    RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
Pattern handler function. This handler resolves DIVECODE instructions and 
writes the values/addresses into the object stream. 
 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
 
    @H_DIVE 
    L6 SET :: TYS_tokensize 
    L3 GET L6 -1 
    L3 ADD A1 L3 
       LOD L3 0     ; L3 dive opcode value 
       ADD A1 L6    ; Skip string token 
 
    L1 SET :: ASM_BLKASM 
       GET L1 -3 
    L4 LOD L1 +1    ; Load current dive instruction word 
       SHL L4 8 
       IOR L4 L3    ; Mask in the new opcode 
    DR LOD L1       ; D is byte counter   

  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             

    ; Continued  

    DR THN >1       ; Branch and store if it was a second op
    L4 STO L1 +1    ; Update (incomplete) instruction word 
       GET DR +1 
    DR STO L1       ; Update byte counter 
       RET 
    @1 
    L2 ADD A2 A3    ; Write complete two byte instruction word 
       GET A3 +1 
    JSR L2 L4 :: WRCODE
 
    DR INT 0 
    DR STO L1 +1    ; Reset instruction word dummy 
    DR STO L1       ; Reset byte counter 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
Pattern handler function. This handler triggers on "BANK" and (re)sets the 
object code address to the first overlay address, without changing the 
object code pointer. 
 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
 
    @H_BANK 
    L6 GET A1 
    DR REF :: ASMMOD   ; For memory target don't pad
    DR THN >2
 
    L5 SET :: FFFFh    ; Pad to here (Set to ORG E000h before first BANK )
    L4 INT 0 
 @1    JSR L5 L4 :: WRCODE ; Padd object code with zeros to ORG address 
       GET A3 +1 
    L7 SUB L5 A3 
    L7 THN <1 
       JSR L5 L4 :: WRCODE ; One more to 10000h, the L5s are just dummies! 
 
 @2 A3 SET :: E000h    ; Always same OVERLAY base address 
 
    L2 INT 1           ; Advance to next token 
    JSR L6 L2 
    TYS_SKIP 
 
     E INT 0           ; Return value 
    A1 GET L6          ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
Pattern handler function. This handler triggers on "END." and closes any 
incomplete dive instruction. 
 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
 
    @H_END 
    L6 SET :: TYS_tokensize 
       ADD A1 L6 ; Skip string token 
 
    L1 SET :: ASM_BLKASM 
       GET L1 -3 
    L4 LOD L1    ; L4 is the byte counter 
    L5 LOD L1 +1 ; L5 is current instruction word 
    L4 THN >1 ; Branch and store pending instruction word 
       RET 
    @1 
    L2 ADD A2 A3 
       GET A3 +1 
       SHL L4 8  ; Move opcode to right place 
    JSR L2 L4 :: WRCODE
    DR INT 0 
    DR STO L1 +1 ; Reset instruction word dummy 
    DR STO L1    ; Reset byte counter 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
Handler function for INT instruction. 
 
 @H_PAR 
 
    L6 SET :: TYS_tokensize 
    L7 INT 0 ; Default value for R1 operand = 0 
 
    L4 LOD A1 +3 ; L value 
       ADD A1 L6 
    L5 LOD A1 +3 ; Base opcode 
       ADD A1 L6 
    L1 LOD A1 +3 ; R1 operand 
       ADD A1 L6 
 
    A4 EQL 33 
    DR THN >A ; Branch if R1 implied 
 
    L7 LOD A1 +3 ; R2 
       ADD A1 L6 
    L2 INT 15 
       AND L7 L2 ; Sanitize R2 to 4-bit range 

  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            

  ; Continued
 
    @A SHL L5 4 
       IOR L5 L4 
       SHL L5 4 
       IOR L5 L7 
       SHL L5 4 
       IOR L5 L1 
 
    L2 SET :: ASM_BLKASM 
    L3 GET L2 -1 
    L4 STO L3 ; Update LHS op 
 
    L2 ADD A2 A3 
       GET A3 +1 
    JSR L2 L5 :: WRCODE 
 
 @DONE RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
Handler function for reg SOP reg label. 
 
 @H_CPU 
 
    L6 SET :: TYS_tokensize 
    L7 INT 0 ; Default value for R1 operand = 0 
 
    L4 LOD A1 +3 ; L operand 
       ADD A1 L6 
 
    L5 LOD A1 +3 ; Base opcode 
    L3 GET L6 -1 
    L3 ADD A1 L3 
       LOD L3 0  ; L3 now opcode extension bit 
       ADD A1 L6 
    L1 LOD A1 +3 ; R1 operand 
 
       ADD A1 L6 
    L7 GET A1 
       JSR L7 L7 :: TYS_MIXED ; L7 now R2 operand (literal or def'd value) 
       ADD A1 L6        ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
 ; Continued

   L2 INT 15 
       AND L7 L2 ; Sanitize R2 to 4-bit range 
 
       SHL L5 4 
       IOR L5 L4 
       SHL L5 4 
       IOR L5 L7 
       SHL L5 4 
       IOR L5 L1 
 
    L2 SET :: ASM_BLKASM 
    L3 GET L2 -1 
    L4 STO L3 ; Update LHS op 
 
    L2 ADD A2 A3 
       GET A3 +1  
    JSR L2 L5 :: WRCODE 
 
 @DONE RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
Handler function for branch opcode. 
 
 @TEMP 0
 @H_BRA 
 
    L6 SET :: TYS_tokensize 
 
    A4 EQL 23 
    DR THN >0    ; Branch if missing L (23) 
    L4 LOD A1 +3 ; L operand 
       ADD A1 L6 
 @0 
    L5 LOD A1 +3 ; Base opcode 
    L3 GET L6 -1 
    L3 ADD A1 L3 
       LOD L3 0  ; L3 now opcode extension bit 
       ADD A1 L6 ; Now points to branch offset token 
 
    A4 EQL 22 
    DR THN >1 ; Branch if pattern has an L operand 
    L2 SET :: ASM_BLKASM 
    L1 GET L2 -1 
    L4 LOD L1 ; Set L operand to "default" LHS op   

   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
 ; Continued

 @1 
    L2 GET A1 
    L1 GET A2 
    L7 GET A3 
    L3 PER :: <TEMP  ; Push L3 (no more spare registers) 
       JSR L2 L1 L7 L3 ; E best absolute displacement 
       NEAREST 
 
    L1 LOD A1 +1 ; Subtype (1: Backward / 2: Forward) 
    L1 EQL 1 
        DR ELS >FWD 
        L3 SET :: FFFFh 
           EOR E L3 
           GET E +1 ; Negated distance 
       @FWD 
    L1 GET E 
    L2 SET :: 127 ; Force 7 bit range 
       AND L1 L2 
    L3 REF :: <TEMP 
       IOR L1 L3 ; Mask in opcode extension bit (ELS/THN)  


   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
   ; Continued

       SHL L5 4 
       IOR L5 L4 
       SHL L5 8 
       IOR L5 L1 
 
       ADD A1 L6 ; Skip branch offset token 
    L2 ADD A2 A3 
       GET A3 +1 
       JSR L2 L5 :: WRCODE 
 
 @DONE RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
Handler function for register type opcodes. 
 
 @H_REGS 
 
    L6 SET :: TYS_tokensize 
 
    A4 GTL 19 
    DR THN >0     ; Branch if missing L (20 or 21) 
    L4 LOD A1 +3  ; L operand 
       ADD A1 L6 
 @0 
    L5 LOD A1 +3  ; Base opcode 
       ADD A1 L6 
    L1 LOD A1 +3  ; R2 operand 
 
    A4 LTL 20 
    DR THN >1     ; Branch if pattern has an L operand 
    L4 GET L1     ; Set missing L to R2 operand 
 @1 
       ADD A1 L6 
    L7 LOD A1 +3  ; L7 now has R1 register or table selector   


  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         

  ; Continued


    A4 EQL 19     ; This handles masking for AND/IOR/EOR 
    DR ELS >@     ; Stay if full masked 
    A4 EQL 21 
    DR ELS >@     ; Stay if missing L masked 
    L7 GET A1 
       JSR L7 L7 :: TYS_MIXED ; L7 now R1 operand (literal or def'd value) 
 
  @@   SHL L5 4 
       IOR L5 L4 
       SHL L5 4 
       IOR L5 L1 
       SHL L5 4 
       IOR L5 L7 
 
    L2 SET :: ASM_BLKASM 
    L3 GET L2 -1 
    L4 STO L3 ; Update LHS op 
 
    L2 ADD A2 A3 
       GET A3 +1 
       JSR L2 L5 :: WRCODE 
 
 @DONE RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
Handler function for nybble opcodes. 
 
 @H_EXT_2REG 
 
    L6 SET :: TYS_tokensize 
    L4 LOD A1 +3 ; L operand 
       ADD A1 L6 
 
    L5 LOD A1 +3 ; Base opcode 
    L3 GET L6 -2 ; Pick 2nd from last (see IF_DICT) 
    L2 ADD A1 L3 
    L7 LOD L2 0  ; ZOP switch code 
   ; DR INT 8 
   ;    IOR L7 DR  ; Set high bit 
       ADD A1 L6 
 
    L1 GET L4    ; Assume missing R1 operand, set R1 equal L 
    A4 EQL 31 
    DR THN >A 
 
    L1 LOD A1 +3 ; R1 operand 
       ADD A1 L6 

    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

  ; Continued


    @A SHL L5 4 
       IOR L5 L4 
       SHL L5 4 
       IOR L5 L7 
       SHL L5 4 
       IOR L5 L1 
 
    L2 SET :: ASM_BLKASM 
    L3 GET L2 -1 
    L4 STO L3 ; Update LHS op 
 
    L2 ADD A2 A3 
       GET A3 +1 
       JSR L2 L5 :: WRCODE 
 
 @DONE RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
Handler function for SOP mapped opcodes. 
 
 @H_CPU_MAP 
 
    L6 SET :: TYS_tokensize 
    L4 LOD A1 +3 ; L operand 
       ADD A1 L6 
    L5 LOD A1 +3 ; Base opcode 
    L3 GET L6 -1 ; Point to final char pos of name field 
    L2 ADD A1 L3 
    L1 LOD L2 0  ; SOP code 
       ADD A1 L6 ; Now points to next token 
 
    L2 SET :: 127 ; Force 7 bit range 
       AND L1 L2 
    L2 SET :: 80h 
       IOR L1 L2  ; Set R2_MSB 
 
       SHL L5 4 
       IOR L5 L4 
       SHL L5 8 
       IOR L5 L1 
 
    L2 ADD A2 A3 
       GET A3 +1 
       JSR L2 L5 :: WRCODE 
 
 @DONE RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             

Handler function for ZOP ZOP opcodes. 
 
 @H_EXT_SIG 
 
    L6 SET :: TYS_tokensize 
    L5 LOD A1 +3 ; Base opcode 
    L3 GET L6 -1 ; Point to penultimate char pos of name field 
    L2 ADD A1 L3 
    L1 LOD L2    ; switch code, for example ZOP, CP_INC 
       ADD A1 L6 ; Now points to next token 
 
    L4 SET :: dop_SIG ; Assume ZOP handler is ZOP 
    A4 EQL 26 
    DR ELS >A ; Branch if not "ZOP xyz" 
 
    L1 GET A1                 ; Ignore previous L1 
       JSR L1 L1 :: TYS_MIXED ; (literal or def'd value) 
       ADD A1 L6              ; Skip to next token    

    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            

  ; Continued


 @A L7 SHR L1 4 ; R2_LOR 
    DR INT Fh 
       AND L1 DR ; R1 
 
       SHL L5 4 
       IOR L5 L7 
       SHL L5 4 
       IOR L5 L4 
       SHL L5 4 
       IOR L5 L1 
 
    L2 ADD A2 A3 
       GET A3 +1 
       JSR L2 L5 :: WRCODE 
 
 @DONE RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
Handler function for ZOP BRA opcode. 
 
 @TEMP 0
 @H_EXT_BRA 
 
    L6 SET :: TYS_tokensize 
    L5 LOD A1 +3 ; Base opcode 
    L3 GET L6 -2 ; Point to penultimate char pos of name field 
    L2 ADD A1 L3 
    L3 LOD L2 1  ; L3 now opcode extension bit (See IF_DICT) 
    L4 LOD L2 0  ; L4 now ZOP switch code (R2) 
       ADD A1 L6 ; Now points to branch offset token 
 
    L2 GET A1 
    L1 GET A2 
    L7 GET A3 
    L3 PER :: <TEMP     ; Push L3 (no more spare registers) 
       JSR L2 L1 L7 L3  ; E best absolute displacement 
       NEAREST    

    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
    ; Continued


    L1 LOD A1 +1 ; Subtype (1: Backward / 2: Forward) 
    L1 EQL 1 
        DR ELS >FWD 
        L3 SET :: FFFFh 
           EOR E L3 
           GET E +1 ; Negated distance 
       @FWD 
    L1 GET E 
    L2 SET :: 255 ; Force 8 bit range 
       AND L1 L2 
    L3 REF :: <TEMP


   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     

  ; Continued

 
       SHL L5 4   ; First the ocpode 
    DR SHR L1 4   ; Now L (high nybl of branch offset) 
       IOR L5 DR 
       SHL L5 4 
       IOR L5 L4  ; Now the ZOP switch code (dop_BRA) 
       IOR L5 L3  ; Mask in opcode extension bit (set/8 in this case) 
       SHL L5 4 
    L2 INT Fh   ; Now R1 (low order nybl of branch offs) 
       AND L1 L2 
       IOR L5 L1 
 
       ADD A1 L6 ; Skip branch offset token 
    L2 ADD A2 A3 
       GET A3 +1 
       JSR L2 L5 :: WRCODE 
 
 @DONE RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
Handler function for byte opcodes. 
 
 @H_BYTE 
 
    L6 SET :: TYS_tokensize 
 
    L4 LOD A1 +3 ; L operand 
       ADD A1 L6 
    L5 LOD A1 +3 ; Base opcode 
    L3 GET L6 -1 
    L3 ADD A1 L3 
       LOD L3 0  ; L3 now opcode extension bit 
       ADD A1 L6 
 
    L7 GET A1 
       JSR L7 L7 :: TYS_MIXED ; L7 now R2 operand (literal or def'd value) 
       ADD A1 L6 
     


  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
  ; Continued


 @@ L2 SET :: FFh 
       AND L7 L2 ; Sanitize R2 operand, clear bit 8 onwards 
       IOR L7 L3 ; Mask in opcode extension bit 
       SHL L5 4 
       IOR L5 L4 
       SHL L5 8 
       IOR L5 L7 
 
    L2 SET :: ASM_BLKASM 
    L3 GET L2 -1 
    L4 STO L3 ; Update LHS op 
 
    L2 ADD A2 A3 
       GET A3 +1 
       JSR L2 L5 :: WRCODE 
 
 @DONE RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             

Handler function for nybble opcodes. 
 
 @H_NYBBLE 
 
    L6 SET :: TYS_tokensize 
    L7 INT 0 ; Default value for R1 operand = 0 
 
    A4 EQL 14 
    DR THN >0    ; Branch if pattern missing L operand (14) 
    A4 EQL 16 
    DR THN >0    ; Branch if pattern missing L and R1 (16) 
 
    L4 LOD A1 +3 ; L operand 
       ADD A1 L6  


   ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
  ; Continued
 
 @0 
    L5 LOD A1 +3 ; Base opcode 
    L3 GET L6 -1 
    L3 ADD A1 L3 
       LOD L3 0  ; L3 now opcode extension bit 
       ADD A1 L6 
    L1 LOD A1 +3 ; R1 operand 
 
    A4 EQL 13 
    DR THN >1    ; Branch if full operands (13) 
    A4 EQL 15 
    DR THN >1    ; Branch if only R2 missing (15) 
 
    L4 GET L1    ; Set missing L to R1 operand 
 
 @1 
       ADD A1 L6 
    A4 GTL 14 
    DR THN >COMMON ; Pattern missing R2 (15) or missing L and R2 (16) 
    L7 GET A1 
       JSR L7 L7 :: TYS_MIXED ; L7 now R2 operand (literal or def'd value) 
       ADD A1 L6     


    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  ; Continued 

 @COMMON 
    L5 EQL 7 ; A bit-shift opcode 
    DR ELS >@ 
       GET L7 -1 ; SHL/SHR 8 (invalid) > SHL 7, SHL/SHR 1 > SHL/SHR 0 
 
 @@ L2 INT 15 
       AND L7 L2 ; Sanitize R2 to 4-bit range 
    L5 EQL Ah    ; Opcode GET, keep R2_MSB as sign bit 
    DR THN >2 
    L2 INT 7 
       AND L7 L2 ; Sanitize R2 to 3-bit range 
       IOR L7 L3 ; Mask in opcode extension bit 
 
 @2    SHL L5 4 
       IOR L5 L4 
       SHL L5 4 
       IOR L5 L7 
       SHL L5 4 
       IOR L5 L1


 ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              

 ; Continued

 
    L2 SET :: ASM_BLKASM 
    L3 GET L2 -1 
    L4 STO L3 ; Update LHS op 
 
    L2 ADD A2 A3 
       GET A3 +1 
       JSR L2 L5 :: WRCODE 
 
 @DONE RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
Pattern handler function for "JSR L6 L6 L6 L6" type instructions. 
 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
 
E OUT Leave error code in E 
 
    @H_PATT09 
    L6 GET A1 
    L1 INT 0      ; L1 Error code, L2 and L3 scratch 
 
    ; The JSR instruction is odd. The first token has the opcode. 
    ; The remaining 0-3 tokens are L-register selectors. 
 
        L2 INT 1 
        L3 INT 3 
           JSR L6 L2 L3    ; E has A1 selector 
           TYS_INFO 
 
        L2 INT 8 
        L7 SET :: FFFFh 
           EOR L2 L7 
           AND E L2        ; Clear bit 3 
           SHL E 1         ; One bit will come in from A2 selector 
        L7 GET E  


 ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            


    ; Continued
 
        ; Get A2 selector 
 
        L2 INT 2 
        L3 INT 3 
           JSR L6 L2 L3    ; E has A2 selector 
           TYS_INFO 
 
        L2 INT 8 
        L5 SET :: FFFFh 
           EOR L2 L5 
           AND E L2        ; Clear bit 3 
        L5 GET E 
 
        ; Fiddle 
 
        L2 INT 4           ; Bit mask selecting bit 2 
           AND E L2        ; Check if bit 2 set 
         E ELS >1 
           GET L7 +1       ; Set bit 0 of slot 0 value 
        L3 SET :: FFFFh 
           EOR L2 L3       ; Invert mask 
           AND L5 L2       ; Clear bit 2 in L5   


    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

  ; Continued


        @1 
         ;  SHL L7 4       ; Shift this value left 4 bits 
        L2 GET L7 
        L7 LOD L6 +3       ; Get opcode 
           SHL L7 4 
           IOR L7 L2 
           SHL L7 2        ; Shift only by 2 as 2 bits of L5 remaining 
           IOR L7 L5 
 
        ; Get A3 selector 
 
        L2 INT 3 
        L3 INT 3 
           JSR L6 L2 L3    ; E has A3 selector 
           TYS_INFO 
 
        L2 INT 8 
        L5 SET :: FFFFh 
           EOR L2 L5 
           AND E L2        ; Clear bit 3 
        L5 GET E 


  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            


  ; Continued

        ; Get A4 selector 
 
        L2 INT 4 
        L3 INT 3 
           JSR L6 L2 L3    ; E has A4 selector 
           TYS_INFO 
 
        L2 INT 8 
        L4 SET :: FFFFh 
           EOR L2 L4 
           AND E L2        ; Clear bit 3 
        L4 GET E 
 
        ; Fiddle 
 
           SHL L7 3        ; Shift left 3 bits for slot 2 
           IOR L7 L5 
           SHL L7 3        ; Shift left 3 bits for slot 3 
           IOR L7 L4


 ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

  ; Continued

 
    L2 ADD A2 A3  ; Store instruction 
       GET A3 +1  ; Advance object code ptr 
     JSR L2 L7 :: WRCODE 
 
    L2 INT 5      ; Skip tokens matched 
       JSR L6 L2 
       TYS_SKIP 
 
     E GET L1     ; Error code 
    A1 GET L6     ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
Pattern handler function for "JSR L6 L6 L6" type instructions. 
 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
 
E OUT Leave error code in E 
 
    @H_PATT08 
    L6 GET A1 
    L1 INT 0      ; L1 Error code, L2 and L3 scratch 
 
    ; The JSR instruction is odd. The first token has the opcode. 
    ; The remaining 0-3 tokens are L-register selectors. 
 
        L2 INT 1 
        L3 INT 3 
           JSR L6 L2 L3    ; E has A1 selector 
           TYS_INFO    


  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

  ; Continued

        L2 INT 8 
        L7 SET :: FFFFh 
           EOR L2 L7 
           AND E L2        ; Clear bit 3 
           SHL E 1         ; One bit will come in from A2 selector 
        L7 GET E 
 
        ; Get A2 selector 
 
        L2 INT 2 
        L3 INT 3 
           JSR L6 L2 L3     ; E has A2 selector 
           TYS_INFO 
 
        L2 INT 8 
        L5 SET :: FFFFh 
           EOR L2 L5 
           AND E L2        ; Clear bit 3 
        L5 GET E


 ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        


    ; Continued
 
        ; Fiddle 
 
        L2 INT 4           ; Bit mask selecting bit 2 
           AND E L2        ; Check if bit 2 set 
         E ELS >1 
           GET L7 +1       ; Set bit 0 of slot 0 value 
        DR SET :: FFFFh 
        L2 EOR DR L2      ; Invert mask 
           AND L5 L2       ; Clear bit 2 in L5 
 
        @1 
          ; SHL L7 4       ; Shift this value left 4 bits 
        L2 GET L7 
        L7 LOD L6 +3       ; Get opcode 
           SHL L7 4 
           IOR L7 L2 
           SHL L7 2        ; Shift only by 2 as 2 bits of L5 remaining 
           IOR L7 L5 

    ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
  ; Continued

 
        ; Get A3 selector 
 
        L2 INT 3 
        L3 INT 3 
           JSR L6 L2 L3    ; E has A3 selector 
           TYS_INFO 
 
        L2 INT 8 
        DR SET :: FFFFh 
        L2 EOR DR L2 
           AND E L2        ; Clear bit 3 
        L5 GET E 
 
        ; Fiddle 
 
           SHL L7 3        ; Shift left 3 bits for slot 2 
           IOR L7 L5 
           SHL L7 3        ; Shift left 3 bits for slot 2 (slot 3 0)  


  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
    ; Continued


    L2 ADD A2 A3      ; Store instruction 
       JSR L2 L7 :: WRCODE 
       GET A3 +1 
 
    L2 INT 4          ; Skip tokens matched 
       JSR L6 L2 
       TYS_SKIP 
 
     E GET L1         ; Error code 
    A1 GET L6         ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
Pattern handler function for "JSR L6 L6" type instructions. 
 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
 
E OUT Leave error code in E 
 
    @H_PATT07 
    L6 GET A1 
    L1 INT 0   ; L1 Error code, L2 and L3 scratch 
 
    ; The JSR instruction is odd. The first token has the opcode. 
    ; The remaining 0-3 tokens are L-register selectors. 
 
        L2 INT 1 
        L3 INT 3 
           JSR L6 L2 L3    ; E has A1 selector 
           TYS_INFO 
 
        L2 INT 8 
        DR SET :: FFFFh 
        L2 EOR DR L2 
           AND E L2        ; Clear bit 3 
           SHL E 1         ; One bit will come in from A2 selector 
        L7 GET E   

  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      

 ; Continued

        L2 INT 2 
        L3 INT 3 
           JSR L6 L2 L3    ; E has A2 selector 
           TYS_INFO 
 
        L2 INT 8 
        DR SET :: FFFFh 
        L2 EOR DR L2 
           AND E L2        ; Clear bit 3 
        L5 GET E 
 
        L2 INT 4           ; Bit mask selecting bit 2 
           AND E L2        ; Check if bit 2 set 
         E ELS >1 
           GET L7 +1       ; Set bit 0 of slot 0 value 
        DR SET :: FFFFh 
        L2 EOR DR L2        ; Invert mask 
           AND L5 L2       ; Clear bit 2 in L5 


 ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
   ; Continued


        @1 
          ; SHL L7 4        ; Shift this value left 4 bits 
        L2 GET L7 
        L7 LOD L6 +3       ; Get opcode 
           SHL L7 4 
           IOR L7 L2 
           SHL L7 2        ; Shift only by 2 as 2 bits of L5 remaining 
           IOR L7 L5 
           SHL L7 6        ; Shift left 6 bits (slot 2 and 3 0) 
 
 
    L2 ADD A2 A3      ; Store instruction 
       JSR L2 L7 :: WRCODE 
       GET A3 +1 
 
    L2 INT 3          ; Skip tokens matched 
       JSR L6 L2 
       TYS_SKIP 
 
     E GET L1         ; Error code 
    A1 GET L6         ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
Pattern handler function for "JSR L6" type instructions. 
 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
 
E OUT Leave error code in E 
 
    @H_PATT06 
    L6 GET A1 
    L1 INT 0      ; L1 Error code, L2 and L3 scratch 
 
    ; The JSR instruction is odd. The first token has the opcode. 
    ; The remaining 0-3 tokens are L-register selectors. 
 
        L7 LOD L6 +3       ; Get Opcode 
           SHL L7 4 
 
        L2 INT 1 
        L3 INT 3 
           JSR L6 L2 L3    ; E has A1 selector 
           TYS_INFO  


 ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        


  ; Continued


 
        L2 INT 8 
        DR SET :: FFFFh 
        L2 EOR DR L2 
           AND E L2        ; Clear bit 3 
           SHL E 1 
        L7 IOR E L7 
           SHL L7 8 
 
    L2 ADD A2 A3      ; Store instruction 
       JSR L2 L7 :: WRCODE 
       GET A3 +1 
 
    L2 INT 2          ; Skip tokens matched 
       JSR L6 L2 
       TYS_SKIP 
 
     E GET L1         ; Error code 
    A1 GET L6         ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
Pattern handler function for the "JSR" instruction. 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
E OUT Leave error code in E 
 
    @H_PATT05 
    L6 GET A1 
    L1 INT 0            ; L1 Error code, L2 and L3 scratch 
 
    ; The JSR instruction is odd. The first token has the opcode. 
    ; The remaining 0-3 tokens are L-register selectors. 
 
    L7 LOD L6 +3        ; Opcode, remaining slots 0 
       SHL L7 8 
       SHL L7 4 
 
    L1 ADD A2 A3 
    JSR L1 L7 :: WRCODE 
       GET A3 +1        ; Advance object code ptr 
 
    L2 INT 1            ; Skip tokens matched 
       JSR L6 L2 
       TYS_SKIP 
 
     E GET L1           ; Error code 
    A1 GET L6           ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
Pattern handler function. This handler resolves WORDs and writes 
the values/addresses into the object stream. 
 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update� 
A3 IN Effective, update 
 
E OUT Leave error code in E 
 
    @H_WORD 
    L6 GET A1 
 
    JSR L6 L5 :: GETSYMBOL      ; Should this be nearest? Local DEFs ?
    LOD L5 +3 
 
       L7 ADD A2 A3    ; Place the DEF and advance obj code ptr 
          JSR L7 L5 :: WRCODE 
          GET A3 +1 
 
    L2 INT 1      ; Advance 1 token (skip DEF label) 
    JSR L6 L2 
    TYS_SKIP 
 
     E INT 0      ; Return value 
    A1 GET L6     ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
Pattern handler function. This handler writes DEF definitions into the 
symbol table. 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
E OUT Leave error code in E 
 
    @H_DEF 
    L6 GET A1 
 
        L2 INT 1          ; From word arg 
        L3 INT 0          ; Symbol 
           JSR L6 L2 L3   ; L2 pointer to word token 
           TYS_INFO 
 
        L4 INT 2          ; From number arg 
        L3 INT 3          ; Index 
           JSR L6 L4 L3 
           TYS_INFO          ; Continue                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

 ; Continued


        E STO L2 +3       ; Store index value in word token 
        E INT 2 
        E STO L2 +2       ; Set group 2 (same as NUM) 
 
           JSR L2 
           <NEWSYMBOL     ; Copy token into symbol table 
 
        L2 INT 3          ; Advance by 3 tokens (DEF Mixed 20) 
           JSR L6 L2 
           TYS_SKIP 
 
     E INT 0              ; Return value 
    A1 GET L6             ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

Pattern handler function. This handler places isolated resolved references 
into the obj code.

A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
E OUT Leave error code in E 
 
    @H_REF 
    L6 GET A1 
    L1 GET A2 
    L2 GET A3 
 
       JSR L6 L1 L2 L4   ; E best abs displ 
       NEAREST 
 
    L3 LOD L4 +3 
    L7 ADD A2 A3 
       JSR L7 L3 :: WRCODE 
       GET A3 +1 
 
    L2 INT 1             ; Advance to next token 
    JSR L6 L2 
    TYS_SKIP 
 
     E INT 0             ; Return value 
    A1 GET L6            ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
    @H_REL  

    L6 GET A1  
    L1 GET A2  
    L2 GET A3  
       JSR L6 L1 L2 L4 :: NEAREST   ; E best abs displ  
  
    L1 LOD A1 +1 ; Subtype (1: Backward / 2: Forward)  
    L1 EQL 1  
    DR ELS >FWD  
    L3 SET :: FFFFh  
       EOR E L3  
       GET E +1 ; Negated distance  

    @FWD   
    L3 GET E
    L3 SET :: 1234h   
     ; L3 LOD L4 +3  
    L7 ADD A2 A3  
       JSR L7 L3 :: WRCODE  
       GET A3 +1  
  
    L2 INT 1             ; Advance to next token  
       JSR L6 L2  
       TYS_SKIP  
  
     E INT 0             ; Return value  
    A1 GET L6            ; Bubble  
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
Assembler pattern handler for label tokens (@ and $ prefix).
 
  @H_LABEL 
    L6 GET A1           ; A1 points to current token structure
    DR LOD L6 +0        ; Type 6=Label
    DR EQL 6
    DR ELS >1
    DR LOD L6 +1        ; Subtype 0=@, 1=$
    DR ELS >1
       BRA >1
       
       JSR L6 DR :: GETSYMBOL ; D will point to symbol entry
     E ELS >1                ; If not found
     
     E LOD L6 +0
     E STO DR +0         ; Force to be label (symbol could be anything)
     E INT 1
     E STO DR +1         ; Force correct subtype
     E LOD L6 +2
     E STO DR +2         ; Copy group
    A3 STO DR +3         ; Update index field with current asm addr
        BRA >2

 @1 A3 STO L6 +3         ; A3 current asm addr, store in index field
    JSR L6 :: NEWSYMBOL
 
 @2 L2 INT TYS_tokensize
       ADD A1 L2 ; Advance by 1 token
     E INT 0 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
Pattern handler function. This handler places isolated numbers into obj code. 
 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
 
E OUT Leave error code in E 
 
    @H_NUMBER 
    L1 GET A1 
 
    L3 LOD L1 +3 
    L7 ADD A2 A3 
       JSR L7 L3 :: WRCODE 
       GET A3 +1 
 
    L2 INT 1          ; Advance to next token 
    JSR L1 L2 
    TYS_SKIP 
 
     E INT 0          ; Return value 
    A1 GET L1         ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
Pattern handler function for "::" pattern breaker. Advance to next token. 
 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
 
E OUT Leave error code in E 
 
    @H_BREAK 
 
    L1 GET A1 
 
    L2 INT 1          ; Advance to next token 
       JSR L1 L2 
       TYS_SKIP 
 
     E INT 0          ; Return value 
    A1 GET L1         ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
Pattern handler function. This handler is called when a token of type is 
matched. In this case, EVALUATE/IF_STRING has already populated the token with
the entire string, and the present function copies it into the object code.

A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
E OUT Leave error code in E 
 
    @H_STRING 
 
    L1 GET A1 
 
    @COPY 
    L4 LOD A1 +4 
    L3 ADD A2 A3 
       GET A1 +1 
    L4 ELS >1 
       JSR L3 L4 :: WRCODE 
       GET A3 +1 
       BRA <COPY 
 
 @1 L2 INT 1          ; Advance to next token 
       JSR L1 L2 
       TYS_SKIP 
 
     E INT 0          ; Return value 
    A1 GET L1         ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
 Pattern handler function for ORG directive. 
A1 IN Pointer to token, handler must update! 
A2 IN Base, update 
A3 IN Effective, update 
E OUT Leave error code in E 
 
    @H_ORG 
    L6 GET A1 
    L2 INT 1 
    L3 INT 3 
      JSR L6 L2 L3    ; E has ORG address 
       TYS_INFO 
    L7 GET E 
    DR REF :: ASMMODE ; For memory target, just set A3 to ORG addr
    DR ELS >1
    A3 GET E
       BRA >2  
 
  @1  L5 GET E ; Is a dummy value effectively
      L4 INT 0 
         JSR L5 L4 :: WRCODE ; Padd object code with zeros to ORG address 
         GET A3 +1 
      L4 SUB L7 A3 
      L4 THN <1 
 
 @2  L2 INT 2          ; Advance to next token 
        JSR L6 L2 :: TYS_SKIP
     E INT 0          ; Return value 
    A1 GET L6         ; Bubble 
       RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
The next portion starts at E000h again, but represents a different overlay. 
 
=== OVERLAY BANK 1 ============================================================ 
 
   BANK      ; Pad to 8K OVERLAY base address 1  (10000h) 
 
Multiplication tables 12 values 
 
 @MUL3   0003h 0006h 0009h 000Ch 000Fh 0012h 0015h 0018h 001Bh 001Eh 0021h 
 @MUL5   0005h 000Ah 000Fh 0014h 0019h 001Eh 0023h 0028h 002Dh 0032h 0037h 
 @MUL6   0006h 000Ch 0012h 0018h 001Eh 0024h 002Ah 0030h 0036h 003Ch 0042h 
 @MUL7   0007h 000Eh 0015h 001Ch 0023h 002Ah 0031h 0038h 003Fh 0046h 004Dh 
 @MUL9   0009h 0012h 001Bh 0024h 002Dh 0036h 003Fh 0048h 0051h 005Ah 0063h 
 @MUL10  000Ah 0014h 001Eh 0028h 0032h 003Ch 0046h 0050h 005Ah 0064h 006Eh                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    


Sine data 0-90 degrees, 2048 16-bit samples 
 
 @SINELUT 
 
 0000h 0032h 0064h 0096h 00C9h 00FBh 012Dh 015Fh 0192h 01C4h 01F6h 0228h 025Bh 
 028Dh 02BFh 02F1h 0324h 0356h 0388h 03BAh 03EDh 041Fh 0451h 0484h 04B6h 04E8h 
 051Ah 054Dh 057Fh 05B1h 05E3h 0616h 0648h 067Ah 06ACh 06DFh 0711h 0743h 0775h 
 07A8h 07DAh 080Ch 083Eh 0870h 08A3h 08D5h 0907h 0939h 096Ch 099Eh 09D0h 0A02h 
 0A35h 0A67h 0A99h 0ACBh 0AFDh 0B30h 0B62h 0B94h 0BC6h 0BF9h 0C2Bh 0C5Dh 0C8Fh 
 0CC1h 0CF4h 0D26h 0D58h 0D8Ah 0DBCh 0DEFh 0E21h 0E53h 0E85h 0EB7h 0EE9h 0F1Ch 
 0F4Eh 0F80h 0FB2h 0FE4h 1016h 1049h 107Bh 10ADh 10DFh 1111h 1143h 1176h 11A8h 
 11DAh 120Ch 123Eh 1270h 12A2h 12D5h 1307h 1339h 136Bh 139Dh 13CFh 1401h 1433h 
 1465h 1498h 14CAh 14FCh 152Eh 1560h 1592h 15C4h 15F6h 1628h 165Ah 168Ch 16BFh 
 16F1h 1723h 1755h 1787h 17B9h 17EBh 181Dh 184Fh 1881h 18B3h 18E5h 1917h 1949h 
 197Bh 19ADh 19DFh 1A11h 1A43h 1A75h 1AA7h 1AD9h 1B0Bh 1B3Dh 1B6Fh 1BA1h 1BD3h 
 1C05h 1C37h 1C69h 1C9Bh 1CCDh 1CFFh 1D31h 1D63h 1D95h 1DC6h 1DF8h 1E2Ah 1E5Ch 
 1E8Eh 1EC0h 1EF2h 1F24h 1F56h 1F88h 1FB9h 1FEBh 201Dh 204Fh 2081h 20B3h 20E5h 
 2116h 2148h 217Ah 21ACh 21DEh 2210h 2241h 2273h 22A5h 22D7h 2309h 233Ah 236Ch 
 239Eh 23D0h 2402h 2433h 2465h 2497h 24C9h 24FAh 252Ch 255Eh 258Fh 25C1h 25F3h 
 2625h 2656h 2688h 26BAh 26EBh 271Dh 274Fh 2780h 27B2h 27E4h 2815h 2847h 2879h 
 28AAh 28DCh 290Eh 293Fh 2971h 29A2h 29D4h 2A06h 2A37h 2A69h 2A9Ah 2ACCh 2AFDh 
 2B2Fh 2B60h 2B92h 2BC3h 2BF5h 2C27h 2C58h 2C8Ah 2CBBh 2CEDh 2D1Eh 2D4Fh 2D81h 
 2DB2h 2DE4h 2E15h 2E47h 2E78h 2EAAh 2EDBh 2F0Ch 2F3Eh 2F6Fh 2FA1h 2FD2h 3003h 
 3035h 3066h 3097h 30C9h 30FAh 312Bh 315Dh 318Eh 31BFh 31F1h 3222h 3253h 3285h                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

 32B6h 32E7h 3318h 334Ah 337Bh 33ACh 33DDh 340Fh 3440h 3471h 34A2h 34D3h 3505h 
 3536h 3567h 3598h 35C9h 35FAh 362Bh 365Dh 368Eh 36BFh 36F0h 3721h 3752h 3783h 
 37B4h 37E5h 3816h 3847h 3878h 38A9h 38DAh 390Bh 393Ch 396Dh 399Eh 39CFh 3A00h 
 3A31h 3A62h 3A93h 3AC4h 3AF5h 3B26h 3B57h 3B88h 3BB9h 3BE9h 3C1Ah 3C4Bh 3C7Ch 
 3CADh 3CDEh 3D0Eh 3D3Fh 3D70h 3DA1h 3DD2h 3E02h 3E33h 3E64h 3E95h 3EC5h 3EF6h 
 3F27h 3F58h 3F88h 3FB9h 3FEAh 401Ah 404Bh 407Ch 40ACh 40DDh 410Eh 413Eh 416Fh 
 419Fh 41D0h 4200h 4231h 4262h 4292h 42C3h 42F3h 4324h 4354h 4385h 43B5h 43E6h 
 4416h 4447h 4477h 44A7h 44D8h 4508h 4539h 4569h 4599h 45CAh 45FAh 462Ah 465Bh 
 468Bh 46BBh 46ECh 471Ch 474Ch 477Dh 47ADh 47DDh 480Dh 483Eh 486Eh 489Eh 48CEh 
 48FEh 492Fh 495Fh 498Fh 49BFh 49EFh 4A1Fh 4A4Fh 4A7Fh 4AAFh 4AE0h 4B10h 4B40h 
 4B70h 4BA0h 4BD0h 4C00h 4C30h 4C60h 4C90h 4CC0h 4CF0h 4D20h 4D4Fh 4D7Fh 4DAFh 
 4DDFh 4E0Fh 4E3Fh 4E6Fh 4E9Fh 4ECEh 4EFEh 4F2Eh 4F5Eh 4F8Eh 4FBDh 4FEDh 501Dh 
 504Dh 507Ch 50ACh 50DCh 510Bh 513Bh 516Bh 519Ah 51CAh 51FAh 5229h 5259h 5288h 
 52B8h 52E8h 5317h 5347h 5376h 53A6h 53D5h 5405h 5434h 5464h 5493h 54C3h 54F2h 
 5521h 5551h 5580h 55B0h 55DFh 560Eh 563Eh 566Dh 569Ch 56CBh 56FBh 572Ah 5759h 
 5789h 57B8h 57E7h 5816h 5845h 5875h 58A4h 58D3h 5902h 5931h 5960h 598Fh 59BEh 
 59EDh 5A1Dh 5A4Ch 5A7Bh 5AAAh 5AD9h 5B08h 5B37h 5B66h 5B94h 5BC3h 5BF2h 5C21h 
 5C50h 5C7Fh 5CAEh 5CDDh 5D0Ch 5D3Ah 5D69h 5D98h 5DC7h 5DF5h 5E24h 5E53h 5E82h 
 5EB0h 5EDFh 5F0Eh 5F3Ch 5F6Bh 5F9Ah 5FC8h 5FF7h 6026h 6054h 6083h 60B1h 60E0h 
 610Eh 613Dh 616Bh 619Ah 61C8h 61F7h 6225h 6254h 6282h 62B0h 62DFh 630Dh 633Bh 
 636Ah 6398h 63C6h 63F5h 6423h 6451h 647Fh 64AEh 64DCh 650Ah 6538h 6566h 6594h 
 65C3h 65F1h 661Fh 664Dh 667Bh 66A9h 66D7h 6705h 6733h 6761h 678Fh 67BDh 67EBh 
 6819h 6847h 6875h 68A3h 68D0h 68FEh 692Ch 695Ah 6988h 69B6h 69E3h 6A11h 6A3Fh                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
 
 6A6Dh 6A9Ah 6AC8h 6AF6h 6B23h 6B51h 6B7Fh 6BACh 6BDAh 6C07h 6C35h 6C62h 6C90h 
 6CBDh 6CEBh 6D18h 6D46h 6D73h 6DA1h 6DCEh 6DFCh 6E29h 6E56h 6E84h 6EB1h 6EDEh 
 6F0Ch 6F39h 6F66h 6F93h 6FC1h 6FEEh 701Bh 7048h 7075h 70A3h 70D0h 70FDh 712Ah 
 7157h 7184h 71B1h 71DEh 720Bh 7238h 7265h 7292h 72BFh 72ECh 7319h 7346h 7373h 
 739Fh 73CCh 73F9h 7426h 7453h 747Fh 74ACh 74D9h 7506h 7532h 755Fh 758Ch 75B8h 
 75E5h 7612h 763Eh 766Bh 7697h 76C4h 76F0h 771Dh 7749h 7776h 77A2h 77CFh 77FBh 
 7827h 7854h 7880h 78ACh 78D9h 7905h 7931h 795Eh 798Ah 79B6h 79E2h 7A0Fh 7A3Bh 
 7A67h 7A93h 7ABFh 7AEBh 7B17h 7B43h 7B6Fh 7B9Bh 7BC7h 7BF3h 7C1Fh 7C4Bh 7C77h 
 7CA3h 7CCFh 7CFBh 7D27h 7D53h 7D7Eh 7DAAh 7DD6h 7E02h 7E2Eh 7E59h 7E85h 7EB1h 
 7EDCh 7F08h 7F34h 7F5Fh 7F8Bh 7FB6h 7FE2h 800Eh 8039h 8065h 8090h 80BBh 80E7h 
 8112h 813Eh 8169h 8194h 81C0h 81EBh 8216h 8242h 826Dh 8298h 82C3h 82EFh 831Ah 
 8345h 8370h 839Bh 83C6h 83F1h 841Ch 8448h 8473h 849Eh 84C9h 84F3h 851Eh 8549h 
 8574h 859Fh 85CAh 85F5h 8620h 864Ah 8675h 86A0h 86CBh 86F5h 8720h 874Bh 8776h 
 87A0h 87CBh 87F5h 8820h 884Bh 8875h 88A0h 88CAh 88F5h 891Fh 8949h 8974h 899Eh 
 89C9h 89F3h 8A1Dh 8A48h 8A72h 8A9Ch 8AC6h 8AF1h 8B1Bh 8B45h 8B6Fh 8B99h 8BC3h 
 8BEEh 8C18h 8C42h 8C6Ch 8C96h 8CC0h 8CEAh 8D14h 8D3Eh 8D68h 8D91h 8DBBh 8DE5h 
 8E0Fh 8E39h 8E63h 8E8Ch 8EB6h 8EE0h 8F09h 8F33h 8F5Dh 8F86h 8FB0h 8FDAh 9003h 
 902Dh 9056h 9080h 90A9h 90D3h 90FCh 9126h 914Fh 9178h 91A2h 91CBh 91F4h 921Eh 
 9247h 9270h 9299h 92C3h 92ECh 9315h 933Eh 9367h 9390h 93B9h 93E2h 940Bh 9434h 
 945Dh 9486h 94AFh 94D8h 9501h 952Ah 9553h 957Bh 95A4h 95CDh 95F6h 961Eh 9647h 
 9670h 9699h 96C1h 96EAh 9712h 973Bh 9763h 978Ch 97B5h 97DDh 9805h 982Eh 9856h 
 987Fh 98A7h 98CFh 98F8h 9920h 9948h 9970h 9999h 99C1h 99E9h 9A11h 9A39h 9A61h 
 9A8Ah 9AB2h 9ADAh 9B02h 9B2Ah 9B52h 9B7Ah 9BA1h 9BC9h 9BF1h 9C19h 9C41h 9C69h 
 9C91h 9CB8h 9CE0h 9D08h 9D2Fh 9D57h 9D7Fh 9DA6h 9DCEh 9DF5h 9E1Dh 9E45h 9E6Ch 
 9E94h 9EBBh 9EE2h 9F0Ah 9F31h 9F58h 9F80h 9FA7h 9FCEh 9FF6h A01Dh A044h A06Bh 
 A092h A0BAh A0E1h A108h A12Fh A156h A17Dh A1A4h A1CBh A1F2h A219h A240h A266h                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
 A28Dh A2B4h A2DBh A302h A328h A34Fh A376h A39Dh A3C3h A3EAh A410h A437h A45Eh 
 A484h A4ABh A4D1h A4F7h A51Eh A544h A56Bh A591h A5B7h A5DEh A604h A62Ah A650h 
 A677h A69Dh A6C3h A6E9h A70Fh A735h A75Bh A781h A7A7h A7CDh A7F3h A819h A83Fh 
 A865h A88Bh A8B1h A8D6h A8FCh A922h A948h A96Dh A993h A9B9h A9DEh AA04h AA29h 
 AA4Fh AA74h AA9Ah AABFh AAE5h AB0Ah AB30h AB55h AB7Ah ABA0h ABC5h ABEAh AC0Fh 
 AC35h AC5Ah AC7Fh ACA4h ACC9h ACEEh AD13h AD38h AD5Dh AD82h ADA7h ADCCh ADF1h 
 AE16h AE3Bh AE5Fh AE84h AEA9h AECEh AEF2h AF17h AF3Ch AF60h AF85h AFAAh AFCEh 
 AFF3h B017h B03Ch B060h B085h B0A9h B0CDh B0F2h B116h B13Ah B15Eh B183h B1A7h 
 B1CBh B1EFh B213h B237h B25Ch B280h B2A4h B2C8h B2ECh B30Fh B333h B357h B37Bh 
 B39Fh B3C3h B3E7h B40Ah B42Eh B452h B475h B499h B4BDh B4E0h B504h B527h B54Bh 
 B56Eh B592h B5B5h B5D9h B5FCh B61Fh B643h B666h B689h B6ACh B6CFh B6F3h B716h 
 B739h B75Ch B77Fh B7A2h B7C5h B7E8h B80Bh B82Eh B851h B874h B897h B8B9h B8DCh 
 B8FFh B922h B944h B967h B98Ah B9ACh B9CFh B9F1h BA14h BA36h BA59h BA7Bh BA9Eh 
 BAC0h BAE3h BB05h BB27h BB4Ah BB6Ch BB8Eh BBB0h BBD2h BBF5h BC17h BC39h BC5Bh 
 BC7Dh BC9Fh BCC1h BCE3h BD05h BD26h BD48h BD6Ah BD8Ch BDAEh BDCFh BDF1h BE13h 
 BE35h BE56h BE78h BE99h BEBBh BEDCh BEFEh BF1Fh BF41h BF62h BF84h BFA5h BFC6h 
 BFE7h C009h C02Ah C04Bh C06Ch C08Dh C0AFh C0D0h C0F1h C112h C133h C154h C175h 
 C195h C1B6h C1D7h C1F8h C219h C23Ah C25Ah C27Bh C29Ch C2BCh C2DDh C2FDh C31Eh 
 C33Fh C35Fh C380h C3A0h C3C0h C3E1h C401h C421h C442h C462h C482h C4A2h C4C3h 
 C4E3h C503h C523h C543h C563h C583h C5A3h C5C3h C5E3h C603h C622h C642h C662h 
 C682h C6A2h C6C1h C6E1h C701h C720h C740h C75Fh C77Fh C79Eh C7BEh C7DDh C7FDh 
 C81Ch C83Bh C85Bh C87Ah C899h C8B8h C8D7h C8F7h C916h C935h C954h C973h C992h 
 C9B1h C9D0h C9EFh CA0Eh CA2Ch CA4Bh CA6Ah CA89h CAA8h CAC6h CAE5h CB04h CB22h                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

 CB41h CB5Fh CB7Eh CB9Ch CBBBh CBD9h CBF7h CC16h CC34h CC52h CC71h CC8Fh CCADh 
 CCCBh CCE9h CD08h CD26h CD44h CD62h CD80h CD9Eh CDBCh CDDAh CDF7h CE15h CE33h 
 CE51h CE6Fh CE8Ch CEAAh CEC8h CEE5h CF03h CF20h CF3Eh CF5Bh CF79h CF96h CFB4h 
 CFD1h CFEEh D00Ch D029h D046h D063h D081h D09Eh D0BBh D0D8h D0F5h D112h D12Fh 
 D14Ch D169h D186h D1A3h D1BFh D1DCh D1F9h D216h D232h D24Fh D26Ch D288h D2A5h 
 D2C2h D2DEh D2FBh D317h D333h D350h D36Ch D388h D3A5h D3C1h D3DDh D3F9h D416h 
 D432h D44Eh D46Ah D486h D4A2h D4BEh D4DAh D4F6h D512h D52Dh D549h D565h D581h 
 D59Dh D5B8h D5D4h D5F0h D60Bh D627h D642h D65Eh D679h D695h D6B0h D6CBh D6E7h 
 D702h D71Dh D738h D754h D76Fh D78Ah D7A5h D7C0h D7DBh D7F6h D811h D82Ch D847h 
 D862h D87Dh D898h D8B2h D8CDh D8E8h D902h D91Dh D938h D952h D96Dh D987h D9A2h 
 D9BCh D9D7h D9F1h DA0Bh DA26h DA40h DA5Ah DA74h DA8Fh DAA9h DAC3h DADDh DAF7h 
 DB11h DB2Bh DB45h DB5Fh DB79h DB93h DBADh DBC6h DBE0h DBFAh DC14h DC2Dh DC47h 
 DC60h DC7Ah DC94h DCADh DCC6h DCE0h DCF9h DD13h DD2Ch DD45h DD5Fh DD78h DD91h 
 DDAAh DDC3h DDDCh DDF5h DE0Eh DE27h DE40h DE59h DE72h DE8Bh DEA4h DEBDh DED5h 
 DEEEh DF07h DF1Fh DF38h DF51h DF69h DF82h DF9Ah DFB3h DFCBh DFE4h DFFCh E014h 
 E02Ch E045h E05Dh E075h E08Dh E0A5h E0BEh E0D6h E0EEh E106h E11Eh E135h E14Dh 
 E165h E17Dh E195h E1ACh E1C4h E1DCh E1F4h E20Bh E223h E23Ah E252h E269h E281h 
 E298h E2AFh E2C7h E2DEh E2F5h E30Dh E324h E33Bh E352h E369h E380h E397h E3AEh 
 E3C5h E3DCh E3F3h E40Ah E421h E438h E44Eh E465h E47Ch E492h E4A9h E4C0h E4D6h 
 E4EDh E503h E51Ah E530h E546h E55Dh E573h E589h E59Fh E5B6h E5CCh E5E2h E5F8h 
 E60Eh E624h E63Ah E650h E666h E67Ch E692h E6A8h E6BDh E6D3h E6E9h E6FFh E714h 
 E72Ah E73Fh E755h E76Ah E780h E795h E7ABh E7C0h E7D5h E7EBh E800h E815h E82Ah                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

 E840h E855h E86Ah E87Fh E894h E8A9h E8BEh E8D3h E8E8h E8FCh E911h E926h E93Bh 
 E94Fh E964h E979h E98Dh E9A2h E9B6h E9CBh E9DFh E9F4h EA08h EA1Dh EA31h EA45h 
 EA59h EA6Eh EA82h EA96h EAAAh EABEh EAD2h EAE6h EAFAh EB0Eh EB22h EB36h EB4Ah 
 EB5Dh EB71h EB85h EB99h EBACh EBC0h EBD3h EBE7h EBFAh EC0Eh EC21h EC35h EC48h 
 EC5Bh EC6Fh EC82h EC95h ECA8h ECBBh ECCFh ECE2h ECF5h ED08h ED1Bh ED2Eh ED41h 
 ED53h ED66h ED79h ED8Ch ED9Eh EDB1h EDC4h EDD6h EDE9h EDFCh EE0Eh EE20h EE33h 
 EE45h EE58h EE6Ah EE7Ch EE8Fh EEA1h EEB3h EEC5h EED7h EEE9h EEFBh EF0Dh EF1Fh 
 EF31h EF43h EF55h EF67h EF79h EF8Ah EF9Ch EFAEh EFBFh EFD1h EFE2h EFF4h F006h 
 F017h F028h F03Ah F04Bh F05Ch F06Eh F07Fh F090h F0A1h F0B2h F0C4h F0D5h F0E6h 
 F0F7h F108h F119h F129h F13Ah F14Bh F15Ch F16Dh F17Dh F18Eh F19Fh F1AFh F1C0h 
 F1D0h F1E1h F1F1h F202h F212h F222h F233h F243h F253h F263h F273h F283h F294h 
 F2A4h F2B4h F2C4h F2D3h F2E3h F2F3h F303h F313h F323h F332h F342h F352h F361h 
 F371h F380h F390h F39Fh F3AFh F3BEh F3CDh F3DDh F3ECh F3FBh F40Ah F41Ah F429h 
 F438h F447h F456h F465h F474h F483h F492h F4A0h F4AFh F4BEh F4CDh F4DBh F4EAh 
 F4F9h F507h F516h F524h F533h F541h F54Fh F55Eh F56Ch F57Ah F589h F597h F5A5h 
 F5B3h F5C1h F5CFh F5DDh F5EBh F5F9h F607h F615h F623h F631h F63Eh F64Ch F65Ah 
 F667h F675h F683h F690h F69Eh F6ABh F6B9h F6C6h F6D3h F6E1h F6EEh F6FBh F708h 
 F715h F723h F730h F73Dh F74Ah F757h F764h F771h F77Dh F78Ah F797h F7A4h F7B1h 
 F7BDh F7CAh F7D6h F7E3h F7F0h F7FCh F809h F815h F821h F82Eh F83Ah F846h F852h 
 F85Fh F86Bh F877h F883h F88Fh F89Bh F8A7h F8B3h F8BFh F8CBh F8D7h F8E2h F8EEh 
 F8FAh F905h F911h F91Dh F928h F934h F93Fh F94Bh F956h F961h F96Dh F978h F983h                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

 F98Fh F99Ah F9A5h F9B0h F9BBh F9C6h F9D1h F9DCh F9E7h F9F2h F9FDh FA08h FA12h 
 FA1Dh FA28h FA32h FA3Dh FA48h FA52h FA5Dh FA67h FA72h FA7Ch FA86h FA91h FA9Bh 
 FAA5h FAAFh FAB9h FAC4h FACEh FAD8h FAE2h FAECh FAF6h FB00h FB09h FB13h FB1Dh 
 FB27h FB31h FB3Ah FB44h FB4Dh FB57h FB61h FB6Ah FB73h FB7Dh FB86h FB90h FB99h 
 FBA2h FBABh FBB4h FBBEh FBC7h FBD0h FBD9h FBE2h FBEBh FBF4h FBFDh FC05h FC0Eh 
 FC17h FC20h FC28h FC31h FC3Ah FC42h FC4Bh FC53h FC5Ch FC64h FC6Dh FC75h FC7Dh 
 FC85h FC8Eh FC96h FC9Eh FCA6h FCAEh FCB6h FCBEh FCC6h FCCEh FCD6h FCDEh FCE6h 
 FCEEh FCF5h FCFDh FD05h FD0Ch FD14h FD1Bh FD23h FD2Ah FD32h FD39h FD41h FD48h 
 FD4Fh FD56h FD5Eh FD65h FD6Ch FD73h FD7Ah FD81h FD88h FD8Fh FD96h FD9Dh FDA4h 
 FDAAh FDB1h FDB8h FDBEh FDC5h FDCCh FDD2h FDD9h FDDFh FDE6h FDECh FDF2h FDF9h 
 FDFFh FE05h FE0Bh FE12h FE18h FE1Eh FE24h FE2Ah FE30h FE36h FE3Ch FE42h FE47h 
 FE4Dh FE53h FE59h FE5Eh FE64h FE6Ah FE6Fh FE75h FE7Ah FE80h FE85h FE8Ah FE90h 
 FE95h FE9Ah FEA0h FEA5h FEAAh FEAFh FEB4h FEB9h FEBEh FEC3h FEC8h FECDh FED2h 
 FED6h FEDBh FEE0h FEE4h FEE9h FEEEh FEF2h FEF7h FEFBh FF00h FF04h FF09h FF0Dh 
 FF11h FF15h FF1Ah FF1Eh FF22h FF26h FF2Ah FF2Eh FF32h FF36h FF3Ah FF3Eh FF42h 
 FF45h FF49h FF4Dh FF51h FF54h FF58h FF5Bh FF5Fh FF62h FF66h FF69h FF6Dh FF70h 
 FF73h FF77h FF7Ah FF7Dh FF80h FF83h FF86h FF89h FF8Ch FF8Fh FF92h FF95h FF98h 
 FF9Bh FF9Dh FFA0h FFA3h FFA5h FFA8h FFABh FFADh FFB0h FFB2h FFB4h FFB7h FFB9h 
 FFBBh FFBEh FFC0h FFC2h FFC4h FFC6h FFC8h FFCAh FFCCh FFCEh FFD0h FFD2h FFD4h 
 FFD6h FFD7h FFD9h FFDBh FFDCh FFDEh FFE0h FFE1h FFE3h FFE4h FFE6h FFE7h FFE8h 
 FFEAh FFEBh FFECh FFEDh FFEEh FFEFh FFF0h FFF1h FFF2h FFF3h FFF4h FFF5h FFF6h 
 FFF7h FFF8h FFF8h FFF9h FFFAh FFFAh FFFBh FFFBh FFFCh FFFCh FFFDh FFFDh FFFDh 
 FFFEh FFFEh FFFEh FFFEh FFFEh FFFEh FFFFh                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

The next portion starts at E000h again, but represents a different overlay. 
 
=== OVERLAY BANK 2 ============================================================ 
 
  BANK      ; Pad to 8K OVERLAY base address 2  (12000h) 
 
Public domain 8x8 ascii font 512 cells 
Source: https://github.com/dhepper/font8x8/ 
 
 @ASC8X8 
 
 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 
 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 
 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 
 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 
 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 
 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 
 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 
 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 
 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 
 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 
 0000h 0000h 183Ch 3C18h 1800h 1800h 3636h 0000h 0000h 0000h 3636h 7F36h 7F36h                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
 3600h 0C3Eh 031Eh 301Fh 0C00h 0063h 3318h 0C66h 6300h 1C36h 1C6Eh 3B33h 6E00h 
 0606h 0300h 0000h 0000h 180Ch 0606h 060Ch 1800h 060Ch 1818h 180Ch 0600h 0066h 
 3BFFh 3C66h 0000h 000Ch 0C3Fh 0C0Ch 0000h 0000h 0000h 000Ch 0C06h 0000h 003Fh 
 0000h 0000h 0000h 0000h 000Ch 0C00h 6030h 180Ch 0603h 0100h 3E63h 737Bh 6F67h 
 3E00h 0C0Eh 0C0Ch 0C0Ch 3F00h 1E33h 301Ch 0633h 3F00h 1E33h 301Ch 3033h 1E00h 
 383Ch 3633h 7F30h 7800h 3F03h 1F30h 3033h 1E00h 1C06h 031Fh 3333h 1E00h 3F33h 
 3018h 0C0Ch 0C00h 1E33h 331Eh 3333h 1E00h 1E33h 333Eh 3018h 0E00h 000Ch 0C00h 
 000Ch 0C00h 000Ch 0C00h 000Ch 0C06h 180Ch 0603h 060Ch 1800h 0000h 3F00h 003Fh 
 0000h 060Ch 1830h 180Ch 0600h 1E33h 3018h 0C00h 0C00h 3E63h 7B7Bh 7B03h 1E00h 
 0C1Eh 3333h 3F33h 3300h 3F66h 663Eh 6666h 3F00h 3C66h 0303h 0366h 3C00h 1F36h 
 6666h 6636h 1F00h 7F46h 161Eh 1646h 7F00h 7F46h 161Eh 1606h 0F00h 3C66h 0303h 
 7366h 7C00h 3333h 333Fh 3333h 3300h 1E0Ch 0C0Ch 0C0Ch 1E00h 7830h 3030h 3333h 
 1E00h 6766h 361Eh 3666h 6700h 0F06h 0606h 4666h 7F00h 6377h 7F7Fh 6B63h 6300h 
 6367h 6F7Bh 7363h 6300h 1C36h 6363h 6336h 1C00h 3F66h 663Eh 0606h 0F00h 1E33h 
 3333h 3B1Eh 3800h 3F66h 663Eh 3666h 6700h 1E33h 070Eh 3833h 1E00h 3F2Dh 0C0Ch 
 0C0Ch 1E00h 3333h 3333h 3333h 3F00h 3333h 3333h 331Eh 0C00h 6363h 636Bh 7F77h 
 6300h 6363h 361Ch 1C36h 6300h 3333h 331Eh 0C0Ch 1E00h 7F63h 3118h 4C66h 7F00h 
 1E06h 0606h 0606h 1E00h 0306h 0C18h 3060h 4000h 1E18h 1818h 1818h 1E00h 081Ch                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

 3663h 0000h 0000h 0000h 0000h 0000h FFFFh 0C0Ch 1800h 0000h 0000h 0000h 1E30h 
 3E33h 6E00h 0706h 063Eh 6666h 3B00h 0000h 1E33h 0333h 1E00h 3830h 303Eh 3333h 
 6E00h 0000h 1E33h 3F03h 1E00h 1C36h 060Fh 0606h 0F00h 0000h 6E33h 333Eh 301Fh 
 0706h 366Eh 6666h 6700h 0C00h 0E0Ch 0C0Ch 1E00h 3000h 3030h 3033h 331Eh 0706h 
 6636h 1E36h 6700h 0E0Ch 0C0Ch 0C0Ch 1E00h 0000h 337Fh 7F6Bh 6300h 0000h 1F33h 
 3333h 3300h 0000h 1E33h 3333h 1E00h 0000h 3B66h 663Eh 060Fh 0000h 6E33h 333Eh 
 3078h 0000h 3B6Eh 6606h 0F00h 0000h 3E03h 1E30h 1F00h 080Ch 3E0Ch 0C2Ch 1800h 
 0000h 3333h 3333h 6E00h 0000h 3333h 331Eh 0C00h 0000h 636Bh 7F7Fh 3600h 0000h 
 6336h 1C36h 6300h 0000h 3333h 333Eh 301Fh 0000h 3F19h 0C26h 3F00h 380Ch 0C07h 
 0C0Ch 3800h 1818h 1800h 1818h 1800h 070Ch 0C38h 0C0Ch 0700h 6E3Bh 0000h 0000h 
 0000h 0000h 0000h 0000h 0000h 
 
Public domain 8x8 unicode hiragana font 384 cells 
Source: https://github.com/dhepper/font8x8/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             


 @HIRAG8X8 
 
 0000h 0000h 0000h 0000h 043Fh 043Ch 564Dh 2600h 043Fh 043Ch 564Dh 2600h 0000h 
 0011h 2125h 0200h 0001h 1121h 2125h 0200h 001Ch 001Ch 2220h 1800h 3C00h 3C42h 
 4020h 1800h 1C00h 3E10h 3824h 6200h 1C00h 3E10h 3824h 6200h 244Fh 043Ch 4645h 
 2200h 244Fh 043Ch 4645h 2200h 0424h 4F54h 5212h 0900h 4424h 0F54h 5252h 0900h 
 081Fh 083Fh 1C02h 3C00h 442Fh 041Fh 0E01h 1E00h 1008h 0402h 0408h 1000h 2844h 
 1221h 0204h 0800h 0022h 7921h 2122h 1000h 4022h 113Dh 1112h 0800h 0000h 3C00h 
 0202h 3C00h 2040h 1620h 0101h 0E00h 107Eh 103Ch 0202h 1C00h 244Fh 142Eh 0101h 
 0E00h 0002h 0202h 4222h 1C00h 2042h 1222h 0222h 1C00h 107Eh 1814h 1810h 0C00h 
 442Fh 0605h 0604h 0300h 2072h 2F22h 1A02h 1C00h 8050h 3A17h 1A02h 1C00h 1E08h 
 047Fh 0804h 3800h 4F24h 027Fh 0804h 3800h 020Fh 0272h 0209h 7100h 422Fh 0272h 
 0209h 7100h 087Eh 083Ch 4040h 3800h 442Fh 041Eh 2020h 1C00h 0000h 001Ch 2220h 
 1C00h 001Ch 2241h 4020h 1C00h 4020h 1E21h 2020h 1C00h 003Eh 0804h 0404h 3800h 
 003Eh 4824h 0404h 3800h 0404h 083Ch 0202h 3C00h 4424h 083Ch 0202h 3C00h 3202h 
 2722h 7229h 1100h 0002h 7A02h 0A72h 0200h 0809h 3E4Bh 6555h 2200h 0407h 344Ch 
 6654h 2400h 0000h 3C4Ah 4945h 2200h 0022h 7A22h 722Ah 1200h 8051h 1D11h 3915h 
 0900h 3FB1h 5D11h 3915h 0900h 0000h 1332h 5111h 0E00h 4020h 0332h 5111h 0E00h 
 3FA0h 4332h 5111h 0E00h 1C00h 082Ah 4910h 0C00h 4C20h 082Ah 4910h 0C00h 4BA0h                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
 480Ah 2948h 0C00h 0000h 040Ah 1120h 4000h 2040h 142Ah 1120h 4000h 2050h 240Ah 
 1120h 4000h 7D11h 7D11h 3955h 0900h 9D51h 1D11h 3955h 0900h 5CB1h 5D11h 3955h 
 0900h 7E08h 3E08h 1C2Ah 0400h 0007h 2424h 7E25h 1200h 040Fh 6406h 0526h 3C00h 
 0009h 3D4Ah 4B45h 2A00h 020Fh 020Fh 6242h 3C00h 0000h 121Fh 2212h 0400h 0012h 
 3F42h 4234h 0400h 0000h 113Dh 5339h 1100h 0011h 3D53h 5139h 1100h 0008h 3808h 
 1C2Ah 0400h 0808h 3808h 1C2Ah 0400h 1E00h 023Ah 4642h 3000h 0020h 2222h 2A24h 
 1000h 1F08h 3C42h 4954h 3800h 0407h 040Ch 1655h 2400h 3F10h 083Ch 4241h 3000h 
 0000h 080Eh 384Ch 2A00h 0407h 043Ch 4645h 2400h 0E08h 3C4Ah 6955h 3200h 063Ch 
 4239h 0436h 4900h 040Fh 046Eh 1108h 7000h 0808h 040Ch 5652h 2100h 402Eh 003Ch 
 4240h 3800h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 
 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 0000h 
 3F80h 2040h 0000h 0000h 3FA0h 4000h 0000h 0000h 0000h 0808h 1030h 0C00h 2040h 
 1424h 0818h 0600h 0000h 0000h 0000h 0000h 
 
Public domain 8x8 unicode box drawing font 512 cells 
Source: https://github.com/dhepper/font8x8/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
 
 @BOX8X8 
 
 0000h 0000h FF00h 0000h 0000h FFFFh FF00h 0000h 0808h 0808h 0808h 0808h 1818h 
 1818h 1818h 1818h 0000h 0000h BB00h 0000h 0000h FFBBh BB00h 0000h 0800h 0808h 
 0800h 0808h 1800h 1818h 1800h 1818h 0000h 0000h 5500h 0000h 0000h 0055h 5500h 
 0000h 0008h 0008h 0008h 0008h 0018h 0018h 0018h 0018h 0000h 0000h F808h 0808h 
 0000h FFF8h F808h 0808h 0000h 0000h F818h 1818h 0000h FFF8h F818h 1818h 0000h 
 0000h 0F08h 0808h 0000h 000Fh 0F08h 0808h 0000h 0000h 1F18h 1818h 0000h 001Fh 
 1F18h 1818h 0808h 0808h F800h 0000h 0808h 07F8h F800h 0000h 1818h 1818h F800h 
 0000h 1818h 17F8h F800h 0000h 0808h 0808h 0F00h 0000h 0808h 080Fh 0F00h 0000h 
 1818h 1818h 1F00h 0000h 1818h 181Fh 1F00h 0000h 0808h 0808h F808h 0808h 0808h 
 07F8h F808h 0808h 1818h 1818h F808h 0808h 0808h 0808h F818h 1818h 1818h 1818h 
 F818h 1818h 1818h 17F8h F808h 0808h 0808h 07F8h F818h 1818h 1818h 17F8h F818h 
 1818h 0808h 0808h 0F08h 0808h 0808h 080Fh 0F08h 0808h 1818h 1818h 1F08h 0808h 
 0808h 0808h 1F18h 1818h 1818h 1818h 1F18h 1818h 1818h 181Fh 1F08h 0808h 0808h 
 081Fh 1F18h 1818h 1818h 181Fh 1F18h 1818h 0000h 0000h FF08h 0808h 0000h 000Fh 
 FF08h 0808h 0000h FFF8h FF08h 0808h 0000h FFFFh FF08h 0808h 0000h 0000h FF18h 
 1818h 0000h 001Fh FF18h 1818h 0000h FFF8h FF18h 1818h 0000h FFFFh FF18h 1818h 
 0808h 0808h FF00h 0000h 0808h 080Fh FF00h 0000h 0808h 07F8h FF00h 0000h 0808h 
 07FFh FF00h 0000h 1818h 1818h FF00h 0000h 1818h 181Fh FF00h 0000h 1818h 17F8h 
 FF00h 0000h 1818h 17FFh FF00h 0000h 0808h 0808h FF08h 0808h 0808h 080Fh FF08h 
 0808h 0808h 07F8h FF08h 0808h 0808h 07FFh FF08h 0808h 1818h 1818h FF08h 0808h 
 0808h 0808h FF18h 1818h 1818h 1818h FF18h 1818h 1818h 181Fh FF08h 0808h 1818h                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
 17F8h FF08h 0808h 0808h 081Fh FF18h 1818h 0808h 07F8h FF18h 1818h 0808h 07FFh 
 FF18h 1818h 1818h 17FFh FF08h 0808h 1818h 17F8h FF18h 1818h 1818h 181Fh FF18h 
 1818h 1818h 17FFh FF18h 1818h 0000h 0000h E700h 0000h 0000h FFE7h E700h 0000h 
 0808h 0800h 0008h 0808h 1818h 1800h 0018h 1818h 0000h FFFFh FFFFh 0000h 1414h 
 1414h 1414h 1414h 0000h FFF8h 07F8h 0808h 0000h 0000h FC14h 1414h 0000h FFFCh 
 03F4h 1414h 0000h 000Fh 080Fh 0808h 0000h 0000h 1F14h 1414h 0000h 001Fh 1017h 
 1414h 0808h 07F8h 07F8h 0000h 1414h 1414h FC00h 0000h 1414h 13F4h 03FCh 0000h 
 0808h 080Fh 080Fh 0000h 1414h 1414h 1F00h 0000h 1414h 1417h 101Fh 0000h 0808h 
 07F8h 07F8h 0808h 1414h 1414h F414h 1414h 1414h 13F4h 03F4h 1414h 0808h 080Fh 
 080Fh 0808h 1414h 1414h 1714h 1414h 1414h 1417h 1017h 1414h 0000h FFFFh FFFFh 
 0808h 0000h 0000h FF14h 1414h 0000h FFFFh FFF7h 1414h 0808h 07FFh FFFFh 0000h 
 1414h 1414h FF00h 0000h 1414h 13F7h FFFFh 0000h 0808h 07FFh 07FFh 0808h 1414h 
 1414h FF14h 1414h 1414h 13F7h FFF7h 1414h 0000h 0000h E010h 0808h 0000h 0000h 
 0304h 0808h 0808h 0804h 0300h 0000h 0808h 0810h E000h 0000h 8040h 2010h 0804h 
 0201h 0102h 0408h 1020h 3F80h 8142h 2418h 1824h 4181h 0000h 0000h 0F00h 0000h 
 0808h 0808h 0000h 0000h 0000h 0000h F800h 0000h 0000h 0000h 0808h 0808h 0000h 
 000Fh 0F00h 0000h 1818h 1818h 0000h 0000h 0000h FFF8h F800h 0000h 0000h 0000h 
 1818h 1818h 0000h FFF8h FF00h 0000h 0808h 0808h 1818h 1818h 0000h 000Fh FF00h 
 0000h 1818h 1818h 0808h 0808h                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
The next portion starts at E000h again, but represents a different overlay. 
 
=== OVERLAY BANK 3 ============================================================ 
 
  BANK      ; Pad to 8K OVERLAY base address 3  (14000h) 
 
System string table - these are byte strings, 
Terminated by ASC 03 (End of Text) if cell not full 
 
 @STR_MyMSG1   'Aerisil/1810 @58MHz' 10 0 
 @STR_ObjCSize ' words generated' 10 0 
 @STR_SymMax   'Symtab at ' 0 
 @STR_CullTo   'Cull to ' 0
 @EDSTATEMPTY  'B:    R:   C:                                   ' 0 
               ;123456789012345678901234567890123456789012345678

; @EDSTRSRC     'SRC' 0
; @EDSTRDST     'DST' 0
 
 @EMPTY7       '       ' 0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
=== OVERLAY BANK 4 ============================================================ 
This bank contains a text buffer and code for Ajisai screen editor 
 
 BANK       ; Pad to 8K OVERLAY base address 4  (16000h) 
 @EDBUF1     ; Gets mapped to E000h 
  ORG EA00h ; Reserve 2560 (80x32) = 2560 = A00h word editor buffer 
 @EDBUF2 
  ORG F400h ; Reserve another 80x32 editor buffer 
 @EDBUFSIZE A00h 
 
 @EDCUR1 0 
 @EDCUR2 0 
 
 @EDCUR EDCUR1 ; Linear cursor offset in edit buffer 
 @EDBUF EDBUF1 ; Edit buffer top left visible portion  
 
 @STATUSLINE 4048 ; 80*128 - 48 cols ; These are text RAM offsets 
 @EDPOSBEACH 4050 ; For example this indicator string starts here on screen
 @EDPOSROW 4056 
 @EDPOSCOL 4061
 @EDPOSSRC 4064
 @EDPOSDST 4068 
 @EDBEACH 0       ; Which SD block range (1 beach = 10 blocks) is being edited                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
 @EDCLR ; Fill buffer with space characters 
   L1 REF :: EDBUF 
   L2 REF :: EDBUFSIZE 
   L3 INT 32 ; ASCII space 
   @LOOP L3 STO L1 
            GET L1 +1 
         L2 REP <LOOP 
 
   L1 REF :: EDCUR ; Reset cursor pos 
    E INT 0 
    E STO L1 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
 @CLR80 ; Fill 80 columns with space characters 
  L1 INT 32       ; Space char 
  L2 INT 0        ; Sweeps txt video memory 
  L3 INT 32       ; Do 32 lines 
  L4 SET :: 48    ; Skip col 80 to 127 
  @UPDLOOPO 
   L6 INT 80      ; Do 80 columns 
   @UPDLOOPI 
    L2 SOP sop_TXT_pos_set  
    L1 SOP sop_TXT_glyphs 
     ; SOP sop_TXT_colors   
       GET L2 +1 
    L6 REP <UPDLOOPI 
       ADD L2 L4 ; Skip cli column 
    L3 REP <UPDLOOPO 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
 @EDGETXY ; Compute row (A2) and column (A3) from linear cursor offset (A1) 
          ; Return col 0 if cursor outside of buffer    
 
             L1 REF :: EDBUF ; Buffer base address 
             L2 SET :: 1000h ; Buffer size 
             
             A2 INT 1 
             A3 INT 0 ; Assume cursor outside buffer (column starts at 1) 
 
             A1 GTR L2 
             DR THN >QUIT ; Cursor must be within buffer 
 
             L7 ADD L1 A1 ; Effective cursor address     
             A3 INT 1     ; First column 
     @LOOP   L4 LOD L1    ; Check character at cursor 
             L4 EQL 10    ; Newline 
             DR ELS >CHAR 
             A3 INT 0 
                GET A2 +1   
     @CHAR      GET A3 +1 
             A1 EQR L7 
             DR THN >QUIT    
                GET L1 +1 
                BRA <LOOP 
 @QUIT 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
 @EDCLEARSTATL 
  L1 REF :: STATUSLINE 
  L1 PER :: TXTPOS 
     JSR :: PR_MSG :: EDSTATEMPTY       
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
 ;Also sets cursor 
 @EDUPDATE 
     JSR :: CLR80 
  L1 REF :: EDBUF ; Top left corner of visible region edit buffer 
  L2 INT 0        ; Sweeps txt video memory 
  L4 SET :: 48    ; Skip col 80 to 127 
  L5 SET :: COLOR_white 
  L7 REF :: EDCUR ; Cursor offset 
     LOD L7 
     ADD L7 L1    ; Cursor addr 
  L3 INT 32       ; Do 32 lines 
  @UPDLOOPO 
   L6 INT 80      ; Do 80 columns 
   @UPDLOOPI   

 ; Continued         

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
 ; Continued

 
    L1 EQR L7 ; Check if where cursor is 
    DR ELS >SKIP 
       L2 SOP sop_TXT_curset 
       JSR :: EDCLEARSTATL 
     E REF :: EDPOSBEACH 
     E PER :: TXTPOS 
     E REF :: EDBEACH 
       JSR :: PRNUM 
     E REF :: EDPOSROW ; display cursor row/col 
     E PER :: TXTPOS 
    DR GET L3 
     E INT 33 
       SUB E DR  
       JSR :: PRNUM 
     E REF :: EDPOSCOL ; display cursor row/col 
     E PER :: TXTPOS 
    DR GET L6 
     E INT 81 
       SUB E DR 
       JSR :: PRNUM    
     ;  JSR :: EDSRCDST ; Display SRC DST markers

 ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
   ; Continued

   @SKIP  
     E LOD L1     ; Read current character in ed buffer 
     E THN >NN 
     E INT 2   
 @NN E EQL 10 
    DR ELS >EDPRINT 
       GET L1 +1    ; Skip newline character 
       ADD L2 L6    ; Skip to column 80 
       ADD L2 L4    ; Skip cli column 
    L3 REP <UPDLOOPO 
       RET        
    @EDPRINT 
    L2 SOP sop_TXT_pos_set  
     E SOP sop_TXT_glyphs 
    L5 SOP sop_TXT_colors   
       GET L1 +1 
       GET L2 +1 
    L6 REP <UPDLOOPI 
       ADD L2 L4 ; Skip cli column 
    L3 REP <UPDLOOPO 
 RET     

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
 @EDSRCDST ; This functions prints SRC DST markings in status line

       L1 REF :: EDPOSSRC ; Clear SRC DST marker in status line
       L1 PER :: TXTPOS
          JSR :: PR_MSG :: EMPTY7

       L2 REF :: ED_SRC_STATE
       L2 THN >2
       L1 PER :: TXTPOS
          JSR :: PR_MSG :: EDSTRSRC
     
   @2  L2 REF :: ED_DST_STATE
       L2 THN >QUIT
       L1 REF :: EDPOSDST
       L1 PER :: TXTPOS
          JSR :: PR_MSG :: EDSTRDST

 @QUIT
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           

 @EDKEYHANDLER ; Keycode (cooked) in A1 
 
       A1 EQL 6 
       DR ELS >1 
          JSR :: ARRUP 
          RET 
    @1 A1 EQL 11 
       DR ELS >2 
          JSR :: ARRDOWN 
          RET 
    @2 A1 EQL 12 
       DR ELS >3 
          JSR :: ARRLEFT 
          RET 
    @3 A1 EQL 14 
       DR ELS >4 
          JSR :: ARRRIGHT 
          RET 
    @4 A1 EQL 1 
       DR ELS >5 
          JSR :: INSKEY 
          RET 
    @5 A1 EQL 127 
       DR ELS >6 
          JSR :: DELKEY 
          RET   


  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
  ; Continued


 
    @6 A1 EQL 8 
       DR ELS >7 
          JSR :: RUBKEY ; Backspace 
          RET 
    @7 A1 EQL 16 
       DR ELS >8 
          JSR :: F1KEY ; Set source region 
          RET 
    @8 A1 EQL 17 
       DR ELS >9 
          JSR :: F2KEY ; Set dest region 
          RET 
    @9 A1 EQL 2 
       DR ELS >10 
          JSR :: EDBUFSWAP ; HOME key 
          RET 
   @10 A1 EQL 3 
       DR ELS >11 
          ; END key 
          RET


 ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
  ; Continued

   @11 A1 EQL 4 ; PgUP key 
       DR ELS >12 
        E REF :: EDBEACH 
        E ELS >QUIT 
          GET E -1 
        E PER :: EDBEACH     
          JSR :: EDLDBEACH 
        E REF :: EDCUR 
       DR INT 0 
       DR STO E   
    @QUIT RET 
   @12 A1 EQL 5 ; PgDN key 
       DR ELS >13 
        E REF :: EDBEACH 
       DR SET :: 999 
       DR GTR E 
       DR ELS >QUIT   
          GET E +1 
        E PER :: EDBEACH     
          JSR :: EDLDBEACH 
        E REF :: EDCUR 
       DR INT 0 
       DR STO E   
    @QUIT RET

  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  ; Continued

   @13 A1 EQL 18 
       DR ELS >14 
          JSR :: EDSTBEACH ; F3KEY Save beach buffer to card 
          RET 
   @14 A1 EQL 19 
       DR ELS >15 
          JSR :: EDCLR ; F4KEY    (was EDFORMAT) 
          RET 
   @15 A1 EQL 20 
       DR ELS >16 
          JSR :: EDINSBEACH ; F5KEY 
          RET 
   @16 A1 EQL 21 
       DR ELS >17 
          JSR :: EDDELBEACH ; F6KEY 
          RET 
   @17 A1 EQL 29
       DR ELS >18
          JSR :: EDDELDST ; Shift DEL
          RET
   @18


  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
  ; Continued

    ; Default to insert character 
 
      L1 REF :: EDBUF ; Editor buffer base address 
      L2 REF :: EDCUR ; EDCUR is the linear offset of the cursor into EDBUF 
         LOD L2 
      L3 ADD L1 L2    ; Effective address of cursor within EDBUF 
      L4 REF :: EDBUFSIZE 
         GET L4 -1 
         ADD L4 L1    ; Last character position in EDBUF 
      
    ; Make space for char by shifting up the buffer from cursor pos by 1 

      L5 GET L4    ; Last pos in EDBUF 
      L6 GET L5 -1 ; Second from last 
      L3 EQR L4    ; If cursor at last position don't shift 
      DR THN >INS
         JSR  L6 L5 L3 :: SHDOWN
 @INS A1 STO L3 ; Store character at cursor pos 
         GET L2 +1 ; Only increment cursor pos if not at final position 
       E REF :: EDCUR    
      L2 STO E ; Update cursor offset 
 
 @QUIT 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

 @SHDOWN ; Shift down a buffer, A1=SRC, A2=DST, A3=FIRST
        
        L1 GET A1
        L2 GET A2
        @LOOP DR LOD L1 
              DR STO L2 
              L1 EQR A3 ; If source char at cursor pos 
              DR THN >QUIT 
                 GET L1 -1 
              L2 REP <LOOP 
 
 @QUIT 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
 @ED_SRC E000h ; Copy-key handler
  
 @F1KEY ; Define source region for copy ops 
     L1 REF :: EDCUR 
        LOD L1 
     L2 REF :: EDBUF 
        ADD L2 L1
     L4 GET L2
     
     L1 REF :: ED_SRC
     L3 SET :: STRBUF_L0
        JSR L1 L2 :: ORDER
        JSR L1 L2 L3 :: CPFROMTO
     L4 PER :: ED_SRC
          
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
 @ED_DST1 E000h  ; Marker key handler
 @ED_DST2 E000h

 @F2KEY ; Define destination region for copy ops 
     L1 REF :: EDCUR 
        LOD L1 
     L2 REF :: EDBUF 
        ADD L2 L1 
     
     L3 REF :: ED_DST2
     L3 PER :: ED_DST1
     L2 PER :: ED_DST2   

 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
 @EDBUFSWAP ; Swap editor buffers and cursors 
 
     L1 SET :: EDBUF1 
     L2 REF :: EDBUF 
     L2 EQR L1 
     DR ELS >1 
 
     L1 SET :: EDBUF2 ; EDBUF DOES point to EDBUF1 
     L1 PER :: EDBUF 
     L1 SET :: EDCUR2 
     L1 PER :: EDCUR 
        BRA >QUIT  
   
  @1 L1 PER :: EDBUF  ; EDBUF does NOT point to EDBUF1 
     L1 SET :: EDCUR1 
     L1 PER :: EDCUR 
 
 @QUIT 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            

 @ARRUP ; Go to previous line 
 
   L1 REF :: EDBUF ; Editor buffer base address 
   L2 REF :: EDCUR ; EDCUR is the linear offset of the cursor into EDBUF1 
      LOD L2 
   L3 ADD L1 L2    ; Effective address of cursor within EDBUF1 
 
   ; Backtrack to beginning of previous line and match column   
    
   L6 INT 0 ; Rewind to beginning of line, count columns in L6 
   @CHECK 
    E LOD L3 
    E EQL 10 ; Check if newline, beginning of current line 
   DR THN >NEWL 
   L3 EQR L1    ; Check if pos 0 
   DR THN >DONE ; Won't see newline on first line of buffer 
      GET L6 +1  
      GET L2 -1 
   L3 REP <CHECK  


  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                


  ; Continued

   @NEWL 
      GET L2 -1 
      GET L3 -1 ; Skip newline 
      GET L6 -1 ; Newline is part of previous line, don't count as col 
    
   ; Rewind to beginning of previous line 
   @CHECK 
    E LOD L3 
    E EQL 10 ; Check if newline, beginning of previous line 
   DR THN >NEWL 
   L3 EQR L1      ; Check if pos 0 
   DR THN >POS0 ; If pos 0 pretend this is newline 
      GET L2 -1  
   L3 REP <CHECK 
   @NEWL 
      GET L2 +1 ; Reverse over newline, part of previous line 
   @POS0 
 
   ; Add required number of columns L6 
      ADD L2 L6 
    E REF :: EDCUR   
   L2 STO E ; Update cursor offset if not first pos    
 
 @DONE 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
 @ARRDOWN ; Go to next line 
 
   L1 REF :: EDBUF ; Editor buffer base address 
   L2 REF :: EDCUR ; EDCUR is the linear offset of the cursor into EDBUF1 
      LOD L2 
   L3 ADD L1 L2    ; Effective address of cursor within EDBUF1 
   L4 REF :: EDBUFSIZE 
      GET L4 -1 
      ADD L4 L1    ; Last character position in EDBUF1 
   
   L6 INT 0 ; Rewind to beginning of line, count columns in L6 
   @CHECK 
    E LOD L3 
    E EQL 10 ; Check if newline, beginning of current line 
   DR THN >NEWL 
   L3 EQR L1    ; Check if pos 0 
   DR THN >NOSKIP 
      GET L6 +1  
      GET L2 -1 
   L3 REP <CHECK    


  ; Continued                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
    ; Continued

   @NEWL 
      GET L2 +1 
      GET L3 +1 ; Reverse back over newline, stay on current line 
      GET L6 -1 ; Newline was part of previous line, don't count as col 
   @NOSKIP    
    
   ; Forward to after newline of current line = beginning of next line 
   @CHECK 
    E LOD L3 
    E EQL 10 ; Check if newline, beginning of next line 
   DR THN >NEWL 
   L3 EQR L4    ; Check if end of buffer pos 
   DR THN >DONE ; Can't go to next row then 
      GET L2 +1 
      GET L3 +1  
      BRA <CHECK 
   @NEWL 
      GET L2 +1 ; Skip newline, still part of current line 
   @POS0 
 
   ; Add required number of columns L6 
      ADD L2 L6 
    E REF :: EDCUR   
   L2 STO E ; Update cursor offset if not first pos    
 
 @DONE 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

 @ARRLEFT ; Go to previous char 
 
       L1 REF :: EDBUF ; Editor buffer base address 
       L2 REF :: EDCUR ; EDCUR is the linear offset of the cursor into EDBUF1 
          LOD L2 
       L3 ADD L1 L2    ; Effective address of cursor within EDBUF1 
  
  L2 ELS >QUIT    
     GET L2 -1 
     GET L3 -1 
   E REF :: EDCUR   
  L2 STO E ; Update cursor offset if not first pos 
 @QUIT 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
 @ARRRIGHT ; Go to next char 
 
       L1 REF :: EDBUF ; Editor buffer base address 
       L2 REF :: EDCUR ; EDCUR is the linear offset of the cursor into EDBUF 
          LOD L2 
       L3 ADD L1 L2    ; Effective address of cursor within EDBUF 
       L4 REF :: EDBUFSIZE 
          GET L4 -1 
          ADD L4 L1    ; Last character position in EDBUF 
 
  L3 EQR L4 ; Compare current pos to last pos  
  DR THN >QUIT    
     GET L2 +1 
     GET L3 +1   
   E REF :: EDCUR          
  L2 STO E ; Update cursor offset if not last pos 
 @QUIT 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    





 @INSKEY                    ; Copy source, overwrite dst region
     L1 SET :: STRBUF_L0
        JSR L1 L7 :: STRLEN ; strlen of buffer in L7
     L2 REF :: ED_DST1
     L3 REF :: ED_DST2
        JSR L2 L3 :: ORDER
        SUB L3 L2           ; Size of marked region
      E REF :: EDBUF
     L4 REF :: EDBUFSIZE
        GET L4 -1
        ADD L4 E            ; Last char in current edit buffer
     L3 GTR L7              ; If insert larger than marked region
     DR THN >SHRINK

     L6 SUB L7 L3
     L5 GET L4 -1
     @LOOP JSR L5 L4 L2 :: SHDOWN
        L6 REP <LOOP
           BRA >GROW

     @SHRINK L6 SUB L3 L7
          @LOOP JSR L2 L4 :: SHUP
             L6 REP <LOOP

     @GROW JSR L1 L2 :: CPNONULL ; Copy insert into snug region
        L3 REF :: EDBUF          ; Set cursor to insert marker
           SUB L2 L3
        L1 REF :: EDCUR
        L2 STO L1
           RET


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
  ; Delete a char by contracting the buffer into it 

 @DELKEY ; Delete following char 
 
       L1 REF :: EDBUF ; Editor buffer base address 
       L2 REF :: EDCUR ; EDCUR is the linear offset of the cursor into EDBUF1 
          LOD L2 
       L3 ADD L1 L2    ; Effective address of cursor within EDBUF1 
       L4 REF :: EDBUFSIZE 
          GET L4 -1 
          ADD L4 L1    ; Last character position in EDBUF 
 
    JSR L3 L4 :: >SHUP
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
 @RUBKEY ; Backspace, delete previous char 
 
       L1 REF :: EDBUF ; Editor buffer base address 
       L2 REF :: EDCUR ; EDCUR is the linear offset of the cursor into EDBUF 
          LOD L2 
       L3 ADD L1 L2    ; Effective address of cursor within EDBUF 
       L4 REF :: EDBUFSIZE 
          GET L4 -1 
          ADD L4 L1    ; Last character position in EDBUF 
 
  L2 ELS >QUIT    
     GET L2 -1 
     GET L3 -1 
   E REF :: EDCUR    
  L2 STO E ; Update cursor offset if not first pos 
     JSR L3 L4 :: >SHUP
 @QUIT 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
 @SHUP  ; Helper for DELKEY/RUBKEY 
        ; A1 is effective cursor addr, A2 = end of buffer addr 
 L5 GET A1 
 L6 GET L5 +1 ; Source pos, L3 is target pos 
    @LOOP DR LOD L6 
          DR STO L5 
          L6 EQR A2 ; If source pos end of buffer 
          DR THN >QUIT 
             GET L6 +1 
             GET L5 +1 
             BRA <LOOP 
   
 @QUIT 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
 @EDDELDST
       L1 REF :: ED_DST1
       L2 REF :: ED_DST2
          JSR L1 L2 :: ORDER ; L2 will be the greater value 
          SUB L2 L1          ; How many chars in region
       L2 ELS >QUIT
       L3 REF :: EDBUF
       L4 REF :: EDBUFSIZE
          ADD L4 L3
          GET L4 -1
       @LOOP
          JSR L1 L4 :: <SHUP
       L2 REP <LOOP
          SUB L1 L3          ; DST1 - EDBUF = new EDCUR
       L3 REF :: EDCUR
       L1 STO L3
 @QUIT
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
 @EDLDBEACH 
 
    ; Block 4096-8192: Beach buffers 
 
          L1 REF :: EDBUF    ; Editor buffer base address 
          L4 INT 0           ; First block high order (a 16-bit number!) 
           E REF :: EDBEACH 
          L2 SHL E 3 
             SHL E 1 
             ADD L2 E         ; Multiply by 10 
           E REF :: BEACHBASE ; Base block for beaches region 
             ADD L2 E         ; First block low order (16 bit) 
          L3 SET :: 10        ; Number of blocks = 10 blocks / 1 beach 
       @1    JSR L2 L1 L4 :: SPI_RDBLK 
             GET L2 +1 
          L3 REP <1 
 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
 @EDSTBEACH 
 
    ; Block 4096-8192: Beach buffers 
 
          L1 REF :: EDBUF    ; Editor buffer base address 
          L4 INT 0           ; First block high order (a 16-bit number!) 
           E REF :: EDBEACH 
          L2 SHL E 3 
             SHL E 1 
             ADD L2 E         ; Multiply by 10 
           E REF :: BEACHBASE ; Base block for beaches region 
             ADD L2 E         ; First block low order (16 bit) 
          L3 SET :: 10        ; Number of blocks = 10 blocks / 1 beach 
       @1    JSR L2 L1 L4 :: SPI_WRBLK 
             GET L2 +1 
          L3 REP <1 
 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
 @EDINSBEACH 
  
          L4 INT 0           ; First block high order (a 16-bit number!) 
           E REF :: EDBEACH 
          L3 SHL E 3 
             SHL E 1 
             ADD L3 E         ; Multiply by 10 
           E REF :: BEACHBASE ; Base block for beaches region 
             ADD L3 E         ; Final block low order (16 bit) 
              
          L5 SET :: 9990
             ADD L5 E        ; First target block (Highest block in use))  
          L7 INT 10 
          L6 SUB L5 L7       ; First source block 
 
       @1 L1 SET :: 6000h    ; Block buffer 
             JSR L6 L1 L4 :: SPI_RDBLK          
          L1 SET :: 6000h 
             JSR L5 L1 L4 :: SPI_WRBLK 
          L6 EQR L3 
          DR THN >QUIT 
             GET L5 -1 
             GET L6 -1 
             BRA <1           
  
 @QUIT       JSR :: EDCLR 
             JSR :: EDSTBEACH 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
 @EDDELBEACH 
  
          L4 INT 0           ; First block high order (a 16-bit number!) 
            
           E REF :: EDBEACH 
          L3 SHL E 3 
             SHL E 1 
             ADD L3 E         ; Multiply by 10 
           E REF :: BEACHBASE ; Base block for beaches region 
             ADD L3 E         ; First target block low order (16 bit) 
 
          L7 INT 10 
             ADD L7 L3       ; First source block (1 beach after target block) 
           
          L5 SET :: 9990     ; 999 beaches
             ADD L5 E        ; Final source block (Highest block in use)  
 
       @1 L1 SET :: 6000h    ; Block buffer 
             JSR L7 L1 L4 :: SPI_RDBLK          
          L1 SET :: 6000h 
             JSR L3 L1 L4 :: SPI_WRBLK 
          L7 EQR L5 
          DR THN >QUIT 
             GET L3 +1 
             GET L7 +1 
             BRA <1           
  
 @QUIT       JSR :: EDLDBEACH 
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
 @EDFORMAT 
          L1 REF :: EDBUF ; Remember no rows no columns in buffer! 
          L2 SET :: 2559  ; 80x32 - 1 
          L3 ADD L1 L2    ; Start at end of buffer 
 
       @1  E LOD L3 
           E EQL 32 
          DR ELS >QUIT  ; Stop at first non-space character 
           E INT 10 
           E STO L3     ; Replace space by newline char   
             GET L3 -1 
          L2 REP <1 
 
 @QUIT  
 RET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
; Paverho limit 
 
;  BANK      ; Pad to 8K OVERLAY base address 5  (18000h) 
;  BANK      ; Pad to 8K OVERLAY base address 6  (1A000h) 
;  BANK      ; Pad to 8K OVERLAY base address 7  (1C000h) 
;  BANK      ; Pad to 8K OVERLAY base address 8  (1E000h) 
;  BANK      ; Pad to 8K OVERLAY base address 9  (20000h) 
;  BANK      ; Pad to 8K OVERLAY base address 10 (22000h) 
;  BANK      ; Pad to 8K OVERLAY base address 11 (24000h) 
;  BANK      ; Pad to 8K OVERLAY base address 12 (26000h) 
;  BANK      ; Pad to 8K OVERLAY base address 13 (2A000h) 
;  BANK      ; Pad to 8K OVERLAY base address 14 (2C000h) 
;  BANK      ; Pad to 8K OVERLAY base address 15 (2E000h) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    