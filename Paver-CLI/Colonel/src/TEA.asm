



====== TEA command line interpreter ===========================================


Welcome to TEA for Paver
Initialization code

 @TEA           JSR L1 :: 8T3_claim        ; Several commands per line 
          @1    JSR L1 :: 8T3_getLine16    ; don't work, try echo bla echo bla

           ;     L2 GET L1
           ;  @X DR LOD L2
           ;        JSR DR :: 8T3_hex
           ;        JSR :: 8T3_msg :: 10 0
           ;        GET L2 +1
           ;     DR THN <X
           ;         JSR :: 8T3_msg :: 10 0

                JSR L1 :: TEA_RUN

                BRA <1
                JSR L1 :: 8T3_cede   ; never
              
 @TEA_FName 'Teadump' 0

 @TEA_EXEC       ; A1 is pointer to dict entry
      GET A1 +2  ; Skip type word
   DR LOD A1     ; Load relative address
      ADD DR A1  ; Make absolute address
      JSR :: 0
      RET

-------------------------------------------------------------------------------
 
 @TEA_LinePos  0h

 @TEA_RUN       L4 GET A1                  ; Cmdline str
         @RESET L1 REF :: TEA_Here         ; Rewind the list cursor
                   JSR L4 :: 8T3_skipSpace ; Start at a word not space
                L4 PER :: TEA_LinePos      ; Update where we are in cmdline
                 E LOD L4                  ; Check whether end of cmdline
                 E ELS >EOL

    ; Traverse the list for a match
          
          @NEXT L2 LOD L1                 ; Relative offset to previous entry
                L2 ELS >SKIPCMD           ; End of list, nothing matches
                   ADD L1 L2              ; Previous entry
                L3 LOD L1 +1              ; Load the type
                L3 EQL TEA_Runnable       ; Must be runnable 
                DR ELS <NEXT
                L3 GET L1 +3              ; Skip offs + type + xt to name str0
                   JSR L4 L3 :: TEA_FIND  ; Compare cmdword to dict entry
                 E ELS <NEXT

         @FOUND L4 PER :: TEA_LinePos     ; Update where we are in cmdline
                   JSR L1 :: TEA_EXEC     ; Call address
                   BRA <RESET             ; Cmdword was found, try next one

       @SKIPCMD  E LOD L4                 ; Cmdword unknown, skip it
                 E ELS >EOL
                 E EQL 32
                DR THN <RESET
                   GET L4 +1
                   BRA <SKIPCMD

           @EOL  E INT 1
                   RET

-------------------------------------------------------------------------------

 @TEA_FIND
                L1 GET A1       ; This strptr terminated by ASCII space
                L2 GET A2       ; This strptr terminated by NULL
            @1  L6 LOD L1       ; One char from command line
                L7 LOD L2       ; One from dict
                L6 ELS >2       ; If NULL char, other must be NULL to
                L6 EQL 32
                DR THN >2       ; If SPACE char, other must be NULL
                L7 ELS >FAIL    ; Fail because L7 NULL, L6 isn't
                L6 EQR L7
                   GET L1 +1
                   GET L2 +1
                DR THN <1       ; Loop as long as chars are the same
                   BRA >FAIL

            @2  L7 THN >FAIL    ; L7 must be NULL char
                A1 GET L1 +1    ; Update cmd line pos if found
                 E INT 1        ; Set FOUND flag
                   RET

          @FAIL  E INT 0        ; Reset FOUND flag
                   RET

-------------------------------------------------------------------------------

   ; THIS DOES NOT KNOW THE TYPE WORD YET!
 
 @TEA_NEW
           L1 REF :: TEA_LinePos        ; Points to name string
            4 OVERLAY
           L4 REF :: EDBEACH            ; Current beach in editor
            0 OVERLAY                   ; But is it?
           L3 REF :: TEA_Here           ; Top handrail element
           L2 GET L3                    ; Save for later
              GET L3 +1                 ; Skip link field
           L7 GET L3                    ; Store execution token here
              GET L3 +1                 ; Skip execution token
              JSR L1 L3 :: TEA_COPYWRD  ; Create NULL terminated name str
           L1 PER :: TEA_LinePos        ; Skip name str in cmdline

           L3 STO L7                    ; Code begins at L3, store as XT
           L5 INT 1                     ; Assemble current beach run
           L6 INT 0
              JSR L4 :: BEACH_TO_BLOCK
              JSR L6 L3 L4 L5 :: SASM   ; offs, buf, block, mode
           L4 REF :: ASMOBJSIZE
                                        ; Create new top entry, relative link
              ADD L3 L4                 ; Point L3 to after the new obj code
                                        ; Adjust code length
           E SUB L2 L3                  ; Relative offset
           E STO L3
           L3 PER :: TEA_Here
 RET

