

CYF, a native, self-hosting assembler and pattern matcher.
The following batch of functions do 2-pass assembly, symbol table management
and pattern matching.
Each assembly pattern writes object code by means of the CYF_putObjCode function into
a block buffer. If the buffer is full, it is flushed to the card image.
In this way, the assembler pass can generate more than 64k object code
to include overlays.

 @FAKESYM        BUF 24
 DEF CYF_SymSize     24
 DEF CYF_TokenSize   64
 
 @CYF_TokenBuf    9000h
 *CYF_SymTabRO    A000h       ; Read Only
 *CYF_SymTabBase  A000h       ; Addr of beginning of symbol table
 *CYF_SymTabPos   A000h       ; Addr of end of symbol table

 @CYF_SrcMode         0       ; Source mode: 0: FOLDER, 1: FILE
 @CYF_ObjMode         0       ; Object mode: 0: SD card, 1: Memory
 @CYF_Pass            0
 @CYF_Line            0

 @CYF_SrcBlk          0

 @CYF_ObjFileBlk      0 
 @CYF_ObjBufPos       0
 @CYF_ObjBase         0
 @CYF_ObjAddr         0
 @CYF_ObjStartAddr    0

 @CYF_LeftOp          0

 @CYF_ObjCodeBufPtr   0

 @CYF_Str16BufPtr     0
 @CYF_Str8BufPtr      0

 @CYF_SplatterPtr   355 ; Change this in hen: hBeam, hReap, hProc

-------------------------------------------------------------------------------

Assemble all files in src folder combined (pass 1 file 1..n, pass 2 file 1..n)

  *CYF_sasm
              JSR :: 8T3_msg :: 'Assembling source files ...' 10 0

           DR SET :: SYS_SrcPath
              JSR DR L1 :: PFS_pathToBix
           DR SET :: SYS_ObjPath
              JSR DR L2 :: PFS_pathToBix
           L4 SET :: PFS_ObjFName

              JSR L2 L4 L6 :: PFS_forceFile   ; replace boot file

           DR INT 0                           ; Base address
           DR PER :: CYF_ObjBase
           DR INT 0                           ; Start address
           DR PER :: CYF_ObjStartAddr
           DR INT 0
           DR PER :: CYF_ObjMode              ; To SD card
           DR INT 0
           DR PER :: CYF_SrcMode              ; From folder
           L1 PER :: CYF_SrcBlk
           L6 PER :: CYF_ObjFileBlk

              JSR :: CYF_setup
              JSR L6 :: CYF_post

      RET

-------------------------------------------------------------------------------

A1 Head bix of kernel file

  *CYF_post

           JSR :: 8T3_msg :: 'Preparing kernel' 10 0

        L1 REF :: PFS_STATE_BUF       ; Mark boot file as primary kernel
           JSR :: PFS_getState
           GET L1 PFS_O_ANY_parent
        A1 STO L1
           JSR :: PFS_putState


        L6 GET A1
           JSR L1 :: 8T3_claim
           JSR L1 L6 :: PFS_rdBlock

        L3 INT PFS_OffsFData          ; Don't forgot to skip block header!
           ADD L3 L1
        
        L2 REF :: CYF_ObjAddr
           GET L2 -1
        L2 STO L3 +3

        ; L2 SET :: TEA ; Does not work, not yet defined at CYF assembly time

           JSR L1 L6 :: PFS_wrBlock
           JSR L1 :: 8T3_cede
  RET

-------------------------------------------------------------------------------

 *CYF_setup

            JSR L6 :: 8T3_claim
         L6 PER :: CYF_ObjCodeBufPtr

            JSR L5 :: 8T3_claim
         L5 PER :: CYF_Str8BufPtr

            JSR L4 :: 8T3_claim
         L4 PER :: CYF_Str16BufPtr

            JSR :: CYF_control      

         L1 REF :: CYF_ObjAddr             ; Only if Save persistent symbols     
         L1 ELS >0
      ;  L2 REF :: CYF_ObjStartAddr
      ;      SUB L1 L2
      ;      GET L1 -1
      ;   L1 PER :: TEA_Here

          E GET L1
       @0   JSR :: 8T3_prHex
            JSR :: 8T3_msg :: ' words generated' 10 0

      ;      JSR :: CYF_toTea              ; Save persistent symbols

            JSR :: 8T3_msg :: 'SymTab: ' 0
         L7 REF :: CYF_SymTabPos
            JSR L7 :: 8T3_hex
            JSR :: 8T3_msg :: 10 0
    
            JSR L6 :: 8T3_cede
            JSR L5 :: 8T3_cede
            JSR L4 :: 8T3_cede        

            JSR :: 8T3_msg :: 'Culling SymTab ... ' 0
         L6 GET L7
            JSR :: STCULL                  ; Leave only * labels
         L7 REF :: CYF_SymTabPos           ; Update symbol table size    
            
            JSR :: 8T3_msg :: 10 'SymTab: ' 0
            JSR L7 :: 8T3_hex
            JSR :: 8T3_msg :: 10 0

     @2  L7 EQR L6                         ; Loop zero out culled portion           
         DR THN >3
         DR INT 0      
         L7 STOS
            BRA <2
   
       @3   RET

-------------------------------------------------------------------------------

                                 ; SymTab culling
 @STCULL                         ; A1 symbol table max addr
     
         L1 REF :: CYF_SymTabBase    ; Beginning of symbol table
         L6 REF :: CYF_SymTabPos
         L3 INT CYF_SymSize

 @CHECK  L1 EQR L6              ; Check if last symbol
         DR THN >QUIT       

         L2 LOD L1 +0           ; Check symbol type
         L2 ELS >QUIT           ; End of table

         L2 EQL 6               ; Labels (@ and *)  
         DR ELS >KEEP           ; Keep other types
         L2 LOD L1 +1           ; Check subtype
         L2 ELS >CULL           ; Reject @ labels 
     
    @KEEP   ADD L1 L3           ; Keep
            BRA <CHECK   

  @QUIT  L1 PER :: CYF_SymTabPos
            RET
  
  @CULL  L4 GET L1
         L5 ADD L4 L3           ; Remove this entry by shifting into it
         L7 GET L6
            SUB L6 L3
   @CUT  L5 EQR L7
         DR THN <CHECK
         L5 LODS
         L4 STOS
            BRA <CUT

-------------------------------------------------------------------------------

@CYF_clearSymtab

   L1 REF :: CYF_SymTabRO
   L2 SET :: FFFFh
   L3 INT 0

     @1 L3 STO L1
           GET L1 +1
        L1 EQR L2
        DR ELS <1   

 RET

-------------------------------------------------------------------------------

This function is called from CYF_getSymbol if a name
could not be found in SymTab.

A1 Persist name string ptr, cell string
A2 Return pointer to SYMBOL entry
E OUT 0: Not found / 1: Found

 @CYF_searchTea

        L4 GET A1
        L3 SET :: FAKESYM             ; Fake SymTab entry as return value 
        L1 REF :: TEA_Here

    @1   E LOD L1

         E ELS >3                     ; End of dict
           ADD L1 E                   ; Point at beginning of previous symbol
        L2 GET L1
           GET L2 +1                  ; TEA Type
         E LOD L2
         E EQL TEA_CYF_Symbol
        DR ELS <1

           GET L2 +1                  ; Skip to symbol header
         E LOD L2                     ; SYMBOL type 
         E STO L3
         E LOD L2 +1                  ; SYMBOL subtype
         E STO L3 +1
         E LOD L2 +2                  ; SYMBOL group
         E STO L3 +2
         E LOD L2 +3                  ; SYMBOL index
         E STO L3 +3
           GET L2 +4                  ; Skip to symbol name field
           GET L3 +4

           JSR L2 L3 :: 8T3_toStr16   ; Copy SYMBOL name
        L7 INT 0                      ; Termination char
           JSR L4 L3 L7 :: 8T3_strCmp
         E ELS <1

        A2 REF :: FAKESYM             ; Found
         E INT 1
           RET 
   
   @3    E INT 0                      ; Not found
           RET

-------------------------------------------------------------------------------

Assemble all files in src folder separately (file 1 pass 1 2, file 2 pass 1 2)

A1 Preserve folder block index

 *CYF_spatter

           JSR :: 8T3_msg :: 10 'Spatter assembly ...' 10 10 0

           JSR L3 :: 8T3_claim

        DR SET :: SYS_ObjPath
           JSR DR L2 :: PFS_pathToBix
        L4 SET :: PFS_ObjFName
           JSR L2 L4 L6 :: PFS_forceFile   ; replace boot file

        DR INT 0                           ; Base address
        DR PER :: CYF_ObjBase
        DR INT 0                           ; Start address
        DR PER :: CYF_ObjStartAddr
        DR INT 0
        DR PER :: CYF_ObjMode              ; To SD card
        DR INT 1
        DR PER :: CYF_SrcMode              ; From File
        L6 PER :: CYF_ObjFileBlk

           JSR :: ASM :: "/sys/src/batch/8T3.asm" 0
         ; JSR :: ASM :: "/sys/src/batch/AGE.asm" 0           
           JSR :: ASM :: "/sys/src/batch/PFS.asm" 0
           JSR :: ASM :: "/sys/src/batch/CYF.asm" 0
           JSR :: ASM :: "/sys/src/batch/ECO.asm" 0
           JSR :: ASM :: "/sys/src/batch/TEA.asm" 0

    @2     JSR L3 :: 8T3_cede
           JSR L6 :: CYF_post  
           RET

