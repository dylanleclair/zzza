; KERNAL [sic] routines
GETIN = $ffe4				; gets one byte of input from keyboard

; Memory macros
SCREEN_COLOR = $9600			; beginning of screen colour data
SCREEN_MEM = $1e00			; beginning of default screen memory

; Value macros
RED = #$02

; setup to hand control from basic over to machine language
	processor 6502

	org	$1001

	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0

stubend
	dc.w	0

; program that displays user input on the screen
start
	; setup
	lda	#$02			; load colour code into accumulator
	sta	SCREEN_COLOR		; store in colour data for 1st block of scree

display
	jsr	GETIN			; jump to GETIN kernal routine

	cmp	#$00			; if a=00, indicates empty buffer
	beq	start			; if the buffer is empty, wait for more input

	cmp	#$0d			; 0x0d is a carriage return, exit
	beq	exit			; allows user to exit the program

	sta	SCREEN_MEM		; display the received character on screen

	jmp	display			; loop forever

exit
	rts				; return to calling code
