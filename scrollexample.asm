; -----------------------------------------------------------------------------
;
; Program to test scrolling level on the screen
;
; -----------------------------------------------------------------------------

; Memory location macros
DELAY_ADDR = $0001
FRAME_COUNT_ADDR = $0002
BYTE_COUNT_ADDR = $0003

LEVEL_OFF_ADDR = $0004
DELTA_ADDR = $0005

LEVEL_START = $0020
LEVEL_START_PLUS_ONE = $0021


CENTERING_ADDR = $9001          ; stores the screen centering values
COLUMNS_ADDR = $9002            ; stores the number of columns on screen
ROWS_ADDR = $9003               ; stores the number of rows on screen

    processor 6502
    org $1001
    
    dc.w stubend ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4109", 0
stubend
    dc.w 0

; change the screen size to 16x16
screen_dim
    lda     #$90                ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR        ; store in columns addr to set screen to 16 cols

    lda     #$20                ; bit pattern 00101000, bits 1to6 = 16
    sta     ROWS_ADDR           ; store in rows addr to set screen to 16 rows

    lda     #$09                ; i don't know what i'm doing
    sta     $9000               ; horizontal screen centering

    lda     #$20                ; i don't know why this value works but it does
	sta     CENTERING_ADDR      ; vertical screen centering


; prepare to init level
    ldx #32                     ; 32 is max loop counter
    stx $0010                   ; store in 0 page for later use

; initialize $0010 to ($0010 + 32) with level data
; this gives us exactly 1 screen worth of level (that we can repeat)
initlevel
    dex                         ; iterate backward from 32 to 0
    sta     LEVEL_START,x             ; store on 0 page
    sta     LEVEL_START_PLUS_ONE,x             ; store on 0 page, off by 1 (screen will be duplicated horizontally)
    beq     initlevel           ; until loop counter is 0, repeat

; start the scrolling code

    lda     #0                  ; accumulator=0
    sta     DELAY_ADDR          ; this is used to set the timer delay

    ; initialize loop counts to 0
    sta     FRAME_COUNT_ADDR
    sta     BYTE_COUNT_ADDR

; TODO: replace this with a different timer
timer
    lda     #1                  ; call update every 1 * 10th of a second
    cmp     DELAY_ADDR          ; place in memory where 10ths of a second are counted (zero page in this instance)
    beq     gameloop            ; function to call every (acc) 10ths of a second
    lda     $00A2               ; load lower end of clock pulsing @ 1/1th of a second
    cmp     $00A2               ; as soon as clock value changes (1/th of a second passes...)
    bne     timercount          ; increment counter
    jmp     timer               ; otherwise, keep waiting for clock to update

timercount
    inc     DELAY_ADDR
    jmp     timer


; macros for the values


; main game loop
gameloop 
    ; get current state

    ; calculate transitions
    
    ; update state
    
    ; branch to delay between frames
    
    lda     FRAME_COUNT_ADDR    ; load frame count into acc
    cmp     #3                  ; compare it against four
    beq     animate 
    ; jump to top of render loop
    jmp     timer
    
    jmp     gameloop

    ; delay

; update all bytes of level on screen by 4 frames (full animation)
animate
    lda     FRAME_COUNT_ADDR    ; load loop counter into acc
    inc     FRAME_COUNT_ADDR    ; increment loop counter for next time
    cmp     #3                  ; if 4 bytes iterated over
    beq     gameloop            ; animation is complete, start over
    
; updates all bytes of level on screen by one frame
animate_byte

    ; prepare SCREEN param for pattern_draw
    lda BYTE_COUNT_ADDR
    asl
    asl
    asl
    
    ; prepare DELTA param for pattern_draw
    ldx LEVEL_OFF_ADDR          ; load offset from start of level memory
    lda LEVEL_START,x           ; the level byte at level offset
    inx                         ; increment offset to the next level byte
    inx                         ; x is now level_off + 2

    eor LEVEL_START,x           ; XOR level byte and the byte under it
    sta DELTA_ADDR

    jsr     pattern_draw        ; update a single byte on screen by 1 frame
    
    lda     BYTE_COUNT_ADDR     ; load byte count into acc
    inc     BYTE_COUNT_ADDR     ; increment loop count for next time
    ; if
    cmp     #32                 ; all 32 screen bytes re-rendered
    bne     animate_byte        ; if not all rendered, repeat loop
    ; else
    lda     #0
    sta     BYTE_COUNT_ADDR     ; reset byte counter to 0
   
    jmp     animate             ; render next frame of animation


; subroutine that updates one 'tile' (8*1 chunk of screen)
; parameters:
;   - SCREEN_ADDR: the location in memory in which to start drawing the tile data
;   - DELTA_ADDR: a byte representing which screen locations need to change and which should stay the same
pattern_draw
    ldx     #0                  ; initialize loop counter
    ldy     #0                  ; initialize loop counter

; this loop runs for 8 iterations, filling in each bit of an entire byte
pattern_loop 

	; 1. AND with 0x80 to check if highest bit is a 1
	lda	    #$80			    ; 0x80 has 1 in hi bit and 0 elsewhere
	and	    DELTA_ADDR   		; AND the byte with 0x80 to check hi bit value

	bne	    shift			        ; if a != 0x80, bit was a 0, just don't change anything

	; 2. test bit is 1
high
    lda     (SCREEN_ADDR),y     ; go to SCREEN+y and get the value stored there
    cmp     #8                  ; we only have 8 char tiles, so loop back around if we hit the top
    bne     advance_frame       ; ASSEMBLY CONDITIONALS

    lda     #0                  ; reset char to 0 if it was 8

    jmp     shift              ; if/else statement: don't execute the stuff in 'advance_frame'

advance_frame
    adc     #1                  ; add 1 to accumulator to advance the frame

	; 4. rotate pattern one bit to the left
shift

	rol	    DELTA_ADDR   		; rotate the pattern left by 1 bit

	; 5. rinse and repeat for 8 bits
	iny				            ; increment y for next loop
	cpy	#$08			        ; compare loop counter to 8
	bne	pattern_loop		    ; if x < 8, loop

    rts                         ; return to calling code