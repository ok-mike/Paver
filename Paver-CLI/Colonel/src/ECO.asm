
Editing COmmands

  *ECO_Bix   0
  *ECO_Buf   0  ; 1024 cells / 2 blocks
  *ECO_Pos   0  ; Byte offset in Buf

-------------------------------------------------------------------------------

A1 Preserve from address
A2 Preserve lines

  *ECO_hdump

        L1 GET A1
        L2 GET A2
        L5 INT 8   ; Columns

     @1  E GET L1  
           JSR :: 8T3_prHex
           JSR :: 8T3_msg :: ': ' 0
        L4 GET L5
     @2 L3 LOD L1
         E GET L3
           JSR :: 8T3_prHex
           JSR :: 8T3_msg :: ' ' 0
           GET L1 +1
        L4 REP <2
           JSR :: 8T3_msg :: 10 0      
        L2 REP <1    
       
  RET

-------------------------------------------------------------------------------

A1 Preserve from address
A2 Preserve lines

  *ECO_cdump

        L1 GET A1
        L2 GET A2
        L5 INT 16   ; Columns

     @1 L6 INT 0    ; Byte offset
         E GET L1
           JSR :: 8T3_prHex
           JSR :: 8T3_msg :: ': ' 0
        L4 GET L5
     
     @2    JSR L1 L6 L3 :: 8T3_ldByte
         E GET L3

         E EQL ASC_space
        DR THN >SP
         E EQL ASC_tab
        DR THN >TAB
         E EQL ASC_linefeed
        DR THN >LF
         E ELS >NUL
         E LTL 32
        DR THN >WHAT
         E GTL 7Fh
        DR THN >WHAT 
           BRA >3

   @SP     JSR :: 8T3_msg :: 'SP ' 0
           BRA >4

   @TAB    JSR :: 8T3_msg :: '\t ' 0
           BRA >4

   @LF     JSR :: 8T3_msg :: '\n ' 0
           BRA >4

   @NUL    JSR :: 8T3_msg :: '\0 ' 0
           BRA >4

  @WHAT    JSR :: 8T3_msg :: '__ ' 0
           BRA >4

     @3    JSR :: 8T3_putC
           JSR :: 8T3_msg :: '  ' 0
             
     @4    GET L6 +1
        L4 REP <2

           JSR :: 8T3_msg :: 10 0
         E SHR L5 1
           ADD L1 E

           GET L2 -1
        L2 ELS >Q   
           JUMP :: <1  ; Far = jump mnemonic
   @Q
   RET

-------------------------------------------------------------------------------

A1 Preserve from address
A2 Preserve from byte offset
A3 Preserve lines

  *ECO_ldump

        L1 GET A1
        L2 GET A3
        L7 SET :: 320            ; Maximum LINE length (=4*80)
        L6 GET A2                ; Byte offset

    @1
         E GET L6
           JSR :: 8T3_prHex
           JSR :: 8T3_msg :: ': ' 0
           JSR L1 L6 L7 :: 8T3_granPrLine
         E ELS >Q
        L2 REP <1

  @Q       JSR :: 8T3_msg :: 10 0      
  RET

-------------------------------------------------------------------------------

  *ECO_header
     
        L1 REF :: ECO_Buf
        L2 REF :: ECO_Bix

           JSR L1 L3 :: PFS_getPrev
           JSR L1 L4 :: PFS_getNext

           JSR :: 8T3_msg :: 10 0
           JSR L1 :: 8T3_hex
           JSR L3 :: 8T3_dec
           JSR L2 :: 8T3_dec
           JSR L4 :: 8T3_dec
           JSR :: 8T3_msg :: 10 0
  RET

-------------------------------------------------------------------------------