-------------------------------------------------------------------------------    

  @ASM
               JSR L1 :: 8T3_claim   ; Helper function
            L5 INT 0

        @0  L2 PULL
               JSR L1 L5 L2 :: 8T3_stByte
               GET L5 +1
            L2 THN <0      
  
               JSR L1 L2 :: PFS_pathToBix
               JSR L1 :: 8T3_prStr8
               JSR :: 8T3_msg :: 10 0

            L2 PER :: CYF_SrcBlk
               JSR :: CYF_setup        
               JSR :: 8T3_msg :: 10 0

            DR REF :: CYF_ObjAddr
            DR PER :: CYF_ObjStartAddr

            DR REF :: CYF_SymTabPos
            DR PER :: CYF_SymTabBase

               JSR L1 :: 8T3_cede
               RET

-------------------------------------------------------------------------------

 @TEMPVAR 0
 @CYF_toTea

             JSR :: 8T3_msg :: 'Persistent symbols to TEA' 10 0

          L1 REF :: TEA_Here      ; Top of dictionary (beginning of list)
          L4 GET L1               ; A cursor
          L2 REF :: CYF_SymTabRO  ; First entry of symbol table
          L2 PER :: <TEMPVAR
          
          L3 REF :: CYF_SymTabPos ; Last entry

             GET L1 +1            ; Skip offset to previous entry

     @1    E LOD L2 +0            ; Only type 6 labels
           E EQL 6
          DR ELS >6 
           E LOD L2 +1            ; Only subtype 1 persistent (* labels)
           E EQL 1
          DR ELS >6 

           E INT TEA_CYF_Symbol   ; Set dict type
           E STO L1
             GET L1 +1

           L7 INT 4               ; Copy symbol, 4 cells
     @2    E LOD L2
           E STO L1
             GET L1 +1
             GET L2 +1
          L7 REP <2

          L5 INT CYF_SymSize      ; Size in cells of each symbol
             GET L5 -4            ; Name max length
  
     @3    E LOD L2               ; First character cell
             SHL E 8
             GET L2 +1
           E ELS >5

          L6 LOD L2               ; Second character cell
          L7 SET :: FFh
             AND L6 L7
             IOR E L6
           E STO L1
             GET L1 +1
             GET L2 +1

     @4      GET L5 -1
          L5 ELS >5               ; Quit copying if max characters
          L6 THN <3               ; or NULL

     @5    E INT 0
           E STO L1               ; Terminate name string
             GET L1 +1
           
           E SUB L4 L1            ; Compute negative offset to prev entry
           E STO L1               ; Finish dict entry
          L1 PER :: TEA_Here
          L4 GET L1               ; Pull cursor to fresh entry 
             GET L1 +1

     @6   L2 REF :: <TEMPVAR
          L5 INT CYF_SymSize      ; Size in cells of each symbol
             ADD L2 L5            ; Point to next symbol
          L2 PER :: <TEMPVAR   
          L2 GTR L3
          DR THN >7               ; Drop through if all done
             JUMP :: <1

     @7      RET

-------------------------------------------------------------------------------

    @CYF_reset  ; Reset state per pass

          E REF :: CYF_ObjMode
          E THN >MEM

              @BLK  L6 REF :: CYF_SymTabBase      ; Assembling to card
                    L6 PER :: CYF_SymTabPos       ; Reset symt insert index
                     E INT 0
                     E PER :: CYF_ObjBufPos
                       BRA >1

              @MEM   E REF :: CYF_SymTabBase          ; Assembling to memory
                     E PER :: CYF_SymTabPos
    
              @1    L1 REF :: CYF_SrcBlk
                    DR REF :: CYF_SrcMode
                    DR THN >A
                       JSR L1 :: PFS_FOLDER_init
                       BRA >2
              @A       JSR L1 :: PFS_FILE_init        
             
      @2  E REF :: CYF_ObjStartAddr
          E PER :: CYF_ObjAddr

          E INT 1
          E PER :: CYF_Line

            RET

-------------------------------------------------------------------------------

This function provides lines of source text to the assembler. It transparently
handles various possible sources, so that the assembler does not have to know
or care for where the lines come from.

A1 Preserve line buffer

 @CYF_getSrcLine
  
             L5 REF :: CYF_Str8BufPtr
             L7 REF :: CYF_SrcMode
                JSR L5 L6 L7 :: PFS_FILE_getLine   ; L6 is dummy (chars read)
              E THN >1

             L6 GET A1
                JSR L5 L6 :: 8T3_toStr16
              E INT 0

            @1  RET

-------------------------------------------------------------------------------

This function assembles the source text twice.
The second pass is necessary to resolve forward references.
The text is copied and assembled line by line.
Counters for pass and line number are maintained for handler error reporting.

    @CYF_control  E INT 1
                  E PER :: CYF_Pass
                 L6 REF :: CYF_Str16BufPtr
                    JSR :: 8T3_msg :: 'Pass ' 0

    @PASS   E REF :: CYF_Pass                ; Print the pass number via TEA
              JSR :: 8T3_prUDec
            E INT 32
              JSR :: 8T3_putC
              JSR :: CYF_reset

    @LINE     JSR L6 :: CYF_getSrcLine       ; Get one line of source text
            E THN >1                         ; We got NULL / EOF

            E REF :: CYF_Line                ; Count empty lines too
              GET E +1
            E PER :: CYF_Line

             E LOD L6                        ; First ASCII char of line
             E EQL ASC_space                 ; Must be space...
            DR THN >PARSE
             E EQL ASC_tab                   ; or TAB
            DR ELS <LINE

    @PARSE  L2 SET :: CYF_AsmTokens          ; Structure with pattern ptrs
               JSR L2 :: CYF_parse
               BRA <LINE

    @1   E REF :: CYF_Pass
           GET E +1
         E PER :: CYF_Pass
         E EQL 3
        DR THN >2
           BRA <PASS

      @2  
         L1 REF :: CYF_ObjMode
         L1 THN >Q                           ; Don't flush if memory target
            JSR :: 8T3_msg :: 10 'Flushing' 10 0
            JSR :: CYF_flushObjFile       
        @Q   
       RET

-------------------------------------------------------------------------------

This function is called by pattern handler functions for each cell of
object code generated. Depending on mode, write object code cell to
memory target address or into SD card buffer.

  @CYF_putObjCode  ; A1 Addr, A2 Obj code

          E REF :: CYF_Pass
          E EQL 1
         DR THN >SKIP ; No code gen during first pass

         L1 REF :: CYF_ObjMode
         L1 THN >MEM

  @CARD  L1 REF :: CYF_ObjCodeBufPtr ; Write a data value to a block buffer
         L3 REF :: CYF_ObjBufPos     ; Set in _setup to PFS_OffsFData
            ADD L1 L3
         A2 STO L1
         L6 SET :: 255               ; Buffer full position
         L3 EQR L6
            GET L3 +1
         L3 PER :: CYF_ObjBufPos
         DR ELS >SKIP
            JSR :: CYF_flushObjFile
            BRA >SKIP                ; This took days!

   @MEM  A2 STO A1
   @SKIP    RET

-------------------------------------------------------------------------------

     @CYF_flushObjFile

               L1 REF :: CYF_ObjCodeBufPtr       ; Flush object code buffer
               L2 REF :: CYF_ObjFileBlk          ; To this block
               L3 REF :: CYF_ObjBufPos           ; Number of data cells
                 
                E SET :: 256
               L3 EQR E
               DR THN >0 
           
              L5 ADD L1 L3              
               E INT 0
              L4 SET :: 256
                 ADD L4 L1
           @Y  E STO L5
                 GET L5 +1
              L5 EQR L4
              DR ELS <Y

              @0  JSR L1 L2 L3 :: PFS_bufToFile
                E PER :: CYF_ObjFileBlk

         ;  @A  DR REF :: CYF_SplatterPtr
         ;         JSR L1 DR :: PFS_wrBlock
         ;         GET DR +1
         ;      DR PER :: CYF_SplatterPtr

                E INT 0
                E PER :: CYF_ObjBufPos
                  RET

