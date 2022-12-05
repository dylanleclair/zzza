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
    ; this causes the 'advance_level' subroutine to only be called once every n game loops
    ; currently only setup to work with multiples of 2
    lda     #$03                        ; for now, run advance_level once every 4 loops
    and     ANIMATION_FRAME             ; calculate (acc AND frame) to check if the low bit pattern matches a multiple of 4
    bne     advance_exit                ; if the AND operation didn't zero out, frame is not a multiple of 4. leave subroutine.

init_advance_loop
    jsr     lfsr                        ; update the lfsr

    ldy     #0                          ; initialize loop counter

advance_loop
    ; get the first half of the delta XOR operation
    lda     LEVEL_DATA,y                ; get the bit pattern onscreen at position y
    sta     LEVEL_DELTA,y               ; this is the first half of the data we need to find the delta

    ; shuffle the data array over by 2
    lda     LEVEL_DATA+2,y              ; get the byte currently stored at LEVEL_DATA[y+2]
    sta     LEVEL_DATA,y                ; store it at LEVEL_DATA[y]

    ; XOR the data at positions y and y+2
    eor     LEVEL_DELTA,y               ; XOR the pattern with the stuff that we previously placed in LEVEL_DELTA
    sta     LEVEL_DELTA,y               ; which parts of LEVEL_DATA[y] need to be animated

    iny                                 ; update loop counter
advance_test
    cpy     #34    
    bne     advance_loop                ; as long as y is not yet 34, jump up to top of loop

    ; check to see if we need to load end level pattern or usual random pattern
    lda     END_LEVEL_INIT              ; check the END_LEVEL flag, if set load in end level data
    beq     advance_new                 ; if END_LEVEL == 0, keep loading random patterns

end_pattern_load                        ; load in a piece of end level pattern
    ldx     END_PATTERN_INDEX           ; load the index into the current end level pattern
    lda     end_pattern,x               ; load the next level pattern
    dey                                 ; bring y back down to 33
    sta     LEVEL_DATA,y                ; store it in LEVEL_DATA at LEVEL_DATA[33]
    dex     
    dey
    sta     LEVEL_DATA,Y                ; store the next piece of LEVEL_DATA at LEVEL_DATA[32]
    dec     END_PATTERN_INDEX           ; decrement the end pattern index by 2
    dec     END_PATTERN_INDEX           ; decrement the end pattern index by 2

    rts

advance_new                             ; this section is responsible for filling in the last 2 array elements
    dey                                 ; bring y back down to 33

    lda     LFSR_ADDR                   ; we will use the lfsr to generate new data for the end of the array
    and     #$0f                        ; bitmask out the high nibble, leaving us with 0 <= a < 16
    tax                                 ; swap this over into X so we can use it as an index
    pha                                 ; put a copy on the stack for later, too
    jmp     advance_level_gen           ; jump down to the bitwise fun

advance_final                           ; fills in the very last byte of level data
    pla                                 ; grab our level index off the stack
    tax                                 ; flip it into x

    cpx     #0                          ; check if x is already 0
    beq     advance_level_gen           ; if it is already 0, don't decrement
    dex                                 ; otherwise, dec X by 1

advance_level_gen
    ; some bitwise fun to help level pieces 'clump' together nicely
    lda     STRIPS,x                    ; grab the strip located at strips[x]
    pha                                 ; put that strip on the stack for later

    lda     LFSR_ADDR                   ; we'll use the hi two bits of the same LFSR value
    rol                                 ; rol the accumulator to put the hi bit in the carry
    bcs     advance_gen                 ; if the carry is set (ie, hi bit was on), skip xor
    bmi     advance_gen                 ; if the new hi bit is on (ie, old 2nd highest bit was on), skip xor
    
    pla                                 ; else, get the strip back from the stack
    ora     LEVEL_DATA-2,y              ; add in the same blocks that were turned 'on' in the row above us
    jmp     advance_gen_check           ; jump down to loop check

advance_gen
    pla                                 ; get the strip back from the stack
advance_gen_check
    sta     LEVEL_DATA,y                ; store it in LEVEL_DATA[y]
    dey                                 ; decrement y
    cpy     #31                         ; while y != 31, branch up (should only execute once)
    bne     advance_final               ; branch up to the code where we deal with the final byte

advance_exit
    rts

