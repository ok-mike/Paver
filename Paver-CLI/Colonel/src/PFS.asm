
====== Paver File System ======================================================

 DEF PFS_O_ANY_type 0       ; These are offsets into block buffers
 DEF PFS_O_ANY_flavor 1
 DEF PFS_O_ANY_parent 2

 DEF PFS_O_STATE_tail 3
 DEF PFS_O_STATE_top 4
 DEF PFS_O_STATE_work 5
 DEF PFS_O_STATE_label 6

 DEF PFS_OffsFPrev 3 
 DEF PFS_OffsFNext 4        ; Offset to index of next block in file 
 DEF PFS_OffsFBCount 5      ; Offset to size of the data region
 DEF PFS_OffsFData  6       ; Offset to data region in buffer
 
 DEF PFS_O_FOLDER_begin 16
 DEF PFS_O_FOLDER_step 16

 DEF PFS_VOL_firstBlk  0 ; 992

 DEF PFS_I_STATE 0
 DEF PFS_I_ROOT 1

 DEF PFS_T_STATE 1          ; Block types
 DEF PFS_T_FOLDER 2
 DEF PFS_T_FILE 3
 DEF PFS_T_FREE_FILE 4
 DEF PFS_T_FREE_FOLDER 5

 *PFS_STATE_BUF    7000h    ; Buffer for volume state block (#0)
 @PFS_FILE_BUF     7100h    ; Reserved for FILE ops
 @PFS_FOLDER_BUF   7200h    ; Reserved for FOLDER ops

 @PFS_oFILE_lastbyte 0      ; Offset of last data byte in a FILE block
 @PFS_iFILE_next 0
 @PFS_FOLDER_next 0

 @PFS_oPOS 0                ; Byte offset into the block
 @PFS_oPOS_initial 0

-------------------------------------------------------------------------------
 
A1 Buffer keep
A2 Block index keep

 *PFS_rdBlock  L1 GET A1
               L2 GET A2
               L3 SET :: PFS_VOL_firstBlk
                  ADD L2 L3
               L3 INT 0
                  JSR L2 L1 L3 :: SPI_RDBLK 
                  RET

 *PFS_wrBlock  L1 GET A1
               L2 GET A2
               L3 SET :: PFS_VOL_firstBlk
                  ADD L2 L3
               L3 INT 0
                  JSR L2 L1 L3 :: SPI_WRBLK
                  RET

-------------------------------------------------------------------------------

A1 Preserve folder block index

  *PFS_FOLDER_init

  L3 REF :: PFS_FOLDER_BUF            ; Block buffer address       
  L2 GET A1
     JSR L3 L2 :: PFS_rdBlock

         L4 INT PFS_O_FOLDER_begin    ; Check if there is an entry
         L6 ADD L4 L3
         L3 LOD L6                    ; Target block of this entry
         L3 ELS >1                    ; If 0, then that signals empty folder
            JSR L3 :: PFS_FILE_init   ; Initialize first file, first block

         L3 INT PFS_O_FOLDER_step
            ADD L4 L3    
      @1 L4 PER :: PFS_FOLDER_next

 RET

-------------------------------------------------------------------------------

If there are no more blocks, return an error.
E  Return 0h on success, 1h on EOF (no more entries, no allocated file blocks)

 @PFS_FOLDER_ahead

            L2 REF :: PFS_FOLDER_next
            L2 EQL 0
             E GET DR                      ; Return value
            DR THN >1                      ; No more entries
          
            L7 REF :: PFS_FOLDER_BUF
            L5 ADD L7 L2
               LOD L5                      ; Current target
            L5 ELS >1
               JSR L5 :: PFS_FILE_init

            L5 INT PFS_O_FOLDER_step       ; Point to next entry
            L6 ADD L5 L2            
            L6 PER :: PFS_FOLDER_next
               RET

        @1   E INT 1
               RET

-------------------------------------------------------------------------------

A1 Preserve block index

 @PFS_FILE_loadBlock
 
         L3 REF :: PFS_FILE_BUF        ; Block buffer address
         L4 REF :: PFS_oPOS_initial
         L4 PER :: PFS_oPOS
         
  L2 GET A1
     JSR L3 L2 :: PFS_rdBlock

            JSR L3 L7 :: PFS_getBUsed
         L7 PER :: PFS_oFILE_lastbyte

         L7 INT PFS_OffsFNext          ; Offset to parameter              
            ADD L7 L3
            LOD L7                     ; Index of next block, or zero = EOF
         L7 PER :: PFS_iFILE_next

 RET

-------------------------------------------------------------------------------

A1 Preserve block index

 *PFS_FILE_init

         L3 REF :: PFS_FILE_BUF
         L4 INT PFS_OffsFData        ; Data region begins after block header
            SHL L4 1                 ; Multiply by 2 to get byte offset
         L4 PER :: PFS_oPOS_initial  ; Keep this for later, doesn't change
         L4 PER :: PFS_oPOS

         L1 GET A1
            JSR L1 :: PFS_FILE_loadBlock    
 RET 

-------------------------------------------------------------------------------

A1 Return last offset

 @PFS_FILE_lastBOffs

            L6 REF :: PFS_FILE_BUF             ; Block buffer address
               JSR L6 L7 :: PFS_getBUsed
            DR INT PFS_OffsFData               ; Add to start of data region
               SHL DR 1                        ; Convert to bytes
               ADD L7 DR                       ; Last byte offs of data region
            A1 GET L7   
               RET

-------------------------------------------------------------------------------

Copy shorts from the file block buffer to a target buffer until a line break is
found. Handle loading the next block in the file transparently.
Return the number of _bytes_ copied. Also return an error code.  

A1 Preserve pointer to target buffer     
A2 Return number of bytes read
A3 Input 0:Batch 1:No batching
E  Return 0h on success, 1h on NULL
                                         ; First block loaded by PFS_FILE_init
 *PFS_FILE_getLine
  
            L2 REF :: PFS_oPOS           ; Byte position in block buffer
            L3 GET A1                    ; Pointer to target buffer
            L4 INT 0                     ; Byte offset into target buffer
            L6 REF :: PFS_FILE_BUF       ; Block buffer address
            A2 INT 0                     ; Number of bytes read
            
               JSR L7 :: PFS_FILE_lastBOffs

        @1  L7 EQR L2
            DR ELS >3                    ; Same block, next pair of bytes
             E GET A3
               JSR :: PFS_FILE_nextBlock ; Load next block of file into buf
             E THN >2                    ; No more blocks, EOF
            L2 REF :: PFS_oPOS
            
               JSR L7 :: PFS_FILE_lastBOffs

          @3   JSR L6 L2 L5 :: 8T3_ldByte
               JSR L3 L4 L5 :: 8T3_stByte

               GET L4 +1
               GET L2 +1
               GET A2 +1

             E INT 1                     ; Prepare NULL flag
            L5 ELS >2                    ; Branch if NULL
             E INT 0                     ; Return not NULL
            L5 EQL ASC_linefeed
            DR ELS <1

        @2  L1 GET E
            
               GET L4 -1
            L5 INT 0   
               JSR L3 L4 L5 :: 8T3_stByte
               GET L4 +1

            L2 PER :: PFS_oPOS

               SHR L4 1
               ADD L3 L4
             E INT 0
             E STO L3

             E GET L1
               RET

-------------------------------------------------------------------------------

Update the PFS_ parameters and load the next block of the file.
If there are no more blocks, return an error.

E Input: 0:Batch 1:No batching
E Return 0h on success, 1h on EOF (no more blocks)

 @PFS_FILE_nextBlock

            L7 GET E

            L3 REF :: PFS_FILE_BUF     ; Buffer address
            L1 INT PFS_OffsFNext       ; Offset of next block index
               ADD L1 L3
            L2 LOD L1                  ; Index of next block
             E INT 1                   ; Prepare ret val for branch
            L2 ELS >0                  ; No more blocks in FILE but try FOLDER
          
               JSR L3 L2 :: PFS_rdBlock

            L4 INT PFS_OffsFData       ; Data region begins after block header
            L5 SHL L4 1                ; Multiply by 2 to get byte offset
            L5 PER :: PFS_oPOS         ; Reset to starting position
             E INT 0
               RET

            @0 L7 THN >1 
               JSR :: PFS_FOLDER_ahead ; Function provides E return value
            @1 RET

-------------------------------------------------------------------------------

 *PFS_getState
 
         L1 REF :: PFS_STATE_BUF
         L2 INT PFS_I_STATE
            JSR L1 L2 :: PFS_rdBlock
            RET

 *PFS_putState
 
         L1 REF :: PFS_STATE_BUF
         L2 INT PFS_I_STATE
            JSR L1 L2 :: PFS_wrBlock
            RET

-------------------------------------------------------------------------------

STATE.tail is 0: Try GROW - increment TOP and allocate that block
ELSE
FILE: Keep head block until no more data blocks, allocate data or head block
FOLDER: Deallocate all 15 entries, then allocate the folder block

A1 Returns the index of a free block, or 0

 *PFS_alloc
      
           JSR :: PFS_getState
        L1 REF :: PFS_STATE_BUF

        L2 INT PFS_O_STATE_tail       ; Get freelist pointer
           ADD L2 L1
        L4 LOD L2                     ; STATE.tail
        L4 THN >1

        L7 INT PFS_O_STATE_top        ; Freelist empty, try to GROW the volume
           ADD L7 L1
        L5 LOD L7
        L6 SET :: FFFFh
        L4 INT 0                      ; Assume return value: volume full
        L5 EQR L6                     ; Volume already at max size?
        DR THN >3
        L4 GET L5
           GET L5 +1                  ; Update TOP
        L5 STO L7
           BRA >3

    @1     JSR L3 :: 8T3_claim
           JSR L3 L4 :: PFS_rdBlock   ; Load freelist tail block
         E INT PFS_O_ANY_type
           ADD E L3
           LOD E                      ; Block type 
         E EQL PFS_T_FILE
        DR THN >2

         ;  JSR :: 8T3_msg :: 'Undoing folder #' 0
         ;  JSR L4 :: 8T3_hex
         ;  JSR :: 8T3_msg :: 10 0

           JSR L3 :: PFS_undoFolder     ; Undo the folder by entries 
           JSR L3 :: PFS_clearBuffer
           JSR L3 L4 :: PFS_wrBlock
           JSR L3 :: 8T3_cede
           BRA >3

    @2     JSR L3 L4 :: PFS_pluckFile   ; Pluck block from FILE list
           JSR L3 :: PFS_clearBuffer
           JSR L3 L4 :: PFS_wrBlock
           JSR L3 :: 8T3_cede
           BRA >3

    @3     JSR :: PFS_putState
        A1 GET L4     
           RET

-------------------------------------------------------------------------------

Helper function for PFS_alloc
Keep head block until no more data blocks, allocate data or head block
STATE has been loaded, caller updates
A1 Preserve: block buffer loaded with bix A2
A2 In: Index of FILE head block, out: Index of allocatable block

 @PFS_pluckFile

        L1 GET A1                     ; Head block of a deleted FILE
           JSR L6 :: 8T3_claim

        L7 GET A2
       ;    JSR :: 8T3_msg :: 'Plucking at ' 0
       ;    JSR L7 :: 8T3_hex
       ;    JSR :: 8T3_msg :: 10 0
        
        L2 INT PFS_OffsFNext
        L4 ADD L2 L1
        L3 LOD L4                     ; Next FILE block or 0
        L3 ELS >1                     ; Branch if only HEAD block left 

           JSR L6 L3 :: PFS_rdBlock   ; Child of HEAD block
        DR ADD L6 L2                  ; Leave head block in freelist unchanged
           LOD DR                     ; but point its NEXT to NEXT of child
        DR STO L4                     ; and allocate child
 
        L2 GET A2
           JSR L1 L2 :: PFS_wrBlock   ; Update HEAD block to new child
        A2 GET L3                     ; Return skipped child of HEAD block
           BRA >2
    @1
        L5 REF :: PFS_STATE_BUF       ; Only the HEAD is left
         E INT PFS_O_STATE_tail       ; Skip it in the freelist
           ADD L5 E                   ; and allocate it
         E INT PFS_O_ANY_parent
        L7 ADD L1 E
           LOD L7                     ; Parent of HEAD
        L7 STO L5                     ; Store as new HEAD, allocate A1

         ;  JSR :: 8T3_msg :: 'Undoing file head' 10 0

     @2    JSR L6 :: 8T3_cede
           RET

-------------------------------------------------------------------------------

Helper function for PFS_alloc
Deallocate all 15 entries, then allocate the folder block
STATE has been loaded, caller updates
A1 Preserve: block buffer loaded with block to undo

 @PFS_undoFolder

        L1 GET A1

        L5 REF :: PFS_STATE_BUF
         E INT PFS_O_STATE_tail       ; Skip A1 in the freelist
           ADD L5 E                   ; and allocate it
         E INT PFS_O_ANY_parent
        L7 ADD L1 E
           LOD L7                     ; Parent of A1
        L7 STO L5                     ; Store as new HEAD, allocate A1

        L6 INT 15                     ; Loop through 15 folder entries
        L2 INT PFS_O_FOLDER_begin     ; and deallocate each one
           ADD L2 L1                  ; Point L2 to first entry
        L3 INT PFS_O_FOLDER_step   
     @1 L7 LOD L2
        L7 ELS >2                     ; Branch if entry empty
           JSR L7 :: PFS_dealloc 

     @2    ADD L2 L3
        L6 REP <1         
           RET

-------------------------------------------------------------------------------

Prepend deallocated block to freelist.
The freelist works backwards, its head is STATE.
STATE has a pointer to the tail.
Deallocating a block is done by pointing STATE to it, and setting the parent
of the deallocated node to the previous pointer STATE had.

A1 Preserve index of block to deallocate

 *PFS_dealloc

        L1 GET A1
        L1 EQL PFS_I_ROOT
        DR THN >1                     ; Don't delete ROOT folder

           JSR :: PFS_getState
        L7 REF :: PFS_STATE_BUF
        L5 INT PFS_O_STATE_tail       ; Adjust freelist pointer
           ADD L5 L7
        L6 LOD L5                     ; STATE.tail
        L1 STO L5                     ; Deallocated block is new freelist tail
           JSR :: PFS_putState

           JSR L2 :: 8T3_claim
           JSR L2 L1 :: PFS_rdBlock
        L5 INT PFS_O_ANY_parent
           ADD L5 L2
        L6 STO L5                     ; Previous tail now before deallocated

        L5 LOD L2

           JSR L2 L1 :: PFS_wrBlock   ; Update deallocated block
           JSR L2 :: 8T3_cede
 
         ;  JSR :: 8T3_msg :: 'Deallocated #' 10 0
         ;  JSR L1 :: 8T3_dec
         ;  JSR :: 8T3_msg :: 10 0
         ;  JSR :: 8T3_msg :: 'Type was ' 10 0
         ;  JSR L5 :: 8T3_dec
         ;  JSR :: 8T3_msg :: 10 0

      @1   RET

-------------------------------------------------------------------------------

A1 Preserve bix
A2 Preserve parent
E Preserve type

 *PFS_wrHeader

            JSR L1 :: 8T3_claim
            JSR L1 L2 :: PFS_rdBlock

         L2 GET A1
         L3 INT 1
         L4 GET A2

         L5 INT PFS_O_ANY_type
            ADD L5 L1          
          E STO L5

         L5 INT PFS_O_ANY_flavor
            ADD L5 L1           
         L3 STO L5

         L5 INT PFS_O_ANY_parent
            ADD L5 L1           
         L4 STO L5
            
            JSR L1 L2 :: PFS_wrBlock
            JSR L1 :: 8T3_cede
            RET

-------------------------------------------------------------------------------

A1 Preserve buffer to clear

 *PFS_clearBuffer

   L1 INT 0
   L2 SET :: 256
   L3 GET A1

   @1  L1 STO L3
          GET L3 +1
       L2 REP <1

 RET

-------------------------------------------------------------------------------

Load block into buffer and return number of bytes stored

A1 Preserve block buffer
A2 Preserve block index
A3 Return number of data bytes stored

 @PFS_BlockPos

      L1 GET A1
      L2 GET A2

         JSR L1 L2 :: PFS_rdBlock
         JSR L1 L7 :: PFS_getBUsed

      A3 GET L7
      RET

-------------------------------------------------------------------------------

Populates a file from a memory buffer. Allocates additional data blocks.
We update all blocks. First block must be cleared (!) expressly, or appending.

A1 Preserve source buffer
A2 Preserve target block
A3 Preserve number of cells to write
E  Return last block allocated

  *PFS_bufToFile

         L1 GET A1
         L2 GET A2
         L6 GET A3
            JSR L3 :: 8T3_claim

            JSR L3 L2 L4 :: PFS_BlockPos  ; Load blk, get bytes in blk
            SHR L4 1                      ; Convert to cells

         L5 ADD L6 L4
          E INT PFS_OffsFData             ; Cell offset to data
            ADD L4 E                      ; Now resume bufpos
          E SET :: 256
         L4 EQR E
         DR THN >C
            BRA >1

     @0  L5 GET L6                        ; Remaining at beginning of block
     @1  L7 ADD L4 L3                     ; OK to use L7 here, block pos
          E LOD L1                        ; Get cell from source buffer
          E STO L7                        ; Store into file buffer
            GET L6 -1
            GET L1 +1
            GET L4 +1
          E SET :: 256
         L4 EQR E
         DR THN >C

         L6 ELS >2
            BRA <1

     @C     JSR L7 :: PFS_alloc           ; Block buffer full, new block
         L7 ELS >3                        ; No space in volume
         DR INT PFS_OffsFNext             ; Link new after existing block
            ADD DR L3
         L7 STO DR
          E INT PFS_OffsFData             ; L4 is 256 here
         L5 SUB L4 E                      ; Don't count block header

     @2     SHL L5 1                      ; Convert words to bytes
            JSR L3 L5 :: PFS_setBUsed
            JSR L3 L2 :: PFS_wrBlock      ; Update existing block
         DR INT 1                         ; Fake parent !?
          E INT PFS_T_FILE
            JSR L2 DR :: PFS_wrHeader
         L6 ELS >3                        ; Finish if we had no allocation   

            JSR L3 :: PFS_clearBuffer     ; Now use buffer for new block
         L5 INT PFS_OffsFPrev             ; OK to use L5 now
            ADD L5 L3
         L2 STO L5                        ; Point new block back to previous
            JSR L3 L7 :: PFS_wrBlock      ; Update existing block
         L2 GET L7
         L4 INT PFS_OffsFData             ; Reset to first data cell
            JUMP :: <0

     @3
          E GET L2
            JSR L3 :: 8T3_cede 
       
            RET

-------------------------------------------------------------------------------

Fills a memory buffer from a file block. Pulls in all remaining data blocks.

A1 Preserve target buffer
A2 Preserve source block
A3 Return number of cells read
A4 Function pointer to run for each block

 *PFS_fileToBuf

         L1 GET A1
         L2 GET A2
         A3 INT 0                       ; Number of cells read
            JSR L3 :: 8T3_claim
            JSR L3 L2 :: PFS_rdBlock    ; Load first src blk into the buf
         
     @0  L4 INT PFS_OffsFData           ; Cell offset to data
            JSR L3 L6 :: PFS_getCUsed
            ADD A3 L6                   ; Add to count
            ADD L6 L4                   ; Offs of last data word in blk

         DR GET A4
            JSR L1 L3 L4 L6 :: 0        ; Copy cells, block or whatever        
            JSR L3 :: PFS_tryNextBlock
          E ELS <0

            JSR L3 :: 8T3_cede
            RET

  *PFS_cpHelper

         L1 GET A1  ; Target buffer
         L3 GET A2  ; Block buffer
         L4 GET A3  ; First data cell offset in block
         L6 GET A4  ; Last data cell offset in block
     @1
         L4 EQR L6
         DR THN >2  ; All data cells read

         L5 ADD L3 L4
          E LOD L5
          E STO L1
            GET L1 +1
            GET L4 +1
            BRA <1

        @2  RET

 
  *PFS_rdvHelper

         L1 GET A1  ; Target buffer
         L3 GET A2  ; Block buffer
         L4 GET A3  ; First data cell offset in block
         L6 GET A4  ; Last data cell offset in block
 
            ADD L3 L4
            SUB L6 L4

          E SET :: RDV_VM_PushesBlk
            RDV L3 L6

            RET

-------------------------------------------------------------------------------

Load next block of the file. If there are no more blocks, return an error.

A1 Preserve block buffer
E Return 0h on success, 1h on EOF (no more blocks)

 @PFS_tryNextBlock

            L3 GET A1                     ; Block buffer address
               JSR L3 L2 :: PFS_getNext
             E INT 1                      ; Prepare ret val for branch
            L2 ELS >0                     ; No more blocks in FILE
               JSR L3 L2 :: PFS_rdBlock
             E INT 0

            @0 RET

-------------------------------------------------------------------------------

A1 Preserve folder buffer
A2 Preserve pointer to cstr
A3 Return entry offset or 0

 *PFS_entryByName

        L1 GET A1
        L2 GET A2

        L4 INT PFS_O_FOLDER_step
        L3 INT PFS_O_FOLDER_begin
        A3 GET L3
           ADD L3 L1
           GET L3 +1                ; Point to name
        L5 INT 15
        L6 INT 0                    ; Termination character
 
     @1    JSR L3 L2 L6 :: 8T3_strCmp
         E THN >SUCC
           ADD A3 L4
           ADD L3 L4
        L5 REP <1

  @FAIL A3 INT 0
  @SUCC    RET

-------------------------------------------------------------------------------

A1 Change entry index to buffer offset

 *PFS_entryOffs

       L1 GET A1
       L2 INT PFS_O_FOLDER_step
          JSR L1 L2 L3 L4 :: 8T3_uMul
       A1 INT PFS_O_FOLDER_begin
          ADD A1 L3
          RET

------------------------------------------------------------------------------- 
Caller must update the folder!

A1 Persist buffer
A2 Persist entry offset to remove, including deallocation of target block

 *PFS_delEntry

       L6 GET A1                    ; Buffer
       L1 GET A2                    ; Entry offset
          ADD L6 L1                 ; Buffer start addr of entry
       L7 LOD L6                    ; Entry target
       
       L2 INT 0
       L3 INT PFS_O_FOLDER_step
    @1 L2 STO L6
          GET L6 +1
       L3 REP <1

          JSR L7 :: PFS_dealloc
 RET

-------------------------------------------------------------------------------

A1 Preserve folder buffer
A2 Preserve target
A3 Preserve pointer to cstr

 *PFS_createEntry

        L1 GET A1
        L3 GET A3

        L4 INT PFS_O_FOLDER_step
        L5 INT PFS_O_FOLDER_begin
           ADD L5 L1                ; Point to base entry

        L6 INT 15                   ; Find an empty entry
     @1 DR LOD L5
        DR ELS >2
           ADD L5 L4
        L6 REP <1
           BRA >4

     @2 A2 STO L5                   ; Found empty entry, store target index
           GET L5 +1                ; Point to entry name
           GET L4 -1                ; Label max chars (exclude target cell)
     @3
         E LOD L3
         E STO L5
         E ELS >4
           GET L3 +1
           GET L5 +1
        L4 REP <3

     @4    RET

-------------------------------------------------------------------------------

A1 Preserve str0 ptr
A2 Return block index

 @TEMPVAR 0
 *PFS_pathToBix                                ; Traverse hierarchy with L2

       L7 GET A1
       L5 INT 0                                ; Byte index into A1 string
       L4 LOD L7
       L4 ELS >FAIL                            ; Empty string

          JSR L1 :: 8T3_claim
       L2 INT 0                                ; Load ROOT 0 or 1
          JSR L1 L2 :: PFS_rdBlock             ; Load folder
        E LOD L1 PFS_O_ANY_type                ; Check if folder, else ld 1
        E EQL PFS_T_FOLDER
       DR THN >ABS
       L2 INT 1

  @ABS DR SHR L4 8                             ; First char8
       DR EQL ASC_fwdSlash
       DR ELS >REL
       DR SET :: FFh
          AND L4 DR
       L4 ELS >SUCC                            ; Slash only, root folder     

          GET L5 +1                            ; Skip slash        
          BRA >NXTBLK

  @REL L2 LOD L1 PFS_O_STATE_work              ; Load CWD

      @NXTBLK  L5 PER :: <TEMPVAR
                  JSR L1 L2 :: PFS_rdBlock     ; Load next folder 
               L3 INT 15                       ; 15 entries
                E INT PFS_O_FOLDER_begin
               L4 GET L1 

    @NXTENTRY  L5 REF :: <TEMPVAR
                  ADD L4 E                     ; Current folder entry
               L2 LOD L4                       ; Target BIX / next block
               L2 THN >CMP                     ; Slot not empty, compare

           @0     GET L3 -1                    ; Empty, one less to check
               L3 ELS >FAIL                    ; Path component not found
                E INT PFS_O_FOLDER_step
                  BRA <NXTENTRY

         @CMP  L6 INT 2                        ; Byte index into L4 string
                                               ; Number 2: skip target cell

     @NXTCHAR     JSR L7 L5 DR :: 8T3_ldByte       ; Buffer offset return-byte
                E GET DR
            @1  E EQL ASC_fwdSlash             ; End of subfolder name?
                  GET L5 +1                    ; Advance one char for next
               DR THN <NXTBLK                  ; Slash was skipped above

                  JSR L4 L6 DR :: 8T3_ldByte       ; Ordinary char to match
                  GET L6 +1                    ; Advance one char for next
                E EQR DR
               DR ELS <0                       ; Entry doesn't match
                E ELS >SUCC                    ; Both NULL - end of path
                  BRA <NXTCHAR

    @SUCC    JSR L1 :: 8T3_cede
          A2 GET L2
             RET

    @FAIL    JSR L1 :: 8T3_cede
          A2 INT 0
             RET

-------------------------------------------------------------------------------

A1 Preserve folder index
A2 Preserve cstr0 subfolder name
A3 Return entry index

 *PFS_targetByName

             JSR L1 :: 8T3_claim
          L2 GET A1
          L3 GET A2

             JSR L1 L2 :: PFS_rdBlock
             JSR L1 L3 L4 :: PFS_entryByName
          L4 ELS >FAIL   
          L5 ADD L1 L4
          A3 LOD L5

             JSR L1 :: 8T3_cede
             RET

        @FAIL    JSR L1 :: 8T3_cede 
              A3 INT 0 
                 RET


-------------------------------------------------------------------------------

A1 Volume label str8

    *PFS_format
      
       L4 INT 0                           ; Create volume block
          JSR L3 :: 8T3_claim
          JSR L3 :: PFS_clearBuffer
        
        E INT 0
        E STO L3 PFS_O_ANY_type
        E STO L3 PFS_O_ANY_flavor
        E INT 0
        E STO L3 PFS_O_ANY_parent
        E INT 0
        E STO PFS_O_STATE_tail
        E INT 2
        E STO PFS_O_STATE_top
        E INT 1
        E STO PFS_O_STATE_work

          ; Copy volume label

          JSR L3 L4 :: PFS_wrBlock


       L4 INT 1                            ; Create root folder
          JSR L3 :: PFS_clearBuffer
          JSR L3 L4 :: PFS_wrBlock
        E INT PFS_T_FOLDER
       DR INT 0
          JSR L4 DR :: PFS_wrHeader


          JSR L3 :: 8T3_cede
          RET

-------------------------------------------------------------------------------

Delete existing file if present, return formatted head bix

A1 Preserve path bix
A2 Preserve fname ptr
A3 Return head bix

  *PFS_forceFile       ; Make a similar func force/buildFolder

      L2 GET A1
      L4 GET A2

         JSR L3 :: 8T3_claim

         JSR L3 L2 :: PFS_rdBlock 
         JSR L3 L4 L5 :: PFS_entryByName
      L5 ELS >1    
         JSR L3 L5 :: PFS_delEntry       ; Deallocate old version

     @1  JSR L6 :: PFS_alloc
         JSR L3 L6 L4 :: PFS_createEntry                     
         JSR L3 L2 :: PFS_wrBlock

       E INT PFS_T_FILE                  ; Setup new blk
         JSR L6 L2 :: PFS_wrHeader

         JSR L3 :: 8T3_cede

      A3 GET L6 
         RET

-------------------------------------------------------------------------------

A1 Preserve head bix

  *PFS_pullFile

           JSR L1 :: 8T3_claim
        L3 GET A1

   @GET  E SET :: RDV_VM_PullsBlock
           RDV L1 L2                        ; Hen fills buffer, sets E
         E ELS >DONE 

           JSR L1 L3 L2 :: PFS_bufToFile
        L3 GET E
           BRA <GET

  @DONE    JSR L1 :: 8T3_cede
           RET

-------------------------------------------------------------------------------

A1 Preserve block buffer
A2 Return working bix

  *PFS_rdWorking

          JSR :: PFS_getState
       L1 REF :: PFS_STATE_BUF
       DR SET :: PFS_O_STATE_work
          ADD DR L1
          LOD DR

       L2 GET A1
          JSR L2 DR :: PFS_rdBlock
        
   A2 GET DR      
   RET

-------------------------------------------------------------------------------

A1 Preserve block buffer
A2 Preserve target bix
A3 Return entry offset or 0

  *PFS_entryByTarget

        L1 GET A1
        L2 GET A2

        L4 INT PFS_O_FOLDER_step
        L3 INT PFS_O_FOLDER_begin
        A3 GET L3
           ADD L3 L1

        L5 INT 15
 
     @1  E LOD L3
         E EQR A2
        DR THN >SUCC 
           ADD A3 L4
           ADD L3 L4
        L5 REP <1

  @FAIL A3 INT 0
  @SUCC    RET

-------------------------------------------------------------------------------

A1 Preserve claim
A2 Preserve bix
A3 Return str8 ptr inside A1 claim

  @ROOTSTR 'Root' 0
  *PFS_getBixName

            L1 GET A1
            L2 GET A2

                     L2 ELS >1     ; Call #0 and #1 'Root'
                     L2 EQL 1
                     DR ELS >1               
                     A3 SET :: ROOTSTR
                        BRA >END

                @1      JSR L1 L2 :: PFS_rdBlock
                     DR SET :: PFS_O_ANY_parent
                        ADD DR L1
                        LOD DR

                        JSR L1 DR :: PFS_rdBlock  
                        JSR L1 L2 L3 :: PFS_entryByTarget
                     L3 ELS >END

                        ADD L3 L1
                     A3 GET L3 +1   
   @END
   RET

-------------------------------------------------------------------------------

A1 Preserve bix

  *PFS_prBix
                L1 GET E

                        JSR :: 8T3_msg :: '(#' 0
                      E GET A1
                        JSR :: 8T3_prUDec
                        JSR :: 8T3_msg :: ')' 0

                 E GET L1
   RET

-------------------------------------------------------------------------------

A1 Preserve str8 pointer to path
A2 Preserve base, return str8 filename

Replace final slash by NULL character and return ptr to second str0

  *PFS_cutFName8

       L1 GET A1                        ; Base str8
       L2 INT 0                         ; Offs str8
       L4 INT ASC_fwdSlash

       L5 GET L1
   @1   E LOD L5                        ; Scan str16 to final NULL
          GET L5 +1
        E THN <1
          GET L5 -1
       L2 SHL L5 1                      ; Turn into offs str8
     
   @2     JSR L1 L2 L3 :: 8T3_ldByte    ; Scan backwards to /
       L7 GET L2                        ; Keep slash pos for NULL
       L3 EQR L4
       DR THN >SLASH
       L2 ELS >3                        ; Pos 0 still no slash
          GET L2 -1
          BRA <2

   @SLASH      GET L2 +1                ; Skip slash in fname offs
            L2 ELS >3
   @BARE       GET L7 +1                ; Keep the slash if at pos 0

   @3  L5 GET A2
       L6 INT 0
   @4     JSR L1 L2 L3 :: 8T3_ldByte
          JSR L5 L6 L3 :: 8T3_stByte
          GET L2 +1
          GET L6 +1
       L3 THN <4

       L3 INT 0                         ; Terminate filename
          SHR L6 1
       DR ADD L5 L6 
       L3 STO DR

          JSR L1 L7 L3 :: 8T3_stByte
          GET L7 +1
          SHR L7 1
       DR ADD L1 L7     
       L3 STO DR                       ; Truncate to path in orig str

  @END
  RET

-------------------------------------------------------------------------------

Zero out buffer from end of charge

A1 Preserve ptr to formatted block buffer

  *PFS_trimBuffer

              L3 GET A1                          ; Base ptr target buf
                 JSR L3 L7 :: PFS_getDEndIndex   ; Offset of last data byte

              L1 SET :: 511
              L7 GTR L1
              DR THN >Q
                 GET L7 +1
                 SUB L1 L7
  
              DR INT 0
           @0    JSR L3 L7 DR :: 8T3_stByte
                 GET L7 +1
              L1 REP <0
  @Q
  RET

-------------------------------------------------------------------------------

A1 Preserve buffer ptr
A2 Return number of bytes used

  *PFS_getCUsed

        L7 INT 0
           BRA >0

  *PFS_getBUsed

        L7 INT 1

    @0  L1 GET A1
        L2 INT PFS_OffsFBCount
           ADD L2 L1
        A2 LOD L2                ; Number of bytes used        
        L7 THN >Q
           SHR A2 1
    @Q     RET

-------------------------------------------------------------------------------

A1 Preserve buffer ptr
A2 Preserve number of bytes used

  *PFS_setCUsed

        L7 INT 0
           BRA >0

  *PFS_setBUsed

        L7 INT 1

    @0  L1 GET A1
        L2 INT PFS_OffsFBCount
           ADD L2 L1             ; Address of number of bytes used

        L7 THN >1
           SHL A2 1

    @1  A2 STO L2
           RET

-------------------------------------------------------------------------------

A1 Preserve buffer ptr
A2 Return cell ptr to first data cell

  *PFS_getDStartPtr

     L1 GET A1
     L2 INT PFS_OffsFData
     A2 ADD L2 L1

  RET

-------------------------------------------------------------------------------

A1 Preserve buffer ptr
A2 Return byte index of last data cell

  *PFS_getDEndIndex

     L1 GET A1
     L2 INT PFS_OffsFData
        SHL L2 1
        JSR L1 L3 :: PFS_getBUsed
     A2 ADD L2 L3

  RET

-------------------------------------------------------------------------------

A1 Preserve buffer ptr
A2 Return next bix

  *PFS_getNext

     L1 GET A1
     L2 INT PFS_OffsFNext
        ADD L2 L1
     A2 LOD L2

  RET

-------------------------------------------------------------------------------

A1 Preserve buffer ptr
A2 Preserve next bix

  *PFS_setNext

     L1 GET A1
     L2 INT PFS_OffsFNext
        ADD L2 L1
     A2 STO L2

  RET

-------------------------------------------------------------------------------

A1 Preserve buffer ptr
A2 Return prev bix

  *PFS_getPrev

     L1 GET A1
     L2 INT PFS_OffsFPrev
        ADD L2 L1
     A2 LOD L2

  RET

-------------------------------------------------------------------------------

A1 Preserve buffer ptr
A2 Preserve prev bix

  *PFS_setPrev

     L1 GET A1
     L2 INT PFS_OffsFPrev
        ADD L2 L1
     A2 STO L2

  RET

-------------------------------------------------------------------------------

A1 Preserve bbuf ptr src
A2 Preserve bbuf ptr dst

  *PFS_cloneBBuf

       L1 GET A1
       L2 GET A2

          JSR L2 :: PFS_clearBuffer

       L3 INT 6
   @0   E LOD L1
        E STO L2
          GET L1 +1
          GET L2 +2
       L3 REP <0   

  RET

-------------------------------------------------------------------------------

A1 Preserve dictionary bix
A2 Preserve function to call for each entry (fheadbix, fnameptr8)

  *PFS_traverse

               JSR L3 :: 8T3_claim
            
            L1 GET A1
               JSR L3 L1 :: PFS_rdBlock
            L7 INT PFS_O_FOLDER_begin
               ADD L7 L3
            L5 INT 15
    @1      L4 LOD L7                     ; Target entry
            L4 ELS >2
            L1 GET L7 +1                  ; Skip to entry name
               
               JSR L1 :: 8T3_prStr8
               JSR :: 8T3_msg :: 10 0

        ;    DR GET A2
        ;       JSR L4 L1 :: 0

             E INT PFS_O_FOLDER_step
               ADD L7 E
            L5 REP <1

    @2         JSR L3 :: 8T3_cede
       
       RET