A1 Preserve line offs
A2 Preserve str8 ptr to src line

  *ECO_insl      JSR L1 :: 8T3_claim

              L3 REF :: ECO_Buf                 ; Base ptr target buf
                 JSR L3 L2 :: PFS_getBUsed
              L7 INT PFS_OffsFData
                 SHL L7 1
                 ADD L7 L2                      ; Curr last byte offs in buf

              DR GET A2
                 JSR DR L1 :: 8T3_toStr8 
              L6 GET E                          ; Length in bytes in L6
               
              L4 GET L2                         ; Checking if block was empty
                 ADD L2 L6
                 JSR L3 L2 :: PFS_setBUsed
              L2 ADD L7 L6                      ; New last byte offs in buf     
              L4 ELS >1

          @0     JSR L3 L7 DR :: 8T3_ldByte   
                 JSR L3 L2 DR :: 8T3_stByte     ; Copy n bytes up to make room
              L7 EQR A1
                 GET L7 -1
                 GET L2 -1
              DR ELS <0

          @1  L2 INT 0
              L4 GET A1                         ; Byte offset in trg buf
          @2     JSR L1 L2 DR :: 8T3_ldByte     ; Insert n bytes into region
                 JSR L3 L4 DR :: 8T3_stByte
                 GET L2 +1
                 GET L4 +1
              L6 REP <2

                 GET L4 -1
              DR INT ASC_linefeed
                 JSR L3 L4 DR :: 8T3_stByte

         @Q      JSR L3 :: ECO_trimPair
                 JSR L1 :: 8T3_cede
                 RET

-------------------------------------------------------------------------------

A1 Preserve line offs
A2 Preserve str8 ptr

  *ECO_reml
              L3 REF :: ECO_Buf                 ; Base ptr target buf
                 JSR L3 L7 :: PFS_getDEndIndex  ; Current offs last data byte

              L1 GET A1
              L6 INT 0                          ; Length of deletable line
          @1     JSR L3 L1 DR :: 8T3_ldByte
                 GET L1 +1
                 GET L6 +1
              DR EQL ASC_linefeed
              DR ELS <1
              L7 SUB DR L6                      ; Current offs last data byte

                 JSR L3 DR :: PFS_getBUsed
                 SUB DR L6
                 JSR L3 DR :: PFS_setBUsed

              L6 GET A1
          @0     JSR L3 L1 DR :: 8T3_ldByte
                 JSR L3 L6 DR :: 8T3_stByte     ; Copy down n bytes
              L1 EQR L7
                 GET L1 +1
                 GET L6 +1
              DR ELS <0

                 JSR L3 :: ECO_trimPair
  RET

-------------------------------------------------------------------------------

  *ECO_commit

              L3 REF :: ECO_Buf                  ; Base ptr target buf
                 JSR L3 L7 :: PFS_getBUsed
              L1 SET :: 500                      ; Max bytes in block
              L7 GTR L1
              DR THN >0

              L5 REF :: ECO_Bix
                 JSR L3 L5 :: PFS_wrBlock        ; Write updated block and done
                 BRA >Q

           @0    SUB L7 L1                       ; Number of surplus bytes
                 JSR L6 :: PFS_alloc             ; Alloc/insert new block
                 JSR L3 L1 :: PFS_setBUsed
                 JSR L3 L4 :: PFS_getNext
                 JSR L3 L6 :: PFS_setNext        ; Update with new block index
                 JSR L3 L5 :: PFS_wrBlock        ; Update 1st blk

                 JSR L2 :: 8T3_claim
                 JSR L3 L2 :: PFS_cloneBBuf
                 JSR L2 L4 :: PFS_setNext        ; Set to previous nix
                 JSR L2 L7 :: PFS_setBUsed       ; Set num of remaining bytes
                 JSR L2 L5 :: PFS_setPrev        ; Link back to first block

              L5 INT PFS_OffsFData
                 SHL L5 1                        ; First data byte offset
              L7 ADD L5 L1

           @1    JSR L3 L7 DR :: 8T3_ldByte
                 JSR L2 L5 DR :: 8T3_stByte      ; Slam upper buf onto header
                 GET L7 +1
                 GET L5 +1
              L1 REP <1

                 JSR L2 L6 :: PFS_wrBlock        ; Update new block
                 JSR L2 :: 8T3_cede
                 JSR L3 :: ECO_trimPair
           @Q
           RET

-------------------------------------------------------------------------------

Zero out buffer pair from end of charge

A1 Preserve ptr to formatted block buffer

  *ECO_trimPair

                 JSR :: 8T3_msg :: 'Trimming buffer pair' 10 0

              L3 GET A1                          ; Base ptr target buf
                 JSR L3 L7 :: PFS_getDEndIndex   ; Offset of last data byte

              L1 SET :: 1024
              L7 GTR L1
              DR THN >Q
                 SUB L1 L7
              DR INT 0

           @0    JSR L3 L7 DR :: 8T3_stByte
                 GET L7 +1
              L1 REP <0
  @Q
  RET




