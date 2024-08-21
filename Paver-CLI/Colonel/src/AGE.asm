




THIS IS REQUIRED BUT SWITCHED OFF
; @CYF_Str16BufPtr  BUF 100h     ; WAS: 80*32*2 multi-purpose buffer  (1400h)


 @EDITING 0 ; flag var

-------------------------------------------------------------------------------


 @BEACHBASE 736   ; First block of beach region
 @SYSBASE   736   ; First block of system source code
 @EDBEACH   0     ; Which SD block range (1 beach = 10 blocks) is being edited

System string table - these are byte strings,
Terminated by ASC 03 (End of Text) if cell not full

 @EDSTATEMPTY  'B:    R:   C:                ' 0
               ;123456789012345678901234567890123456789012345678

 @EDSTRSRC     'SRC' 0
 @EDSTRDST     'DST' 0

 @EMPTY7       '       ' 0

 
 ;@EDBUF1 BUF A00h ; Reserve 2560 (80x32) = 2560 = A00h word editor buffer
 ;@EDBUF2 BUF A00h ; Reserve another 80x32 editor buffer
 ;@EDBUFSIZE A00h

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

-------------------------------------------------------------------------------

 @EDCLR ; Fill buffer with space characters
   L1 REF :: EDBUF
   L4 GET L1
   L2 REF :: EDBUFSIZE
   L3 INT 32 ; ASCII space
   @LOOP L3 STO L1
            GET L1 +1
         L2 REP <LOOP

   DR INT 0
   DR STO L4    ; Set first char to NULL (Stop assembly runs, beach head)
   DR INT 59    ; ASCII
   DR STO L4 +1

   L1 REF :: EDCUR ; Reset cursor pos
   E INT 0
   E STO L1
 RET

-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------

 @EDCLEARSTATL
  L1 REF :: STATUSLINE
  L1 PER :: TXTPOS
     JSR :: PR_MSG :: EDSTATEMPTY
 RET

Also sets cursor

-------------------------------------------------------------------------------

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

    L1 EQR L7 ; Check if where cursor is
    DR ELS >SKIP
       L2 SOP sop_TXT_curset
       JSR :: EDCLEARSTATL
    E REF :: EDPOSBEACH
    E PER :: TXTPOS
    E REF :: EDBEACH
       JSR :: 8T3_prUDec
    E REF :: EDPOSROW ; display cursor row/col
    E PER :: TXTPOS
    DR GET L3
    E INT 33
       SUB  E DR
       JSR :: 8T3_prUDec
    E REF :: EDPOSCOL ; display cursor row/col
    E PER :: TXTPOS
    DR GET L6
    E INT 81
       SUB  E DR
       JSR :: 8T3_prUDec
     ;  JSR :: EDSRCDST ; Display SRC DST markers

   @SKIP
    E LOD L1     ; Read current character in ed buffer
    E THN >NN
    E INT 2      ; If NULL replace by 02h glyph
 @NN  E EQL 10
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

-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------

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

   @11 A1 EQL 4 ; PgUP key
       DR ELS >12
       E REF :: EDBEACH
       E ELS >QUIT
          GET  E -1
       E PER :: EDBEACH
          JSR :: EDLDBEACH
       E REF :: EDCUR
       DR INT 0
       DR STO  E
    @QUIT RET
   @12 A1 EQL 5 ; PgDN key
       DR ELS >13
       E REF :: EDBEACH
       DR SET :: 999
       DR GTR ER
       DR ELS >QUIT
          GET  E +1
       E PER :: EDBEACH
          JSR :: EDLDBEACH
       E REF :: EDCUR
       DR INT 0
       DR STO  E
    @QUIT RET

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
      L2 STO  E ; Update cursor offset

 @QUIT
 RET

-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------

 @ED_SRC E000h ; Copy-key handler

 @F1KEY ; Define source region for copy ops
     L1 REF :: EDCUR
        LOD L1
     L2 REF :: EDBUF
        ADD L2 L1
     L4 GET L2

     L1 REF :: ED_SRC
     L3 SET :: CYF_Str16BufPtr
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