-------------------------------------------------------------------------------

    @CYF_parse                       ; A1 ptr to dictionary

    L4 REF :: CYF_Str16BufPtr        ; Expects line string
    L6 REF :: CYF_TokenBuf
    L1 GET L6

     E INT 0
     E STO L6                        ; Mark token buffer empty
       JSR L6 L4 :: CYF_tokenize     ; Create token for each word, number, etc

    @DOTOKEN                         ; Now determine token type
    E LOD L1                         ; Type in E
    E ELS >MATCH                     ; Type 0 means end of list

           E EQL 4  ; If string
          DR THN >1
          L2 GET A1 +1
             JSR L1 L2 :: CYF_testIfDictEntry
           E THN >1
             JSR L1 :: CYF_testIfLabelDef
           E THN >1
             JSR L1 :: CYF_testIfLabelRef
           E THN >1
             JSR L1 :: CYF_testIfNum
           E THN >1
             JSR L1 :: CYF_testIfWord

      @1   E SET :: CYF_TokenSize
             ADD L1 E                ; Point to next token
             BRA <DOTOKEN            ; Repeat for all tokens

    @MATCH                           ; Match token seq, call pattern handler

      L3 LOD A1                      ; Pointer to pattern table
         JSR L6 L3 :: CYF_match      ; L6 advances in token buffer
      L3 ELS >DONE                   ; None of the patterns matched
      L4 LOD L6                      ; Handler change L6, skips matched pattern
      L4 THN <MATCH     

    @DONE RET                        ; E handler return code, 7Fh for no match

-------------------------------------------------------------------------------

This function creates a list of token structures, each corresponding
to a contiguous, non-whitespace "word" in the current line of source text.

A1 IN Pointer to empty token buffer
A2 IN Pointer to input line

    @CYF_tokenize
    L1 GET A2                   ; Buffer contains the source line to tokenize
    L2 GET A1                   ; Base pointer for the token buffer
    L3 GET L2

    @NEWTOKEN
    L3 GET L2
       JSR L1 :: 8T3_skipSpace  ; Advance L1 to next non-space char

    L6 LOD L1
       ELS >CLOSE
    L6 EQL ASC_semicolon        ; Check if beginning of ; comment
    L6 INT 0                    ; Fake 0 as if end of line reached
    DR THN >CLOSE 
    L6 SET :: FFFFh             ; Force a non-0 type
    L6 STO L2 +0
       GET L2 +4                ; Skip type, subtype, group, index

       JSR L1 L2 :: CYF_testIfStr16  ; Handle "...", advance L1 and L2
       JSR L1 L2 :: CYF_testIfStr8   ; Handle '...', advance L1 and L2

    E EQL 1
    DR THN >CLOSE

    @1 L6 LOD L1                ; Test for NULL
       L6 ELS >CLOSE
       L6 EQL ASC_space         ; Same for space
       DR THN >CLOSE
       L6 EQL ASC_tab           ; Same for TAB
       DR THN >CLOSE
       L6 STO L2
          GET L1 +1
          GET L2 +1
          BRA <1

    @CLOSE                      ; End of token
    L4 INT 0
    L4 STO L2                   ; Store string terminator
    L4 SET :: CYF_TokenSize
    L2 ADD L3 L4                ; Make L2 point to next token structure
    L6 THN <NEWTOKEN            ; Line string closed by null char
    L6 STO L2                   ; Terminate token sequence (type 0 marker)

       RET      

-------------------------------------------------------------------------------

The function matches tokens against patterns from the current token onwards.
It returns a pointer to the next token to be matched in A1.

A1 IN Ptr to token, update
A2 IN Ptr to pattern structure, change

    @CYF_match    L2 GET A1
                  L3 GET A2
                  L7 INT 0     ; Best match length so far
                  A2 INT 0     ; Best match pattern pointer so far
                  L6 LOD L3
                  L1 GET L3
                  L4 INT 0     ; Current match length

    @NEXT
       JSR L6 L2               ; Comparison result in E
       >CYF_checkToken
    DR SET :: CYF_TokenSize
       ADD L2 DR               ; Point to next token
     E ELS >FAIL               ; Token doesn't match - try next pattern

       GET L4 +1               ; Add to match length
       GET L3 +1               ; Assume pattern not finished yet
    L6 LOD L3
    L6 ELS >SUCC               ; End of pattern: success but try to find longer
     E LOD L2
       THN <NEXT               ; Check if no more tokens (token type 0)
      
      ; Fall through to fail, not enough tokens for pattern

    @FAIL L2 GET A1            ; Restart at first token
          L4 INT 0             ; Reset match length
             GET L1 +7         ; Point to next pattern
             GET L1 +1
          L3 GET L1            ; Fresh pointer to current pattern
          L6 LOD L3            ; If first element is non-0, check pattern
             THN <NEXT
          L7 THN >BEST         ; If a matching pattern was found
          A2 INT 0             ; Result code: No matching pattern
           E SET :: 7Fh        ; Fake a handler return code (no match)
             BRA >DONE

    @SUCC L6 SUB L7 L4         ; See if longer than previous match
          DR THN <FAIL
          L7 GET L4            ; Store as new best match
          A2 GET L1
             BRA <FAIL
    
    @BEST  
          L4 REF :: CYF_ObjBase
          L5 REF :: CYF_ObjAddr 

           E INT 1             ; Sanitize handler return code to "normal"
          L3 LOD A2 +6         ; Get handler ID (if handler for several)
          DR LOD A2 +7         ; Get pointer to pattern handler

       JSR L2 L4 L5 L3 :: 0    ; JSR address in D

          A1 GET L2            ; A1 now points to *next* token to be matched
          
          L4 PER :: CYF_ObjBase
          L5 PER :: CYF_ObjAddr

       @DONE RET

-------------------------------------------------------------------------------

This is a helper function for CYF_match. It matches one token against one
pattern element.

A1 IN Current pattern element
A2 IN Pointer to token

    @CYF_checkToken
    L1 INT 15
    L2 GET A1
    L3 GET A2

    E AND L2 L1     ; Check expected type
      SHR L2 4
    E ELS >0        ; Type 0: match any type
   L4 LOD L3 +0     ; Compare to token element type
      SUB E L4
    E THN >FAIL     ; Pattern fails, types don't match for current element

 @0 E AND L2 L1     ; Check expected subtype
      SHR L2 4
    E ELS >1        ; Subtype 0: match any subtype
   L4 LOD L3 +1     ; Compare to token element subtype
      SUB E L4
    E THN >FAIL     ; Pattern fails, subtypes don't match

 @1 E AND L2 L1     ; Check expected group
      SHR L2 4
    E ELS >2        ; Group 0: match any group but not any index
   L4 LOD L3 +2     ; Compare to token element group
      SUB E L4
    E THN >FAIL     ; Pattern fails, groups don't match
   L6 INT 8
   L6 AND E L6      ; Check if negative (8-D)
   L6 ELS >CONT     ; Group 1-7: match any index

 @2 E AND L2 L1     ; Check expected index
   L4 LOD L3 +3     ; Compare to token element index
      SUB E L4
      THN >FAIL     ; Pattern fails, indices don't match

 @CONT E INT 1
         RET

 @FAIL E INT 0
         RET

-------------------------------------------------------------------------------