-------------------------------------------------------------------------------

 @TEA_COPYWRD
     @1 A1 LODS        ; Copy name strz
        A2 STOS
        E ELS >DONE    ; Could be NULL
        E EQL 32       ; or space separator
        DR THN >DONE
           BRA <1      ; Add name string/0
 @DONE
 RET

-------------------------------------------------------------------------------

A1 Preserve buffer for str8z
  
  @TEA_getNamePar

     L4 GET A1                      ; Base
     L5 INT 0                       ; Offs
     L2 REF :: TEA_LinePos
      
  @1 L3 LOD L2
        JSR L4 L5 L3 :: 8T3_stByte
        GET L2 +1
        GET L5 +1
     L3 THN <1
        JSR L4 L5 L3 :: 8T3_stByte  ; L3 zero, use as terminator

     L2 PER :: TEA_LinePos

        RET   

-------------------------------------------------------------------------------

A1 Return numeric value
E  Return err code

 @TEA_getNumPar

              L1 REF :: TEA_LinePos
                 JSR L1 :: 8T3_skipSpace

                 JSR L1 L2 :: PARSENUM
               E THN >FAIL
          
              A1 GET L2
                 JSR L1 :: 8T3_skipWord
              L1 PER :: TEA_LinePos      ; Skip number str

               E INT 0                   ; Return val
 @FAIL
 RET        

-------------------------------------------------------------------------------

A1 Return TEA dict base address
A2 Return dict size

 @TEA_findBase

       L1 REF :: TEA_Here
       A1 GET L1                ; Follow backlinks down from TEA_Here
       A2 INT 0                 ; Initial size

   @1  L3 LOD A1                ; Negative offset to previous entry
       L3 ELS >2                ; Dict base if offset 0
       L7 GET L3
       L3 NEG

          ADD A2 DR             ; Add positive offset to size  
          ADD A1 L3             ; Down to previous entry
          BRA <1  
   
   @2     RET

-------------------------------------------------------------------------------

  @TEA_export  JSR :: 8T3_msg :: 'Exporting TEA dictionary...' 10 0
  
      L1 SET :: TEA_FName
 
  RET

-------------------------------------------------------------------------------

  @TEA_import  JSR :: 8T3_msg :: 'Importing TEA dictionary...' 10 0

      L1 SET :: TEA_FName
      
      ; L5 SET :: PFS_cpHelper
      ;    JSR L2 L3 L4 L5 :: PFS_fileToBuf
  
  RET

-------------------------------------------------------------------------------

TEA was Oolong - RIP
These are the remnants of a Forth dictionary.

