; ----------------------------------
;
; program to fill the screen with patterns of black and white blocks
; the block patterns are 8*1 meta-tiles that are stored as a bit representation,
; the screen fill is created by displaying 32 of these 8-bit tiles
;
; ----------------------------------

; assembler deets
	processor 6502

; offsets of important mem
COLUMNS_ADDR = $9002
ROWS_ADDR = $9003

; TODO: these locations are all over the place
SCREEN = $20
COLOR = $30
PATTERNS = $40
LEVEL = (PATTERNS+16)

; stub to hand over control to machine language instructions
	org $1001

	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0

stubend
	dc.w	0

; start of assembly
start

; setup screen dimensions
screen_dim
	lda	#$90			; bit pattern 10010000, lower 6 bits = 16
	sta	COLUMNS_ADDR		; store in columns addr to set screen to 16 cols

	lda	#$20			; bit pattern 00101000, bits 1to6 = 16
	sta	ROWS_ADDR		; store in rows addr to set screen to 16 rows

	lda	#$09			; i don't know what i'm doing
	sta	$9000			; horizontal screen centering
	
	lda	#$20			; i don't know why this value works but it does
	sta	$9001			; vertical screen centering


; store row patterns for level creation
pattern_setup
	; TODO: tidy up patterns. originally I thought of these as 8 different 16-bit patterns
	; but that's silly. they should just be 16 different 8-bit patterns :P
	lda	#$55
	sta	PATTERNS
	lda	#$e1
	sta	PATTERNS+1
	lda	#$33
	sta	PATTERNS+2
	lda	#$00
	sta	PATTERNS+3
	lda	#$8c
	sta	PATTERNS+4
	lda	#$1e
	sta	PATTERNS+5
	lda	#$c1
	sta	PATTERNS+6
	lda	#$99
	sta	PATTERNS+7

	lda	#$83
	sta	PATTERNS+8
	lda	#$42
	sta	PATTERNS+9
	lda	#$08
	sta	PATTERNS+10
	lda	#$24
	sta	PATTERNS+11
	lda	#$cc
	sta	PATTERNS+12
	lda	#$c4
	sta	PATTERNS+13
	lda	#$f1
	sta	PATTERNS+14
	lda	#$dc
	sta	PATTERNS+15

; store list of patterns that will make up the level
level_setup
	lda	#$00
	sta	LEVEL
	sta	LEVEL+25
	lda	#$01
	sta	LEVEL+1
	sta	LEVEL+16
	sta	LEVEL+30
	lda	#$02
	sta	LEVEL+2
	sta	LEVEL+31
	lda	#$03
	sta	LEVEL+3
	lda	#$04
	sta	LEVEL+4
	sta	LEVEL+21
	sta	LEVEL+22
	sta	LEVEL+26
	sta	LEVEL+29
	lda	#$05
	sta	LEVEL+5
	lda	#$06
	sta	LEVEL+6
	sta	LEVEL+18
	lda	#$07
	sta	LEVEL+7
	sta	LEVEL+17
	sta	LEVEL+28
	lda	#$08
	sta	LEVEL+8
	lda	#$09
	sta	LEVEL+9
	sta	LEVEL+19
	sta	LEVEL+23
	lda	#$0a
	sta	LEVEL+10
	lda	#$0b
	sta	LEVEL+11
	lda	#$0c
	sta	LEVEL+12
	lda	#$0d
	sta	LEVEL+13
	lda	#$0e
	sta	LEVEL+14
	sta	LEVEL+23
	lda	#$0f
	sta	LEVEL+15
	sta	LEVEL+20
; main
main
	jsr	draw_screen		; jump to 'draw_screen' subroutine
	rts				; return to calling code

; subroutine used to fill the screen with patterns. 
draw_screen
	; initialize location of screen and color memory
	lda	#$00			; low-order byte
	sta	SCREEN			; store in 0-page
	sta	COLOR			; store in 0-page

	lda	#$1e			; hi-order screen byte
	sta	SCREEN+1		; store in 0-page
	lda	#$96			; hi-order color
	sta	COLOR+1

	; counter setup
	ldx	#$00			; x will be used as loop counter
	ldy	#$00			; use y to keep track of screen offsets

screen_loop

	; need to calculate correct chunk of screen to write to:
	; each call to 'draw_pattern' will fill 8 bytes, so we need to move the screen
	; memory base location over by 8 each time if we want to draw to a brand-new section
	txa				; move loop counter value into accumulator
	asl				; shift accumulator value left by 1 (multiply by 2)
	asl				; shift accumulator value left by 1 (multiply by 2)
	asl				; shift accumulator value left by 1 (multiply by 2)
	sta	SCREEN			; store this in the 0-page location for screen offsets
	sta	COLOR			; also store in the 0-page location for color

	; set up subroutine call
	lda	LEVEL,x			; get the pattern listed at LEVEL+x
	sta	$00			; store in $00 for draw_pattern to use
	jsr	draw_pattern		; jump to 'draw_pattern' subroutine

	; loop stuff
	inx				; increment y
	cpx	#$20			; check loop counter value
	bne	screen_loop		; while y < 16

	rts				; return to calling code

; subroutine used to take a pattern and display it on screen
; expects the intended pattern's number to be available in $00,
; and the correct screen base address to be stored in SCREEN
; callee-saved.
draw_pattern
	sta	$10			; store a
	stx	$11			; store x
	sty	$12			; store y

	; loop setup, get counters and offsets ready
	ldx	$00			; we will find the pattern using PATTERN+x offset
	ldy	#$00			; y will be loop counter, initialize to 0	
	clc				; carry bit will be needed for rotations, so clear it now

	; extract the pattern using bitwise operations, then draw it to screen
	; DON'T MESS WITH CARRY BIT INSIDE HERE
pattern_loop
	lda	#$00			; colour code for black
	sta	(COLOR),y		; store it in COLOR_ADDR+y
	
	; 1. AND with 0x80 to check if highest bit is a 1
	lda	#$80			; 0x80 has 1 in hi bit and 0 elsewhere
	and	PATTERNS,x		; AND the pattern with 0x80 to check hi bit value
	cmp	#$80			; if result is still 0x80, bit was a 1

	bne	space			; if a != 0x80, bit was a 0, jump to 'space'

	; 2. if 1, load up a full fill
fill
	lda	#$e0			; char code for a full fill
	jmp	draw_and_shift		; skip over 'space'

	; 3. if 0, load up an empty space
space
	lda	#$60			; char code for empty space

	; 4. rotate pattern one bit to the left
draw_and_shift
	sta	(SCREEN),y		; store the char in SCREEN_ADDR+y

	rol	PATTERNS,x		; rotate the pattern left by 1 bit

	; 5. rinse and repeat for 8 bits
	iny				; increment y for next loop
	cpy	#$08			; compare loop counter to 8
	bne	pattern_loop		; if x < 8, loop

	; by the end of the loop, pattern should be back in its proper place

	lda	$10			; restore a
	ldx	$11			; restore x
	ldy	$12			; restore y

	; return to calling code
	rts