This is a subordinate function used by CYF_tokenize. It tests whether the
current character during tokenization is an inch-mark (") indicating the
beginning of a string literal. In this case, the token must not break at
a space character, but runs until the trailing (").

A1 IN Pointer to current character of the source text line, update
A2 IN Pointer to string entry of current token, update

E OUT 0: No group found, continue / 1: Found a group, close token

    @CYF_testIfStr16
    L4 INT 0                    ; Assume no group found
    L2 LOD A1
       ELS >DONE                ; String terminator (null), caller handles it

       L2 EQL ASC_doublequote   ; Test if "
       DR ELS >DONE

          GET A1 +1             ; Skip "
        E INT 4
       L5 GET A2 -4
        E STO L5                ; Set token type to string
        E INT 1
       L5 GET A2 -2
       E STO L5                 ; Set group to 1  SHOULD THIS NOT SeT SUBTYPE?

    @FOUND L4 INT 1
    @COPY
       L2 LOD A1
          ELS >DONE             ; Test if line end

       L2 EQL ASC_doublequote   ; Test if "
       DR THN >FIX

       L2 STO A2
          GET A1 +1
          GET A2 +1
          BRA <COPY

    @FIX GET A1 +1              ; Skip trailing "
    @DONE
       E GET L4
         RET

-------------------------------------------------------------------------------

This is a subordinate function used by CYF_tokenize. It tests whether the
current character during tokenization is (') indicating the
beginning of a string literal. In this case, the token must not break at
a space character, but runs until the trailing (').

A1 IN Pointer to current character of the source text line, update
A2 IN Pointer to string entry of current token, update

E OUT 0: No group found, continue / 1: Found a group, close token

    @CYF_testIfStr8
    L4 INT 0 ; Assume no group found
    L2 LOD A1
       ELS >DONE                ; String terminator (null), handles it

       L2 EQL ASC_singlequote   ; Test if opening '
       DR ELS >DONE

          GET A1 +1             ; Skip '
        E INT 4
       L5 GET A2 -4
        E STO L5                ; Set token type to string
        E INT 1
       L5 GET A2 -2
        E STO L5                ; Set group to 1  SHOULD THIS NOT SeT SUBTYPE?

    @FOUND L4 INT 1
    @COPY
       L2 LOD A1                ; First char
          ELS >DONE             ; Test if line end
       L2 EQL ASC_singlequote   ; Test if closing '
       DR THN >FIX
          GET A1 +1

       ; DR INT 3
       DR INT 0
          SHL L2 8              ; If missing 2nd char, use ASC 3 (End of Text)
          IOR L2 DR
       L3 LOD A1                ; Second char
       L3 ELS >DONE             ; Test if line end
       L3 EQL ASC_singlequote   ; Test if closing '
       DR THN >A
          GET A1 +1

       DR SET :: FF00h          ; Clear lower nibble (ASC 3 set above)
          AND L2 DR
          IOR L2 L3
       L2 STO A2
          GET A2 +1
            BRA <COPY

    @A L2 STO A2                ; Flush incomplete cell
          GET A2 +1

    @FIX GET A1 +1              ; Skip trailing '
    @DONE
       E GET L4
         RET

-------------------------------------------------------------------------------

This is a subordinate function used by ASM_EVALUATE. It tests whether the
given token is a number (-123, 4Eh).

A1 IN Pointer to current token

E OUT 0: Not recognized / 1: Recognized

    @CYF_testIfNum
    L1 GET A1 +4              ; Pointer to string in current token
       JSR L1 L2 :: PARSENUM
     E THN >FAIL

    L2 STO A1 +3              ; Store the number as token "index"
     E INT 3
     E STO A1 +0              ; Set token type to number
     E INT 2
     E STO A1 +2              ; Set group to 2 (same as DEF numbers)
    L7 INT 1                  ; Number was found

        BRA >SUCC

    @FAIL L7 INT 0
    @SUCC
   E GET L7
      RET

-------------------------------------------------------------------------------

This is a subordinate function used by ASM_EVALUATE. It tests whether the
given token is a register or opcode mnemonic (L6, ADD).

A1 IN Pointer to current token, A2 ptr to dictionary

E OUT 0: Not recognized / 1: Recognized

    @CYF_testIfDictEntry
    L1 GET A2
    L3 GET L1
    L4 GET A1 +4
    L5 INT 12                ; Size of string buffer in dictionary entry

    @1 L2 LOD L3             ; Type 0 means end of table
          ELS >FAIL
          GET L3 +4          ; Skip numbers (4 cells)
       L6 INT 0
          JSR L3 L4 L6 :: 8T3_strCmp
        E THN >FOUND
          ADD L3 L5
          THN <1

    @FAIL
    E INT 0
      BRA >DONE

    @FOUND
    E INT 1

   L7 SET :: CYF_TokenSize   ; Copy last two words from DICT to end of token
      GET L7 -6              ; -4 since pre-incremented -2 picks penult item
      GET L5 -2
      ADD L7 L4
      ADD L5 L3
   L6 LOD L5                 ; Copy penult word
   L6 STO L7
   L6 LOD L5 +1              ; Copy last word
   L6 STO L7 +1

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

-------------------------------------------------------------------------------

This is a subordinate function used by ASM_EVALUATE. It tests whether the
given token is a label definition (@LABEL, *LABEL).

A1 IN Pointer to current token

E OUT 0: Not recognized / 1: Recognized

    @CYF_testIfLabelDef

    L1 LOD A1 +4
    L7 INT 0                  ; Assume subtype = @
    L1 EQL ASC_atsign         ; First char of label definition must be "@"
    DR THN >1
    L7 INT 1                  ; Assume subtype = *
    L1 EQL ASC_star           ; or dollar sign
    DR ELS >FAIL

 @1 L1 GET A1 +4
    L2 INT 1
       JSR L1 L2 :: CUTLEFT   ; Remove "@/*" character

    L6 INT 6
    L6 STO A1                 ; Set token type
    L7 STO A1 +1              ; Set token subtype
    L6 INT 1
    L6 STO A1 +2              ; Set token group

     E INT 1
       BRA >DONE

    @FAIL E INT 0
    @DONE
       RET

-------------------------------------------------------------------------------

Creates a new symbol table entry, copying data from the token parameter.

A1 IN Token pointer, keep!

    @CYF_newSymbol
    L4 GET A1
    L2 INT CYF_SymSize        ; Max symbol table entry size
    L3 GET L2
    L5 REF :: CYF_SymTabPos
    L7 GET L5

    @COPY
    L6 LOD L4
    L6 STO L5
       GET L4 +1
       GET L5 +1
    L2 REP <COPY

       ADD L7 L3              ; Point to next entry

    L7 PER :: CYF_SymTabPos
    L6 INT 0
    L5 GET L7 -1
    L6 STO L5                 ; Force truncate runaway tokens

       RET

-------------------------------------------------------------------------------

Symbol table look-up, return value in E.
A1 IN Token pointer
A2 OUT Pointer to symbol entry
E OUT 0: Not found / 1: Found

    @CYF_getSymbol
    L2 INT CYF_SymSize                    ; Max symbol table entry size
    L4 INT 0
    L5 GET A1 +4

    L1 REF  :: CYF_SymTabRO
       @1 L3 LOD L1
             ELS >FAIL

          @COMPARE
          L7 GET L1 +4                    ; Prepare 8T3_strCmp arg
             JSR L7 L5 L4
             8T3_strCmp
             ADD L1 L2                    ; Point to next symbol
           E ELS <1                       ; E 8T3_strCmp result code
          A2 GET L7 -4
             BRA >SUCC

    @FAIL  E INT 0
           E SET :: 0
             JSR L5 DR :: CYF_searchTea   ; Check persistent symbols too
          A2 GET DR
          L3 REF :: CYF_Pass              ; Error message
          L3 EQL 2
          DR ELS >SUCC
             JSR :: 8T3_msg :: 10 'Missing symbol ' 0
             JSR L5 :: 8T3_prStr16

    @SUCC    RET     

-------------------------------------------------------------------------------

A1 IN Pointer to current token
E OUT 0: Not recognized / 1: Recognized

    @CYF_testIfLabelRef

    L1 GET A1
    L7 INT 7                ; Default type 7
    L5 INT 1                ; Default cut 1 char

    L2 LOD L1 +4
    L2 EQL ASC_less         ; First char must be "<" or ">"
    DR ELS >2               ; else check if  ">"
    L2 LOD L1 +5
    L2 EQL ASC_less         ; If repeated, relative REF (type F)
    DR ELS >1               ; else abs REF (default type 7)
    L7 INT Fh
    L5 INT 2                ; Cut 2 chars
 @1 L6 INT 1
    L6 STO A1 +1            ; Set token subtype (backward ref)
       BRA >COMMON

 @2 L2 EQL ASC_greater      ; Check if ">"
    DR ELS >FAIL
    L2 LOD L1 +5
    L2 EQL ASC_greater      ; If repeated, relative REF (type F)
    DR ELS >3               ; else abs REF (default type 7)
    L7 INT Fh
    L5 INT 2
 @3 L6 INT 2
    L6 STO A1 +1            ; Set token subtype (forward ref)

  @COMMON
      GET L1 +4
      JSR L1 L5 :: CUTLEFT  ; Remove the "<" or ">" characters

   L7 STO A1                ; Set token type, subtype set above
   L6 INT 1
   L6 STO A1 +2             ; Set token group

    E INT 1
      BRA >DONE

    @FAIL E INT 0
    @DONE   RET

-------------------------------------------------------------------------------

Given the current assembly
address (Effective), it searches for the nearest matching symbol in the given
direction "<" or ">". It stores the (absolute) distance in the token.

A1 IN Pointer to token
A2 IN Base
A3 IN Effective
A4 OUT Pointer to best match symbol
E OUT Best absolute displacement found

    @CYF_nearest
    L2 SET :: FFFFh        ; Best distance infinite so far
    L7 LOD A1 +1           ; Type of reference, 1:"<" and 2:">"
    L3 GET A1 +4           ; Point to token string
    L1 REF :: CYF_SymTabRO ; L1 is pointer to first symbol in table

    @NEXT                  ; L1 points to beginning of current symbol
    L6 LOD L1              ; Check if end of symbol table
    L6 ELS >DONE
       GET L1 +4           ; Skip to string part
     E INT 6
       SUB E L6
       THN >DIFFER         ; Has to be a label entry

       L6 INT 0            ; Compare 0 terminated strings
          JSR L1 L3 L6
          8T3_strCmp
        E ELS >DIFFER

       L5 GET L1 -1
       L5 LOD L5           ; Get the reference address from symbol index
       L6 INT 1
          SUB L6 L7
       L6 THN >FWD

            L6 SUB A3 L5   ; Test if really before
            L4 SUB L5 A3
               
               BRA >1

     @FWD   L6 SUB L5 A3   ; Test if really after
            L4 SUB A3 L5
     @1

         E GET DR          ; Check last subtr carry
        A3 ELS >SUCC
         E THN >DIFFER

          @SUCC
         E SUB L6 L2       ; Compare to current best distance
         E GET DR
         E THN >DIFFER

       L2 GET L6           ; Update closest distance
       A4 GET L1 -4        ; Keep a pointer to it

    @DIFFER
  E INT CYF_SymSize
    GET L1 -4              ; Reset to beginning
    ADD L1  E              ; Point to next entry
        BRA <NEXT

   @DONE
   E GET L2
     RET

-------------------------------------------------------------------------------

This is a subordinate function used by ASM_EVALUATE. It sets the token type
to "word" meaning an unrecognized string (SOMETHING), and finds out the mixed
case subtype used in DEFs etc.

A1 IN Pointer to current token

    @CYF_testIfWord
    E LOD A1

    E EQL 4            ; Strings are special, recognized in CYF_testIfStr16
   DR THN >DONE

    L2 GET A1 +4
    L3 INT 1           ; Assume no lower case present
    L4 SET :: ASC_a
       GET L4 -1
    L5 SET :: ASC_z
       GET L5 +1
    L7 SET :: ASC_underscore

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
    L3 INT 2           ; Mixed case or lower case

    @SUBTYPE
    L6 INT 5
    L6 STO A1          ; Set token type
    L3 STO A1 +1       ; Set token subtype
    L3 INT 2           ; Group 2
    L3 STO A1 +2       ; Set token group

    @DONE
    RET

-------------------------------------------------------------------------------

The following structure is the ASM dictionary. This structure is used by
the pattern matcher for recognizing instruction and register mnemonics.

 @CYF_AsmTokens

 >CYF_AsmPatterns   ; The final two words (pos 15,16) are copied into the token
                    ; during CYF_testIfDictEntry matching

 1 1 1 0h "PTR"   0   0 0 0 0 0 0 0 0
 1 1 1 1h "E" 0 0 0   0 0 0 0 0 0 0 0
 1 1 1 2h "1ST"   0   0 0 0 0 0 0 0 0
 1 1 1 3h "2ND"   0   0 0 0 0 0 0 0 0

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
 8 4 1 1h "BANK"      0 0 0 0 0 0 0 0
 8 5 1 1h ".256"      0 0 0 0 0 0 0 0
 8 6 1 1h "BUF" 0     0 0 0 0 0 0 0 0 

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

Following IDs map to SOP instruction switch

 Ah 6 1 0 "POP" 0     0 0 0 0 0 0 0 sop_POP
 Ah 6 1 0 "DROP"      0 0 0 0 0 0 0 sop_DROP
 Ah 6 1 0 "SET" 0     0 0 0 0 0 0 0 sop_SET
 Ah 6 1 0 "PER" 0     0 0 0 0 0 0 0 sop_PER
 Ah 6 1 0 "PC-SET"        0 0 0 0 0 sop_PC_set
 Ah 6 1 0 "PC-GET"        0 0 0 0 0 sop_PC_get
 Ah 6 1 0 "PULL"      0 0 0 0 0 0 0 sop_PULL
 Ah 6 1 0 "W-GET"       0 0 0 0 0 0 sop_W_get
 Ah 6 1 0 "MSB" 0     0 0 0 0 0 0 0 sop_MSB
 Ah 6 1 0 "LSB" 0     0 0 0 0 0 0 0 sop_LSB
 Ah 6 1 0 "NOT" 0     0 0 0 0 0 0 0 sop_NOT
 Ah 6 1 0 "NEG" 0     0 0 0 0 0 0 0 sop_NEG
 Ah 6 1 0 "BYTE"      0 0 0 0 0 0 0 sop_BYTE
 Ah 6 1 0 "NYBL"      0 0 0 0 0 0 0 sop_NYBL

 Ah 6 1 0 "IRQ-VEC"         0 0 0 0 sop_IRQ_vec
 Ah 6 1 0 "RETI"      0 0 0 0 0 0 0 sop_RETI
 Ah 6 1 0 "STOS"      0 0 0 0 0 0 0 sop_STOS
 Ah 6 1 0 "LODS"      0 0 0 0 0 0 0 sop_LODS
 Ah 6 1 0 "SERVICE"         0 0 0 0 sop_SERVICE
 Ah 6 1 0 "OVERLAY"         0 0 0 0 sop_OVERLAY

 ; Following IDs map to ZOP instruction switch

 Bh 6 1 0h "NEXT"     0 0 0 0 0 0 0 zop_NEXT
 Bh 6 1 0h "JUMP"     0 0 0 0 0 0 0 zop_JUMP
 Bh 6 1 0h "NOP" 0    0 0 0 0 0 0 0 zop_NOP
 Bh 6 1 0h "LIT" 0    0 0 0 0 0 0 0 zop_LIT
 Bh 6 1 0h "IDLE"     0 0 0 0 0 0 0 zop_VM_IDLE

 ; Following IDs map to DOP instruction switch

 Bh 6 1 9h "REF" 0    0 0 0 0 0 0 dop_REF       0
 Bh 6 1 9h "BRA" 0    0 0 0 0 0 0 dop_BRA       0
 Bh 6 1 9h "PULL"     0 0 0 0 0 0 dop_PULL      0
 Bh 6 2 9h "PUSH"     0 0 0 0 0 0 dop_PUSH      0
 Bh 6 2 9h "RET" 0    0 0 0 0 0 0 dop_RET       0
 Bh 6 1 9h "GFX-LDFG"         0 0 dop_GFX_ldfg  0
 Bh 6 1 9h "GFX-STBG"         0 0 dop_GFX_stbg  0
 Bh 6 3 9h "RDV" 0    0 0 0 0 0 0 dop_VM_rdv    0

 Ch 1 1 0h "NOP."        0 0 0 0 0 0 0   00h ; Was for divecode
 Ch 1 1 0h "EMERGE."           0 0 0 0   01h

 0 ; End marker

-------------------------------------------------------------------------------

The following structure are the assembler patterns (each of size 7) used
by the pattern matcher.

How do these work? Patterns are matched for each token found in the
input line. A pattern match calls the corresponding handler with a pointer
to the current token and the current assembler address, both of which the
handler can update. In particular, it should advance to the next token
following the pattern.

 @CYF_AsmPatterns

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
 1168h 0203h 0000h 0000h 0000h 0000h  9 H_BUF      ; Match BUF 80
 1148h 0000h 0000h 0000h 0000h 0000h 10 H_BANK     ; Match BANK
 1158h 0000h 0000h 0000h 0000h 0000h 11 H_ALIGN    ; Match .256
 010Fh 0000h 0000h 0000h 0000h 0000h 12 H_REL      ; Match <<LABEL, >>LABEL
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
 0101h 0129h 0000h 0000h 0000h 0000h 24 H_BYTE
 0101h 0129h 0101h 0225h 0000h 0000h 25 H_CPU      ; reg SOP reg label
 0169h 0200h 0000h 0000h 0000h 0000h 26 H_EXT_SIG  ; ZOP + code
 016Bh 0000h 0000h 0000h 0000h 0000h 27 H_EXT_SIG  ; ZOP name
 016Bh 0107h 0000h 0000h 0000h 0000h 28 H_EXT_BRA  ; ZOP branch
 0101h 016Ah 0000h 0000h 0000h 0000h 29 H_CPU_MAP  ; SOP mapped opcodes
 0101h 016Bh 0101h 0000h 0000h 0000h 30 H_EXT_2REG ; ZOP mapped codes 2reg
 0101h 016Bh 0000h 0000h 0000h 0000h 31 H_EXT_2REG ; ZOP mapped codes 1reg
 0200h 0179h 0101h 0200h 0000h 0000h 32 H_PAR      ; DOP instruction
 0200h 0179h 0101h 0000h 0000h 0000h 33 H_PAR      ; DOP instruction implied
 0101h 016Bh 0200h 0000h 0000h 0000h 30 H_EXT_2REG ; ZOP mapped codes use 30!
 0200h 016Ah 0000h 0000h 0000h 0000h 24 H_CPU_MAP  ; SOP mapped codes use 29!

 036Bh 0101h 0101h 0000h 0000h 0000h 38 H_RDV      ; RDV L1 L2

 026Bh 0000h 0000h 0000h 0000h 0000h 35 H_DOP_PUSH
 026Bh 0101h 0000h 0000h 0000h 0000h 36 H_DOP_PUSH
 026Bh 0101h 0203h 0000h 0000h 0000h 37 H_DOP_PUSH

 0 ; End of pattern list
The following batch of functions each handle a specific pattern, for example
register, instruction name, register.

-------------------------------------------------------------------------------

This is a helper for the pattern handler functions. It advances the token ptr
a given number of tokens, which typically corresponds to the number of tokens
matched. It tries to not go past the end of the token buffer.

A1 IN Pointer to token, update
A2 IN Number of tokens to skip

    @CYF_skip
    L6 SET :: CYF_TokenSize

    @NEXT
   E LOD A1
   E ELS >DONE

    ADD A1 L6
 A2 REP <NEXT

    @DONE
    RET

-------------------------------------------------------------------------------

This is a helper for the pattern handler functions. It retrieves a value from
one of the downstream tokens in the pattern, typically subtype or index.

A1 IN Pointer to token buffer
A2 IN Number of tokens to skip
A3 IN Offset from where to retrieve

A2 OUT Pointer to requested token

E OUT Requested value
  
    @CYF_info
    L6 SET :: CYF_TokenSize
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

-------------------------------------------------------------------------------

Helper function for pattern handlers. Looks up the token and either returns the
value directly for numbers, or looks up the value in symbol table for words.

A1 IN Token pointer
A2 OUT Number value

    @CYF_mixed
    L2 GET A1

   E LOD A1          ; Load token type
   E EQL 5
   DR THN >MIXED     ; Test if number or Mixed

      LOD L2 +3      ; Get slot 3 NUM
        BRA >COMMON

    @MIXED
       JSR L2 L2
       CYF_getSymbol
       LOD L2 +3

    @COMMON
    A2 GET L2
    RET

-------------------------------------------------------------------------------

Handler function for PUSH type DOP instructions.
Type 35=PUSH, 36=PUSH L1, 37=PUSH L1 +2

 @H_DOP_PUSH

    L6 SET :: CYF_TokenSize
    L5 LOD A1 +3 ; Base opcode
    L3 GET L6 -2 ; Point to penultimate char pos of name field
    L2 ADD A1 L3
    L1 LOD L2    ; Shortcut code (dop_PUSH etc)
       ADD A1 L6 ; Now points to next token

    A4 EQL 37 ; PUSH L1 +2
    DR THN >3
    A4 EQL 36 ; PUSH L1, 1 default value
    DR THN >2

 @1 ; Just PUSH, 2 default values

    L4 INT 0 ; Default zero offset
    L7 INT 1 ; Default to  E register
       BRA >ENCODE



 @2 L4 INT 0 ; Default zero offset
    L7 LOD A1 +3 ; Get L reg index
       ADD A1 L6
       BRA >ENCODE

 @3 ; Get register index
    L7 LOD A1 +3
       ADD A1 L6
    L4 GET A1                  ; Ignore previous L1
       JSR L4 L4 :: CYF_mixed  ; L1 output number value
       ADD A1 L6               ; Skip to next token
       NYBL L4                 ; AND Fh
    L4 GET DR

 @ENCODE  DR INT Fh
       AND L1 DR  ; R1
       SHL L5 4
       IOR L5 L7
       SHL L5 4
       IOR L5 L1
       SHL L5 4
       IOR L5 L4
    L2 ADD A2 A3
       GET A3 +1
       JSR L2 L5 :: CYF_putObjCode

 @DONE RET

-------------------------------------------------------------------------------

Pattern handler function. This handler triggers on "BANK" and (re)sets the
object code address to the first overlay address, without changing the
object code pointer.

A1 IN Pointer to token, handler must update!
A2 IN Base, update
A3 IN Effective, update

    @H_BANK
    L6 GET A1
    DR REF :: CYF_ObjMode  ; For memory target don't pad
    DR THN >2

    L5 SET :: FFFFh        ; Pad to here (Set to ORG E000h before first BANK )
    L4 INT 0
 @1    JSR L5 L4 :: CYF_putObjCode ; Padd object code with zeros to ORG address
       GET A3 +1
    L7 SUB L5 A3
    L7 THN <1
       JSR L5 L4 :: CYF_putObjCode ; One more to 10000h, the L5s are just dummies!

 @2 A3 SET :: E000h    ; Always same OVERLAY base address

    L2 INT 1           ; Advance to next token
    JSR L6 L2
    CYF_skip
    E INT 0            ; Return value
    A1 GET L6          ; Bubble
       RET

-------------------------------------------------------------------------------

Pattern handler function. This handler triggers on ".256" and (re)sets the
object code address to the first overlay address, without changing the
object code pointer.

A1 IN Pointer to token, handler must update!
A2 IN Base, update
A3 IN Effective, update

    @H_ALIGN
    L6 GET A1

    L1 SHR A3 8 ; Divide by 256 (1x 512 byte block)
       GET L1 +1
       SHL L1 8 ; Multiply by 256
    
       DR INT 0
    @1 L2 GET A3
          JSR L2 DR :: CYF_putObjCode
          GET A3 +1
       A3 EQR L1
       DR ELS <1       ; Pad to block boundary

       L2 INT 1        ; Advance to next token
          JSR L6 L2
          CYF_skip
        E INT 0        ; Return value
       A1 GET L6       ; Bubble
          RET

-------------------------------------------------------------------------------

 @H_PAR

    L6 SET :: CYF_TokenSize
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

    @A SHL L5 4
       IOR L5 L4
       SHL L5 4
       IOR L5 L7
       SHL L5 4
       IOR L5 L1

    L4 PER :: CYF_LeftOp

    L2 ADD A2 A3
       GET A3 +1
    JSR L2 L5 :: CYF_putObjCode

 @DONE RET

-------------------------------------------------------------------------------

Handler function for reg SOP reg label.

 @H_CPU

    L6 SET :: CYF_TokenSize
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
       JSR L7 L7 :: CYF_mixed ; L7 now R2 operand (literal or def'd value)
       ADD A1 L6

    L2 INT 15
       AND L7 L2 ; Sanitize R2 to 4-bit range

       SHL L5 4
       IOR L5 L4
       SHL L5 4
       IOR L5 L7
       SHL L5 4
       IOR L5 L1

    L4 PER :: CYF_LeftOp

    L2 ADD A2 A3
       GET A3 +1
    JSR L2 L5 :: CYF_putObjCode

 @DONE RET

-------------------------------------------------------------------------------

Handler function for branch opcode.

 @TEMP 0
 @H_BRA

    L6 SET :: CYF_TokenSize

    A4 EQL 23
    DR THN >0                   ; Branch if missing L (23)
    L4 LOD A1 +3                ; L operand
       ADD A1 L6
 @0
    L5 LOD A1 +3                ; Base opcode
    L3 GET L6 -1
    L3 ADD A1 L3
       LOD L3 0                 ; L3 now opcode extension bit
       ADD A1 L6                ; Now points to branch offset token

    A4 EQL 22
    DR THN >1                   ; Branch if pattern has an L operand
    L4 REF :: CYF_LeftOp        ; Set L operand to "default" LHS op

 @1
    L2 GET A1
    L1 GET A2
    L7 GET A3
    L3 PER :: <TEMP             ; Push L3 (no more spare registers)
       JSR L2 L1 L7 L3          ; E best absolute displacement
       CYF_nearest

    L1 LOD A1 +1                ; Subtype (1: Backward / 2: Forward)
    L1 EQL 1
        DR ELS >FWD
        L3 SET :: FFFFh
           EOR E L3
           GET E +1             ; Negated distance
       @FWD

    L1 GET E
    L2 SET :: 127               ; Force 7 bit range
       AND L1 L2
    L3 REF :: <TEMP

       IOR L1 L3                ; Mask in opcode extension bit (ELS/THN)
       SHL L5 4
       IOR L5 L4
       SHL L5 8
       IOR L5 L1

       ADD A1 L6                ; Skip branch offset token
    L2 ADD A2 A3
       GET A3 +1

       JSR L2 L5 :: CYF_putObjCode          ; THIS WAS A STRAY STORE TARGET

                               ; STO to 16FF  0E03: iw6584 from CYF_putObjCode

 @DONE RET

-------------------------------------------------------------------------------

Handler function for register type opcodes.

 @H_REGS

    L6 SET :: CYF_TokenSize

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
    A4 EQL 19     ; This handles masking for AND/IOR/EOR
    DR ELS >@     ; Stay if full masked
    A4 EQL 21
    DR ELS >@     ; Stay if missing L masked
    L7 GET A1
       JSR L7 L7 :: CYF_mixed ; L7 now R1 operand (literal or def'd value)

  @@   SHL L5 4
       IOR L5 L4
       SHL L5 4
       IOR L5 L1
       SHL L5 4
       IOR L5 L7

    L4 PER :: CYF_LeftOp

    L2 ADD A2 A3
       GET A3 +1
       JSR L2 L5 :: CYF_putObjCode

 @DONE RET

-------------------------------------------------------------------------------

Handler function for nybble opcodes.

 @H_EXT_2REG

    L6 SET :: CYF_TokenSize
    L4 LOD A1 +3 ; L operand
       ADD A1 L6

    L5 LOD A1 +3 ; Base opcode
    L3 GET L6 -2 ; Pick 2nd from last (see CYF_testIfDictEntry)
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

    @A SHL L5 4
       IOR L5 L4
       SHL L5 4
       IOR L5 L7
       SHL L5 4
       IOR L5 L1

    L4 PER :: CYF_LeftOp

    L2 ADD A2 A3
       GET A3 +1
       JSR L2 L5 :: CYF_putObjCode

 @DONE RET

-------------------------------------------------------------------------------

Handler function for SOP mapped opcodes.

 @H_CPU_MAP

    L6 SET :: CYF_TokenSize
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
       JSR L2 L5 :: CYF_putObjCode

 @DONE RET

-------------------------------------------------------------------------------

Handler function for ZOP shortcuts.

 @H_EXT_SIG

    L6 SET :: CYF_TokenSize
    L5 LOD A1 +3 ; Base opcode
    L3 GET L6 -1 ; Point to penultimate char pos of name field
    L2 ADD A1 L3
    L1 LOD L2    ; Shortcut code (zop_RET etc)
       ADD A1 L6 ; Now points to next token

    L4 SET :: dop_SIG
    A4 EQL 26
    DR THN >1 ; Branch if zop_ xyz
    A4 EQL 35
    DR ELS >A
         ; Unfinished stuff

 @1 L1 GET A1                 ; Ignore previous L1
       JSR L1 L1 :: CYF_mixed ; (literal or def'd value)
       ADD A1 L6              ; Skip to next token
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
       JSR L2 L5 :: CYF_putObjCode

 @DONE RET

-------------------------------------------------------------------------------

Handler function for ZOP BRA opcode.

 @TEMP 0
 @H_EXT_BRA

    L6 SET :: CYF_TokenSize
    L5 LOD A1 +3 ; Base opcode
    L3 GET L6 -2 ; Point to penultimate char pos of name field
    L2 ADD A1 L3
    L3 LOD L2 1  ; L3 now opcode extension bit (See CYF_testIfDictEntry)
    L4 LOD L2 0  ; L4 now ZOP switch code (R2)
       ADD A1 L6 ; Now points to branch offset token

    L2 GET A1
    L1 GET A2
    L7 GET A3
    L3 PER :: <TEMP     ; Push L3 (no more spare registers)
       JSR L2 L1 L7 L3  ; E best absolute displacement
       CYF_nearest

    L1 LOD A1 +1 ; Subtype (1: Backward / 2: Forward)
    L1 EQL 1
        DR ELS >FWD
        L3 SET :: FFFFh
           EOR  E L3
           GET  E +1 ; Negated distance
       @FWD
    L1 GET  E
    L2 SET :: 255 ; Force 8 bit range
       AND L1 L2
    L3 REF :: <TEMP
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
       JSR L2 L5 :: CYF_putObjCode

 @DONE RET

-------------------------------------------------------------------------------

Handler function for byte opcodes.

 @H_BYTE

    L6 SET :: CYF_TokenSize

    L4 LOD A1 +3 ; L operand
       ADD A1 L6
    L5 LOD A1 +3 ; Base opcode
    L3 GET L6 -1
    L3 ADD A1 L3
       LOD L3 0  ; L3 now opcode extension bit
       ADD A1 L6

    L7 GET A1
       JSR L7 L7 :: CYF_mixed ; L7 now R2 operand (literal or def'd value)
       ADD A1 L6

 @@ L2 SET :: FFh
       AND L7 L2 ; Sanitize R2 operand, clear bit 8 onwards
       IOR L7 L3 ; Mask in opcode extension bit
       SHL L5 4
       IOR L5 L4
       SHL L5 8
       IOR L5 L7

    L4 PER :: CYF_LeftOp

    L2 ADD A2 A3
       GET A3 +1
       JSR L2 L5 :: CYF_putObjCode

 @DONE RET

-------------------------------------------------------------------------------

Handler function for nybble opcodes.

 @H_NYBBLE

    L6 SET :: CYF_TokenSize
    L7 INT 0 ; Default value for R1 operand = 0

    A4 EQL 14
    DR THN >0    ; Branch if pattern missing L operand (14)
    A4 EQL 16
    DR THN >0    ; Branch if pattern missing L and R1 (16)

    L4 LOD A1 +3 ; L operand
       ADD A1 L6
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
       JSR L7 L7 :: CYF_mixed ; L7 now R2 operand (literal or def'd value)
       ADD A1 L6

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

    L4 PER :: CYF_LeftOp

    L2 ADD A2 A3
       GET A3 +1
       JSR L2 L5 :: CYF_putObjCode

 @DONE RET

-------------------------------------------------------------------------------

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
           CYF_info

        L2 INT 8
        L7 SET :: FFFFh
           EOR L2 L7
           AND  E L2        ; Clear bit 3
           SHL  E 1         ; One bit will come in from A2 selector
        L7 GET  E

        ; Get A2 selector

        L2 INT 2
        L3 INT 3
           JSR L6 L2 L3    ; E has A2 selector
           CYF_info

        L2 INT 8
        L5 SET :: FFFFh
           EOR L2 L5
           AND  E L2        ; Clear bit 3
        L5 GET  E

        ; Fiddle

        L2 INT 4           ; Bit mask selecting bit 2
           AND  E L2        ; Check if bit 2 set
        E ELS >1
           GET L7 +1       ; Set bit 0 of slot 0 value
        L3 SET :: FFFFh
           EOR L2 L3       ; Invert mask
           AND L5 L2       ; Clear bit 2 in L5
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
           CYF_info

        L2 INT 8
        L5 SET :: FFFFh
           EOR L2 L5
           AND  E L2        ; Clear bit 3
        L5 GET  E

        ; Get A4 selector

        L2 INT 4
        L3 INT 3
           JSR L6 L2 L3    ; E has A4 selector
           CYF_info

        L2 INT 8
        L4 SET :: FFFFh
           EOR L2 L4
           AND  E L2       ; Clear bit 3
        L4 GET  E

        ; Fiddle

           SHL L7 3        ; Shift left 3 bits for slot 2
           IOR L7 L5
           SHL L7 3        ; Shift left 3 bits for slot 3
           IOR L7 L4

    L2 ADD A2 A3  ; Store instruction
       GET A3 +1  ; Advance object code ptr
     JSR L2 L7 :: CYF_putObjCode

    L2 INT 5      ; Skip tokens matched
       JSR L6 L2
       CYF_skip

    E GET L1     ; Error code
    A1 GET L6     ; Bubble
       RET

-------------------------------------------------------------------------------

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
           CYF_info

        L2 INT 8
        L7 SET :: FFFFh
           EOR L2 L7
           AND  E L2        ; Clear bit 3
           SHL  E 1         ; One bit will come in from A2 selector
        L7 GET  E

        ; Get A2 selector

        L2 INT 2
        L3 INT 3
           JSR L6 L2 L3     ; E has A2 selector
           CYF_info

        L2 INT 8
        L5 SET :: FFFFh
           EOR L2 L5
           AND  E L2        ; Clear bit 3
        L5 GET  E

        ; Fiddle

        L2 INT 4           ; Bit mask selecting bit 2
           AND  E L2        ; Check if bit 2 set
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

        ; Get A3 selector

        L2 INT 3
        L3 INT 3
           JSR L6 L2 L3    ; E has A3 selector
           CYF_info

        L2 INT 8
        DR SET :: FFFFh
        L2 EOR DR L2
           AND  E L2        ; Clear bit 3
        L5 GET  E

        ; Fiddle

           SHL L7 3        ; Shift left 3 bits for slot 2
           IOR L7 L5
           SHL L7 3        ; Shift left 3 bits for slot 2 (slot 3 0)

    L2 ADD A2 A3      ; Store instruction
       JSR L2 L7 :: CYF_putObjCode
       GET A3 +1

    L2 INT 4          ; Skip tokens matched
       JSR L6 L2
       CYF_skip

    E GET L1         ; Error code
    A1 GET L6         ; Bubble
       RET

-------------------------------------------------------------------------------

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
           CYF_info

        L2 INT 8
        DR SET :: FFFFh
        L2 EOR DR L2
           AND  E L2        ; Clear bit 3
           SHL  E 1         ; One bit will come in from A2 selector
        L7 GET  E
        L2 INT 2
        L3 INT 3
           JSR L6 L2 L3    ; E has A2 selector
           CYF_info

        L2 INT 8
        DR SET :: FFFFh
        L2 EOR DR L2
           AND  E L2        ; Clear bit 3
        L5 GET  E

        L2 INT 4           ; Bit mask selecting bit 2
           AND  E L2        ; Check if bit 2 set
        E ELS >1
           GET L7 +1       ; Set bit 0 of slot 0 value
        DR SET :: FFFFh
        L2 EOR DR L2        ; Invert mask
           AND L5 L2       ; Clear bit 2 in L5

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
       JSR L2 L7 :: CYF_putObjCode
       GET A3 +1

    L2 INT 3          ; Skip tokens matched
       JSR L6 L2
       CYF_skip

    E GET L1         ; Error code
    A1 GET L6         ; Bubble
       RET

-------------------------------------------------------------------------------

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
           CYF_info

        L2 INT 8
        DR SET :: FFFFh
        L2 EOR DR L2
           AND  E L2        ; Clear bit 3
           SHL  E 1
        L7 IOR  E L7
           SHL L7 8

    L2 ADD A2 A3      ; Store instruction
       JSR L2 L7 :: CYF_putObjCode
       GET A3 +1

    L2 INT 2          ; Skip tokens matched
       JSR L6 L2
       CYF_skip

    E GET L1         ; Error code
    A1 GET L6         ; Bubble
       RET

-------------------------------------------------------------------------------

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
    JSR L1 L7 :: CYF_putObjCode
       GET A3 +1        ; Advance object code ptr

    L2 INT 1            ; Skip tokens matched
       JSR L6 L2
       CYF_skip

    E GET L1           ; Error code
    A1 GET L6           ; Bubble
       RET

-------------------------------------------------------------------------------

Pattern handler function. This handler resolves WORDs and writes
the values/addresses into the object stream.

A1 IN Pointer to token, handler must update!
A2 IN Base, updateƒ
A3 IN Effective, update

E OUT Leave error code in E

    @H_WORD
    L6 GET A1

    JSR L6 L5 :: CYF_getSymbol      ; Should this be nearest? Local DEFs ?
    LOD L5 +3

       L7 ADD A2 A3    ; Place the DEF and advance obj code ptr
          JSR L7 L5 :: CYF_putObjCode
          GET A3 +1

    L2 INT 1      ; Advance 1 token (skip DEF label)
    JSR L6 L2
    CYF_skip

    E INT 0      ; Return value
    A1 GET L6     ; Bubble
       RET

-------------------------------------------------------------------------------

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
           CYF_info

        L4 INT 2          ; From number arg
        L3 INT 3          ; Index
           JSR L6 L4 L3
           CYF_info          ; Continue

       E STO L2 +3       ; Store index value in word token
       E INT 2
       E STO L2 +2       ; Set group 2 (same as NUM)

           JSR L2
           <CYF_newSymbol     ; Copy token into symbol table

        L2 INT 3          ; Advance by 3 tokens (DEF Mixed 20)
           JSR L6 L2
           CYF_skip

    E INT 0              ; Return value
    A1 GET L6             ; Bubble
       RET

-------------------------------------------------------------------------------

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
       CYF_nearest

    L3 LOD L4 +3
    L7 ADD A2 A3
       JSR L7 L3 :: CYF_putObjCode
       GET A3 +1

    L2 INT 1             ; Advance to next token
    JSR L6 L2
    CYF_skip

    E INT 0             ; Return value
    A1 GET L6            ; Bubble
       RET

    @H_REL

    L6 GET A1
    L1 GET A2
    L2 GET A3
       JSR L6 L1 L2 L4 :: CYF_nearest   ; E best abs displ

    L1 LOD A1 +1 ; Subtype (1: Backward / 2: Forward)
    L1 EQL 1
    DR ELS >FWD
    L3 SET :: FFFFh
       EOR  E L3
       GET  E +1 ; Negated distance
    @FWD

    L3 GET  E
    L7 ADD A2 A3
       JSR L7 L3 :: CYF_putObjCode
       GET A3 +1

    L2 INT 1             ; Advance to next token
       JSR L6 L2
       CYF_skip
    E INT 0             ; Return value
    A1 GET L6            ; Bubble
       RET

-------------------------------------------------------------------------------

Assembler pattern handler for label tokens (@ and @ prefix).

  @H_LABEL
    L6 GET A1                       ; A1 points to current token structure
    DR LOD L6 +0                    ; Type 6=Label
    DR EQL 6
    DR ELS >1
    DR LOD L6 +1                    ; Subtype 0=@, 1=*
    DR ELS >1
       BRA >1

       JSR L6 DR :: CYF_getSymbol   ; D will point to symbol entry
    E ELS >1                        ; If not found

    E LOD L6 +0
    E STO DR +0              ; Force to be label (symbol could be anything)
    E INT 1
    E STO DR +1              ; Force correct subtype
    E LOD L6 +2
    E STO DR +2              ; Copy group
    A3 STO DR +3             ; Update index field with current asm addr
        BRA >2

 @1 A3 STO L6 +3             ; A3 current asm addr, store in index field
    JSR L6 :: CYF_newSymbol

 @2 L2 INT CYF_TokenSize
       ADD A1 L2             ; Advance by 1 token
    E INT 0
       RET

-------------------------------------------------------------------------------

Pattern handler function. This handler places isolated numbers into obj code.

A1 IN Pointer to token, handler must update!
A2 IN Base, update
A3 IN Effective, update

E OUT Leave error code in E

    @H_NUMBER
    L1 GET A1

    L3 LOD L1 +3
    L7 ADD A2 A3
       JSR L7 L3 :: CYF_putObjCode
       GET A3 +1

    L2 INT 1          ; Advance to next token
    JSR L1 L2
    CYF_skip

    E INT 0          ; Return value
    A1 GET L1         ; Bubble
       RET

-------------------------------------------------------------------------------

Pattern handler function for "::" pattern breaker. Advance to next token.

A1 IN Pointer to token, handler must update!
A2 IN Base, update
A3 IN Effective, update

E OUT Leave error code in E

    @H_BREAK

    L1 GET A1

    L2 INT 1          ; Advance to next token
       JSR L1 L2
       CYF_skip

    E INT 0          ; Return value
    A1 GET L1         ; Bubble
       RET

-------------------------------------------------------------------------------

Pattern handler function. This handler is called when a token of type is
matched. In this case, EVALUATE/CYF_testIfStr16 has already populated the token with
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
       JSR L3 L4 :: CYF_putObjCode
       GET A3 +1
       BRA <COPY

 @1 L2 INT 1          ; Advance to next token
       JSR L1 L2
       CYF_skip

    E INT 0          ; Return value
    A1 GET L1         ; Bubble
       RET

-------------------------------------------------------------------------------

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
       CYF_info
    L7 GET  E
    DR REF :: CYF_ObjMode ; For memory target, just set A3 to ORG addr
    DR ELS >1
    A3 GET  E
       BRA >2

  @1  L5 GET  E                    ; Dummy value effectively, as disk target
      L4 INT 0
         JSR L5 L4 :: CYF_putObjCode   ; Padd obj code with zeros to ORG address
         GET A3 +1
      L4 SUB L7 A3
      L4 THN <1

 @2  L2 INT 2                      ; Advance to next token
        JSR L6 L2 :: CYF_skip
      E INT 0                      ; Return value
     A1 GET L6                     ; Bubble
        RET

-------------------------------------------------------------------------------

Pattern handler function for BUF directive.
A1 IN Pointer to token, handler must update!
A2 IN Base, update
A3 IN Effective, update
E OUT Leave error code in E

    @H_BUF
    L6 GET A1
    L2 INT 1
    L3 INT 3
      JSR L6 L2 L3      ;  E has BUF size
       CYF_info
    L7 GET  E

    DR REF :: CYF_ObjMode   ; For memory target, just add BUF size to A3
    DR ELS >1
       ADD A3 L7
       BRA >2  

  @1  L5 GET  A3
      L4 INT 0
         JSR L5 L4 :: CYF_putObjCode       ; Padd object code with GRAB zeros
         GET A3 +1
      L7 REP <1

  @2  L2 INT 2                      ; Advance to next token
         JSR L6 L2 :: CYF_skip
       E INT 0                      ; Return value
      A1 GET L6                     ; Bubble
         RET

-------------------------------------------------------------------------------

Pattern handler function for DOP RDV instruction.
A1 IN Pointer to token, handler must update!
A2 IN Base, update
A3 IN Effective, update
E OUT Leave error code in E

    @H_RDV
    L6 GET A1

    L2 INT 1
    L3 INT 3
      JSR L6 L2 L3      ; E first reg
       CYF_info
    L7 GET  E

    L2 INT 2
    L3 INT 3
       JSR L6 L2 L3     ; E second reg
       CYF_info
    L5 GET E

    L1 INT 9
       SHL L1 4
       ADD L1 L7
       SHL L1 4
    L7 INT dop_VM_rdv
       ADD L1 L7
       SHL L1 4
       ADD L1 L5

    L2 ADD A2 A3
       JSR L2 L1 :: CYF_putObjCode
       GET A3 +1

  @2  L2 INT 3                      ; Advance to next token (skip 3)
         JSR L6 L2 :: CYF_skip
       E INT 0                      ; Return value
      A1 GET L6                     ; Bubble
        RET





