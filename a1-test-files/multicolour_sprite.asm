; ----------------------------------
;
; program to display the eva-right sprite on screen
; mostly a test to work with multicolor mode
;
; ----------------------------------


; KERNAL [sic] routines
GETIN = $ffe4				; gets one byte of input from keyboard
RDTIM = $ffde				; gets value from system clock

; Memory macros
SCREEN_COLOR = $9600		; beginning of screen colour data
SCREEN_MEM = $1e00			; beginning of default screen memory
CUSTOM_CHAR_ADDR = $1c00    ; beginning of custom charset location

COLUMNS_ADDR = $9002		; memory that determines number of columns displayed
ROWS_ADDR = $9003			; memory that determines number of rows displayed
CHARSET_CTRL = $9005        ; memory that stores location where the charset can be found
AUX_COLOR_ADDR = $900e      ; memory for auxilliary 4th colour. NOTE: only bits 4-7

; Offsets in Zero-page
SCREEN = $00				; bytes $00 and $01 used to store screen addr
COLOR = $02					; bytes $02 and $03 used to store colour addr

; Value macros
BLACK = #$00
RED = #$02
FULL_BLOCK = #224
EMPTY_SPACE = #96

	processor 6502

	org	$1001

	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0

stubend
	dc.w	0

; start of assembly
start

; change the location of the charset
    lda     #255            ; this is the value needed to set the location of the char set to $1c00
    sta     CHARSET_CTRL    ; store in charset control address

; load custom character into charset location
; this is the eva-right sprite
    lda     #%11010111
    sta     CUSTOM_CHAR_ADDR
    lda     #%11010011
    sta     CUSTOM_CHAR_ADDR+1
    lda     #%01000011
    sta     CUSTOM_CHAR_ADDR+2
    lda     #%00101011
    sta     CUSTOM_CHAR_ADDR+3
    lda     #%11010100
    sta     CUSTOM_CHAR_ADDR+4
    lda     #%10111011
    sta     CUSTOM_CHAR_ADDR+5
    lda     #%00000000
    sta     CUSTOM_CHAR_ADDR+6
    lda     #%11011101
    sta     CUSTOM_CHAR_ADDR+7

; set the auxilliary colour code. aux colour is in the high 4 bits of the address
    lda     #$0f            ; bitmask out the top 4 bits
    and     AUX_COLOR_ADDR  ; aux colour addr AND accumulator to zero out the top 4
    sta     AUX_COLOR_ADDR  ; put the result back in the aux colour location

    lda     #$01            ; colour code for light purple in hi 4 bits, nothing in lo 4
    ora     AUX_COLOR_ADDR  ; aux colour addr OR accumulator to put our value in
    sta     AUX_COLOR_ADDR  ; put the result back in the aux colour location


; draw our char to the screen
; i'm not 100% on why this needs to be done in a loop. i assume that it's because of all the empty space
; in character memory after CUSTOM_CHAR_ADDR??
draw
    lda     #$0a
    sta     SCREEN_COLOR    ; store in location for colour

    lda     #$00            ; the first char in the charset
    sta     SCREEN_MEM      ; store on screen

    jmp     draw            ; loop forever for some reason

    rts
