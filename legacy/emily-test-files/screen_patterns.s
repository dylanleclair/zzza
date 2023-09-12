; assembler deets
	processor 6502

; offsets of important mem
COLOR_ADDR = $9600
COLOR_ADDR_2 = (COLOR_ADDR + 16)

COLUMNS_ADDR = $9002
ROWS_ADDR = $9003

; TODO: these locations are all over the place
SCREEN = $1e00
PATTERNS = $30
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

	lda	#$20			; bit pattern 00100000, bits 1to6 = 16
	sta	ROWS_ADDR		; store in rows addr to set screen to 16 rows

; store row patterns for level creation
pattern_setup
	; TODO: tidy up patterns. originally I thought of these as 8 different 16-bit patterns
	; but that's silly. they should just be 16 different 8-bit patterns :P
	lda	#$55
	sta	PATTERNS
	lda	#$08
	sta	PATTERNS+1
	lda	#$30
	sta	PATTERNS+2
	lda	#$00
	sta	PATTERNS+3
	lda	#$8c
	sta	PATTERNS+4
	lda	#$20
	sta	PATTERNS+5
	lda	#$c1
	sta	PATTERNS+6
	lda	#$91
	sta	PATTERNS+7

	lda	#$83
	sta	PATTERNS+8
	lda	#$42
	sta	PATTERNS+9
	lda	#$08
	sta	PATTERNS+10
	lda	#$24
	sta	PATTERNS+11
	lda	#$04
	sta	PATTERNS+12
	lda	#$c4
	sta	PATTERNS+13
	lda	#$01
	sta	PATTERNS+14
	lda	#$03
	sta	PATTERNS+15

; main
main
	; display pattern 0
	lda	#$00
	sta	$00
	jsr	draw_pattern		; jump to 'draw_pattern' subroutine
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
	sta	COLOR_ADDR,y		; store it in COLOR_ADDR+y
	
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
	sta	SCREEN,y		; store the char in SCREEN_ADDR+y

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















