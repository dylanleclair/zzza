; -----------------------------------------------------------------------------
; SUBROUTINE: ADVANCE_LEVEL
; - goes through the 34-byte 'LEVEL_DATA' array, shuffling all elements by 2
; - so LEVEL_DATA[2] will be placed in LEVEL_DATA[0], etc
; - the data in LEVEL_DATA[0] and LEVEL_DATA[1] is lost as it is no longer needed
; - the data in LEVEL_DATA[32] and LEVEL_DATA[33] is generated using the LFSR
; - additionally, calculates the deltas that will be stored in LEVEL_DELTAS
; - the deltas are essentially a representation of which parts of the screen need to animate
;   and which will stay the same 
;
; - NOTE: technically, LEVEL_DELTA is defined as being 34 bytes long even though it only holds
;         32 bytes of 'good' data however, the code to deal with LEVEL_DATA and LEVEL_DELTA 
;         being different lengths takes up way more than 2 bytes, so it's better for 
;         LEVEL_DELTA to just be too long.
; -----------------------------------------------------------------------------
advance_level
    lda     PROGRESS_BAR
    bmi     advance_exit                ; negative progress bar means level is complete, don't advance

    ; this causes the 'advance_level' subroutine to only be called once every n game loops
    ; currently only setup to work with multiples of 2
    lda     #$03                        ; for now, run advance_level once every 4 loops
    and     ANIMATION_FRAME             ; calculate (acc AND frame) to check if the low bit pattern matches a multiple of 4
    bne     advance_exit                ; if the AND operation didn't zero out, frame is not a multiple of 4. leave subroutine.

advance_char_pos
    lda     #$4b                        ; memory location 004b is where player's newX and newY are stored
    sta     WORKING_COOR                ; store it so the block check can use it for indirect addressing
    jsr     check_block_down            ; check if there's a block under the player
    beq     init_advance_loop           ; if not, (return of 0 means no block) then don't lift the sprite up
    dec     NEW_Y_COOR                  ; the level is moving up, so the player sprite also needs to move up

init_advance_loop
    ldy     #0                          ; initialize loop counter
    ldx     #2                          ; we need an offset that is always 2 ahead of y

advance_loop
    ; get the first half of the delta XOR operation
    lda     LEVEL_DATA,y                ; get the bit pattern onscreen at position y
    sta     LEVEL_DELTA,y               ; this is the first half of the data we need to find the delta

    ; shuffle the data array over by 2
    lda     LEVEL_DATA,x                ; get the byte currently stored at LEVEL_DATA[x], which is LEVEL_DATA[y+2]
    sta     LEVEL_DATA,y                ; store it at LEVEL_DATA[y]

    ; XOR the data at positions y and y+2
    eor     LEVEL_DELTA,y               ; XOR the pattern with the stuff that we previously placed in LEVEL_DELTA
    sta     LEVEL_DELTA,y               ; which parts of LEVEL_DATA[y] need to be animated

    iny                                 ; update both loop counters
    inx

advance_test
    cpy     #34    
    bne     advance_loop                ; as long as y is not yet 34, jump up to top of loop

advance_new                             ; this section is responsible for filling in the last 2 array elements
    dey                                 ; bring y back down to 33

    lda     LFSR_ADDR                   ; we will use the lfsr to generate new data for the end of the array
    and     #$0f                        ; bitmask out the high nibble, leaving us with 0 <= a < 16
    tax                                 ; swap this over into X so we can use it as an index
    lda     STRIPS,x                    ; grab the strip located at strips[x]
    sta     LEVEL_DATA,y                ; store it in LEVEL_DATA[33]

    dey                                 ; bring y down to 32

    cpx     #0                          ; check if x is already 0
    beq     advance_final               ; if it is already 0, don't decrement
    dex                                 ; otherwise, dec X by 1
    lda     STRIPS,x                    ; grab the strip located at strips[x]

advance_final
    sta     LEVEL_DATA,y                ; store it in LEVEL_DATA[32]

advance_exit
    rts

