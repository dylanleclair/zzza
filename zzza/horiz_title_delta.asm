; -----------------------------------------------------------------------------
; SUBROUTINE: HORIZONTAL TITLE DELTA
; - calculates the delta of the screen data to prepare to scroll left
; - this is built to be particular to the title screen!
; -----------------------------------------------------------------------------

; HORIZ_DELTA_BYTE = $49
; HORIZ_DELTA_ADDR = $4a 

; set the screen to black background, black border to make scrolling easier
black_on_black
    lda     #8                      ; black background, black border
    sta     $900F                   ; set screen border color

; change all the black blocks to empty blocks to make scolling easier
horiz_block_switch_init
    ldy     #0                      ; zero out the y register (loop counter)
    lda     #$20                    ; load the purple block character

; set all black blocks to empty blocks so we can scroll easily
horiz_block_switch
    ldx     SCREEN_ADDR,y           ; load a byte of screen character data
    cpx     #$A0                    ; check if it's a purple block
    beq     horiz_bs_inc            ; jump to increment the loop counter and keep going
    sta     SCREEN_ADDR,y           ; store a blank character at this space
horiz_bs_inc 
    iny                             ; increment y
    bne     horiz_block_switch      ; if haven't looped over all 256 screen addresses, loop again

; calculate the screen delta for horizontal scrolling
; ASSUMES THAT Y IS ALREADY ZERO FROM LAST LOOP
horiz_delta_init
    lda     #$21                    ; set A to 21, the location just before LEVEL_DELTA
    sta     HORIZ_DELTA_ADDR        ; set HORIZ_DELTA_ADDR as the byte we're working on
    ldx     #0                      ; set X to 0, used to index into LEVEL_DELTA

; initialize the delta byte to 1.  We set it to 1 because rolling left 8 times will leave that 1 in
; the carry position, can we can check that carry bit to figure out if we've rotated 8 times.  If
; yes then we get the next delta_byte
horiz_delta_new_byte
    inc     HORIZ_DELTA_ADDR        ; get the next horizontal_delta_byte
    lda     #1                      ; load 1 into the A register
    sta     HORIZ_DELTA_BYTE        ; store 1 into the HORIZ_DELTA_BYTE (used to measure 8 rotations)

; calculate the screen delta
horiz_delta_calc
    lda     SCREEN_ADDR,y           ; load a byte of the screen address
    iny                             ; increment y to get the next screen byte
    beq     horiz_delta_exit        ; if y == 0, we've gone through the entire screen, stop the loop
    cmp     SCREEN_ADDR,y           ; compare SCREEN_ADDR,y to SCREEN_ADDR,y+1
    clc                             ; clear the carry in case it was set by the cmp
    beq     horiz_rol               ; if they are equal, no change between bytes, don't set carry, and rol a 0

; set the carry flag indicating a delta for this byte
horiz_set_delta
    sec                             ; set the carry flag (indicating delta true)

; rotate the delta byte
horiz_rol
    rol     HORIZ_DELTA_BYTE        ; rotate the horizontal delta byte (rol in 1 if carry set)

; check to see if we've checked 8 bytes worth of data.  Carry set means the 1 we initialized HORIZ_DELTA_BYTE
; to has been rotated 8 times and we need a new byte
horiz_byte_limit
    bcs     horiz_change_byte       ; if carry set, we've rotated through the entire byte (8 positions), get a new byte of delta
    jmp     horiz_delta_calc        ; otherwise jump back to check the next byte of delta

horiz_change_byte
    lda     HORIZ_DELTA_BYTE        ; load the delta byte into the A register
    sta     (HORIZ_DELTA_ADDR,x)    ; store the delta into level delta array
    jmp     horiz_delta_new_byte    ; setup the next byte of delta data

horiz_delta_exit
    rol     HORIZ_DELTA_BYTE        ; rotate the HORIZ_DELTA_BYTE for the last time

; we need to mask out the right most bit on the screen since we're scrolling in black screen
; TODO: THIS IS INCREDIBLY HACKY AND WON'T WORK FOR ANYTHING BUT THE TITLE SCREEN BUT I'M SO TIRED YOU GUYS
horiz_mask_end_init
    ldx     #31                     ; initialize X to 31 (loop backwards for easier branching)
    ldy     #$FE                    ; load 1111 1110 into the Y register for masking the byte

horiz_mask_end
    tya                             ; move the bitmask into the A register
    and     $22,x                   ; mask the 0th bit out of the pattern
    sta     $22,X                   ; store the masked bit back where it belongs!
    dex                             ; decrement x
    dex                             ; decrement x
    bpl     horiz_mask_end          ; if x still positive, we need to keep looping 