<< forms a relative offset to the preceding label, which in this case
is equal to the length of the previous (lower address) dictionary entry.
The number following the offset is the TYPE of the entry, 1=function.


  @@ @TEA_BASE 0

  @@ <<@ TEA_Runnable >>TEA_SASM "sasm" 0                
                    @TEA_SASM
                        JSR :: CYF_sasm
                      E INT 1                       
                      E SOP sop_VM_ready 
                        RET

  @@ <<@ TEA_Runnable >>TEA_TE "te" 0
           ; @TEA_TE JSR L1 :: TEA_getNumPar
           ; E ELS >1
           ; L1 REF :: EDBEACH
           ; @1 JSR L1 :: H_CMD_EDIT
               RET

  @@ <<@ TEA_Runnable >>A "pathy" 0
              @PATHYP '/sys/src/batch/PFS.asm' 0
                     @A 
                     L1 SET :: PATHYP
                        JSR :: 8T3_msg :: 'Bix of boot = #' 0
                        JSR L1 L2 :: PFS_pathToBix
                        JSR L2 :: 8T3_hex
                        JSR :: 8T3_msg :: 10 0
                        RET               


  @@ <<@ TEA_Runnable >>A "echo" 0
                     @A 
                        JSR L1 :: 8T3_claim
                        JSR L1 :: TEA_getNamePar
                        JSR L1 :: 8T3_prStr8
                        JSR :: 8T3_msg :: 10 0
                        JSR L1 :: 8T3_cede

                        RET               


  @@ <<@ TEA_Runnable >>A "fmt" 0
                     @A 
                        JSR :: PFS_format
                      E INT 1                       
                      E SOP sop_VM_ready 
                        RET


  @@ <<@ TEA_Runnable >>A "vol" 0
                     @A 
                        JSR :: PFS_getState
                     L1 REF :: PFS_STATE_BUF

                        JSR :: 8T3_msg :: 'Volume info: ' 0
                     DR SET :: PFS_O_STATE_label
                        ADD DR L1
                        JSR DR :: 8T3_prStr8
                        JSR :: 8T3_msg :: 10 0

                     DR SET :: PFS_O_STATE_tail
                        ADD DR L1
                        LOD DR
                        JSR :: 8T3_msg :: 'Tail: ' 0
                        JSR DR :: 8T3_dec
                        JSR :: 8T3_msg :: 10 0

                     DR SET :: PFS_O_STATE_top
                        ADD DR L1
                        LOD DR
                        JSR :: 8T3_msg :: 'Top: ' 0
                        JSR DR :: 8T3_dec
                        JSR :: 8T3_msg :: 10 0

                     DR SET :: PFS_O_STATE_work
                        ADD DR L1
                        LOD DR
                        JSR :: 8T3_msg :: 'Current: ' 0
                        JSR DR :: 8T3_dec
                        JSR :: 8T3_msg :: 10 0

                        JSR :: 8T3_msg :: 'Freelist: -' 10 0  

                        RET


  @@ <<@ TEA_Runnable >>A "del" 0
                     @A 
                        JSR L1 :: 8T3_claim
                        JSR L3 :: 8T3_claim

                        JSR L1 L2 :: PFS_rdWorking
                        JSR L3 :: TEA_getNamePar
                        JSR L1 L3 L4 :: PFS_entryByName
                     L4 ELS >END

                        JSR L1 L4 :: PFS_delEntry
                        JSR L1 L2 :: PFS_wrBlock

                  @END  JSR L3 :: 8T3_cede
                        JSR L1 :: 8T3_cede
                        RET


  @@ <<@ TEA_Runnable >>A "lif" 0
                     @A 
                        JSR L7 :: 8T3_claim
                        JSR L2 :: 8T3_claim

                        JSR :: PFS_getState
                     L1 REF :: PFS_STATE_BUF
                        JSR :: 8T3_msg :: 'VOL "' 0
                     DR SET :: PFS_O_STATE_label
                        ADD DR L1
                        JSR DR :: 8T3_prStr8
                        JSR :: 8T3_msg :: '"' 10 0

                        JSR L7 L4 :: PFS_rdWorking
                        JSR L2 L4 L5 :: PFS_getBixName
                        JSR :: 8T3_msg :: '>' 0
                        JSR L5 :: 8T3_prStr8
                        JSR L4 :: PFS_prBix
                        JSR :: 8T3_msg :: ':' 10 0

                     L3 SET :: PFS_O_FOLDER_begin           
                     L4 INT 15

                 @1  L5 ADD L7 L3
                     L6 LOD L5
                     L6 ELS >NXT
        
                        GET L5 +1                    ; Skip target cell
                      E INT ASC_tab
                        JSR :: 8T3_putC
                        JSR L5 :: 8T3_prStr8      ; Todo: Prefix (>)
                        JSR L6 :: PFS_prBix
                        JSR :: 8T3_msg :: 10 0
        
                @NXT  E SET :: PFS_O_FOLDER_step
                        ADD L3 E
                     L4 REP <1
                     
                        JSR L7 :: 8T3_cede
                        JSR L2 :: 8T3_cede
                        RET


  @@ <<@ TEA_Runnable >>A "leave" 0
                     @A 
                        JSR L1 :: 8T3_claim

                        JSR L1 L2 :: PFS_rdWorking
                     L2 SET :: PFS_O_ANY_parent
                        ADD L2 L1
                        LOD L2

                        JSR :: PFS_getState
                     L3 SET :: PFS_O_STATE_work
                        ADD L3 L1
                     L2 STO L3
                        JSR :: PFS_putState
                        
                        JSR L1 :: 8T3_cede
                        RET


  @@ <<@ TEA_Runnable >>A "chf" 0
                     @A
                        JSR :: PFS_getState
                     L1 REF :: PFS_STATE_BUF
                        JSR L3 :: 8T3_claim
                        JSR L3 :: TEA_getNamePar
                        JSR L3 L4 :: PFS_pathToBix
                     L4 ELS >1

                     L5 SET :: PFS_O_STATE_work
                        ADD L5 L1
                     L4 STO L5
                        JSR :: PFS_putState

                    @1  JSR L3 :: 8T3_cede
                        RET



  @@ <<@ TEA_Runnable >>A "cref" 0
                     @A
                        JSR L1 :: 8T3_claim
                        JSR L2 :: 8T3_claim
                        JSR L7 :: 8T3_claim
                        
                        JSR L1 :: TEA_getNamePar
                        JSR L1 L2 :: PFS_cutFName8
                        JSR L1 L3 :: PFS_pathToBix
                        JSR L7 L4 :: PFS_rdWorking
                     
                      E LOD L2
                      E THN >MKFILE
                      E LOD L1
                      E ELS >END
                        
                        JSR L5 :: PFS_alloc
                     DR INT 2
                        JSR L1 DR :: 8T3_chop

                        JSR L7 L5 L1 :: PFS_createEntry                      
                        JSR L7 L4 :: PFS_wrBlock

                      E INT PFS_T_FOLDER
                        JSR L5 L4 :: PFS_wrHeader
                        BRA >END

            @MKFILE     JSR L4 L2 L5 :: PFS_forceFile

                 @END   JSR L1 :: 8T3_cede
                        JSR L2 :: 8T3_cede
                        JSR L7 :: 8T3_cede 
                        RET



  @@ <<@ TEA_Runnable >>A "sexp" 0
                     @A JSR :: TEA_export

                      E INT 1                     
                      E SOP sop_VM_ready 
                        RET

  @@ <<@ TEA_Runnable >>A "simp" 0
                   @A JSR :: TEA_import
                   
                    E INT 1
                    E SOP sop_VM_ready 
                      RET

  @@ <<@ TEA_Runnable >>A "spatter" 0
                     @A
                        JSR :: CYF_spatter
                      E INT 1
                      E SOP sop_VM_ready 
                        RET

  @@ <<@ TEA_Runnable >>A "pair" 0
                      @A
                        JSR L1 :: TEA_getNumPar
                        JSR L2 :: TEA_getNumPar
                     L1 PER :: ECO_Buf
                     L2 PER :: ECO_Bix
                     
                      E INT PFS_OffsFData
                        SHL E 1
                      E PER :: ECO_Pos

                        JSR :: ECO_header
                        JSR L1 L2 :: PFS_rdBlock
                        JSR L1 :: ECO_trimPair
                        RET

  @@ <<@ TEA_Runnable >>A "list" 0
                      @A
                        JSR L2 :: TEA_getNumPar   ; Number of lines
                        JSR :: ECO_header
                     L1 REF :: ECO_Buf
                     L3 REF :: ECO_Pos
                        JSR L1 L3 L2 :: ECO_ldump
                        JSR :: 8T3_msg :: 10 0
                        RET

  @@ <<@ TEA_Runnable >>A "insl" 0
                      @A
                        JSR L1 :: TEA_getNumPar
                     L2 REF :: TEA_LinePos
                        JSR L1 L2 :: ECO_insl
                        RET

  @@ <<@ TEA_Runnable >>A "reml" 0
                      @A
                        JSR L1 :: TEA_getNumPar
                        JSR L1 :: ECO_reml
                        RET

  @@ <<@ TEA_Runnable >>A "repl" 0
                      @A
                        JSR L1 :: TEA_getNumPar
                        JSR L1 :: ECO_reml
                     L2 REF :: TEA_LinePos
                        JSR L1 L2 :: ECO_insl
                        RET

  @@ <<@ TEA_Runnable >>A "commit" 0
                      @A
                        JSR :: ECO_commit
                        RET


  @@ <<@ TEA_Runnable >>A "bsave" 0
                      @A
                        JSR L4 :: 8T3_claim
                        JSR L7 :: 8T3_claim

                        JSR L2 :: TEA_getNumPar
                        JSR L3 :: TEA_getNumPar

                        JSR L4 :: TEA_getNamePar
                        JSR L7 L6 :: PFS_rdWorking
                        JSR L6 L4 L5 :: PFS_forceFile  ; bix fname head
                        JSR L4 L6 :: PFS_wrBlock  
                     L5 ELS >1

                        JSR L2 L5 L3 :: PFS_bufToFile  ; srcbuf trgbix cells

                     @1 JSR L4 :: 8T3_cede
                        JSR L7 :: 8T3_cede
                        RET

  @@ <<@ TEA_Runnable >>A "bload" 0
                      @A
                        JSR L1 :: 8T3_claim
                        JSR L1 :: TEA_getNamePar
                        JSR L2 :: TEA_getNumPar
                        JSR L1 L3 :: PFS_pathToBix
                     L3 ELS >1   

                     L5 SET :: PFS_cpHelper
                        JSR L2 L3 L4 L5 :: PFS_fileToBuf

                        JSR L4 :: 8T3_dec
                        JSR :: 8T3_msg :: ' cells' 10 0

                     @1 JSR L1 :: 8T3_cede
                        RET

  @@ <<@ TEA_Runnable >>A "hdump" 0
                      @A
                          JSR L1 :: TEA_getNumPar
                          JSR L2 :: TEA_getNumPar
                          JSR L1 L2 :: ECO_hdump
                          RET

  @@ <<@ TEA_Runnable >>A "cdump" 0
                      @A
                          JSR L1 :: TEA_getNumPar
                          JSR L2 :: TEA_getNumPar
                          JSR L1 L2 :: ECO_cdump
                          RET

  @@ <<@ TEA_Runnable >>A "ldump" 0
                      @A
                          JSR L1 :: TEA_getNumPar
                          JSR L2 :: TEA_getNumPar
                       L3 INT 0   
                          JSR L1 L3 L2 :: ECO_ldump
                          RET

  @@ <<@ TEA_Runnable >>A "bwr" 0
                      @A
                          JSR L1 :: TEA_getNumPar  ; Src address
                          JSR L2 :: TEA_getNumPar  ; Bix
                          JSR L1 L2 :: PFS_wrBlock
                          RET

  @@ <<@ TEA_Runnable >>A "brd" 0
                      @A
                          JSR L1 :: TEA_getNumPar  ; Dest address
                          JSR L2 :: TEA_getNumPar  ; Bix
                          JSR L1 L2 :: PFS_rdBlock
                          RET

  @@ <<@ TEA_Runnable >>A "ruler" 0
                      @A
                          JSR :: 8T3_msg :: '000000000111111111122222222223' 0
                          JSR :: 8T3_msg :: '333333333444444444455555555556' 0
                          JSR :: 8T3_msg :: '66666666677777777778' 10 0

                          JSR :: 8T3_msg :: '123456789*123456789*123456789*' 0
                          JSR :: 8T3_msg :: '123456789*123456789*123456789*' 0
                          JSR :: 8T3_msg :: '123456789*123456789*' 10 0

                        RET


  @@ <<@ TEA_RDV >>A  RDV_FUNC_wrPFSFile
                   @A
                        JSR L1 :: 8T3_claim
                        JSR L2 :: 8T3_claim
                        
                     L3 SET :: 256
                      E SET :: RDV_VM_ReadsRDVBuf
                        RDV L1 L3
                        JSR L1 L2 :: PFS_cutFName8
                     DR INT 2
                        JSR L1 DR :: 8T3_chop
                        JSR L1 L3 :: PFS_pathToBix
                     L3 ELS >END

                        JSR L3 L2 L4 :: PFS_forceFile  ; bix fname head
                        JSR L4 :: PFS_pullFile

                  @END  JSR L1 :: 8T3_cede
                        JSR L2 :: 8T3_cede

                      E SET :: RDV_VM_Finished
                      E SOP sop_VM_ready
                        RET


  @@ <<@ TEA_RDV >>A  RDV_FUNC_rdPFSFile
                   @A
                        JSR L1 :: 8T3_claim
                        JSR L2 :: 8T3_claim
                        JSR L7 :: 8T3_claim

                     L3 SET :: 256
                      E SET :: RDV_VM_ReadsRDVBuf
                        RDV L1 L3
                        JSR L1 L2 :: PFS_cutFName8
                     DR INT 2
                        JSR L1 DR :: 8T3_chop
                        JSR L1 L3 :: PFS_pathToBix

                     L3 ELS >END

                        JSR L7 L3 :: PFS_rdBlock
                        JSR L7 L2 L4 :: PFS_entryByName
                        ADD L4 L7
                        LOD L4

                     DR SET :: PFS_rdvHelper              ; Pumps into RDVPtr
                        JSR L2 L4 L5 DR :: PFS_fileToBuf  ; buf, bix, cellsread, funcptr

                 @END   JSR L1 :: 8T3_cede
                        JSR L2 :: 8T3_cede
                        JSR L7 :: 8T3_cede

                      E SET :: RDV_VM_Finished
                      E SOP sop_VM_ready
                        
                        RET

  ; Fix bug: Can't place TEA_Runnable here, will cause hen segfault!

  @@ <<@ ACEDh  ; Visual cue in hex editor
         TEA 
  @TEA_Head <<@


THIS SPACE RESERVED FOR RUNTIME TEA DICTIONARY ENTRIES