-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------

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
   L2 STO  E ; Update cursor offset if not first pos

 @DONE
 RET

-------------------------------------------------------------------------------

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
   L2 STO  E ; Update cursor offset if not first pos

 @DONE
 RET

-------------------------------------------------------------------------------

 @ARRLEFT ; Go to previous char

       L1 REF :: EDBUF ; Editor buffer base address
       L2 REF :: EDCUR ; EDCUR is the linear offset of the cursor into EDBUF1
          LOD L2
       L3 ADD L1 L2    ; Effective address of cursor within EDBUF1

  L2 ELS >QUIT
     GET L2 -1
     GET L3 -1
  E REF :: EDCUR
  L2 STO  E ; Update cursor offset if not first pos
 @QUIT
 RET

-------------------------------------------------------------------------------

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
  L2 STO  E ; Update cursor offset if not last pos

 @QUIT RET ;Copy source, overwrite dst region

-------------------------------------------------------------------------------

 @INSKEY
     L1 SET :: CYF_Str16BufPtr
        JSR L1 L7 :: 8T3_strLen16 ; strlen of buffer in L7
     L2 REF :: ED_DST1
     L3 REF :: ED_DST2
        JSR L2 L3 :: ORDER
        SUB L3 L2           ; Size of marked region
     E REF :: EDBUF
     L4 REF :: EDBUFSIZE
        GET L4 -1
        ADD L4  E           ; Last char in current edit buffer
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

-------------------------------------------------------------------------------

Delete a char by contracting the buffer into it

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

-------------------------------------------------------------------------------

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
  L2 STO  E ; Update cursor offset if not first pos
     JSR L3 L4 :: >SHUP
 @QUIT
 RET

-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------

 @EDLDBEACH

    ; Block 4096-8192: Beach buffers

          L1 REF :: EDBUF    ; Editor buffer base address
          L4 INT 0           ; First block high order (a 16-bit number!)
          E REF :: EDBEACH
          L2 SHL  E 3
             SHL  E 1
             ADD L2  E        ; Multiply by 10
          E REF :: BEACHBASE ; Base block for beaches region
             ADD L2  E        ; First block low order (16 bit)
          L3 SET :: 10        ; Number of blocks = 10 blocks / 1 beach
       @1    JSR L2 L1 L4 :: SPI_RDBLK
             GET L2 +1
          L3 REP <1

 RET

-------------------------------------------------------------------------------

 @EDSTBEACH

    ; Block 4096-8192: Beach buffers

          L1 REF :: EDBUF    ; Editor buffer base address
          L4 INT 0           ; First block high order (a 16-bit number!)
          E REF :: EDBEACH
          L2 SHL  E 3
             SHL  E 1
             ADD L2  E       ; Multiply by 10
          E REF :: BEACHBASE ; Base block for beaches region
             ADD L2  E        ; First block low order (16 bit)
          L3 SET :: 10        ; Number of blocks = 10 blocks / 1 beach
       @1    JSR L2 L1 L4 :: SPI_WRBLK
             GET L2 +1
          L3 REP <1

 RET

-------------------------------------------------------------------------------

 @EDINSBEACH

          L4 INT 0           ; First block high order (a 16-bit number!)
          E REF :: EDBEACH
          L3 SHL  E 3
             SHL  E 1
             ADD L3  E       ; Multiply by 10
          E REF :: BEACHBASE ; Base block for beaches region
             ADD L3  E        ; Final block low order (16 bit)

          L5 SET :: 9990
             ADD L5  E       ; First target block (Highest block in use))
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

-------------------------------------------------------------------------------

 @EDDELBEACH

          L4 INT 0           ; First block high order (a 16-bit number!)

          E REF :: EDBEACH
          L3 SHL  E 3
             SHL  E 1
             ADD L3  E       ; Multiply by 10
          E REF :: BEACHBASE ; Base block for beaches region
             ADD L3  E       ; First target block low order (16 bit)

          L7 INT 10
             ADD L7 L3       ; First source block (1 beach after target block)

          L5 SET :: 9990     ; 999 beaches
             ADD L5  E      ; Final source block (Highest block in use)

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

-------------------------------------------------------------------------------

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














