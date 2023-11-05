; KERNAL [sic] routines
GETIN = $ffe4				; gets one byte of input from keyboard
RDTIM = $ffde				; gets value from system clock

; Memory macros
SCREEN_COLOR = $9600		; beginning of screen colour data
SCREEN_MEM = $1e00			; beginning of default screen memory

COLUMNS_ADDR = $9002		; memory that determines number of columns displayed
ROWS_ADDR = $9003			; memory that determines number of rows displayed


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

start

; setup memory offsets
offsets
	lda 	#$00			; lo-order bytes for screen and colour addrs
	sta 	SCREEN
	sta 	COLOR

	lda 	#$1e			; hi-order byte for screen
	sta 	SCREEN+1
	
	lda		#$96			; hi-order byte for colour
	sta 	COLOR+1

; setup screen to be 16x16 and centre the image
screen_dim

    lda     #$90                    ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR            ; store in columns addr to set screen to 16 cols

    lda     #$20                    ; bit pattern 00101000, bits 1to6 = 16
    sta     ROWS_ADDR               ; store in rows addr to set screen to 16 rows

    lda     #$09                    ; i don't know what i'm doing
    sta     $9000                   ; horizontal screen centering

    lda     #$20                    ; i don't know why this value works but it does
	sta     $9001                   ; vertical screen centering

; mysterious timer function
timer
;     lda #01							; call update every 1 * 10th of a second
;     cmp $10 						; place in memory where 10ths of a second are counted (zero page in this instance)
;     beq animate						; function to call every (acc) 10ths of a second
;     lda $a2 						; load lower end of clock pulsing @ 1/1th of a second
;     cmp $a2 						; as soon as clock value changes (1/th of a second passes...)
;     bne timercount 					; increment counter
;     jmp timer 						; otherwise, keep waiting for clock to update
    
; timercount
;     inc $10
;     jmp timer


	ldy 	#$00				; initialize loop counter/offset counter
	lda 	#$10				; we also need to keep track of an index that is 16 ahead of y (ie 1 row down from y)
	sta 	$11					; only y can do the indirect indexing that we want, so store y+16 on the 0 page

animate

; frame 1, "base frame" responsible for getting offsets lined up properly and drawing initial state
f1
	; clear tile and the tile beneath it
	; print black block to screen
	lda		#$01				; colour code for black
	sta		(COLOR),y			; store in colour mem for block

	lda		#$e0				; char code for full fill
	sta		(SCREEN),y			; store on screen

	; store a white block one row down, too
	tya 						; shuffle old index to a
	tax 						; and then into x because why not
	ldy 	$11					; get the stored index for y+16

	lda		#$01				; colour code for white
	sta 	(COLOR),y 			; store one block below original y

	lda		#$e0				; char code for full fill
	sta		(SCREEN),y			; store one block below original y




; frame 2, makes no changes to offsets, just advances animation
f2



; 'frame' 3, clear old data from the screen
f3






	; 1. clear tile from current offset
	; 2. increment offset
	; 3. draw tile in new offset
	; 4. wait

clear_block
	; print white block to screen
	lda	#$01				; colour code for white
	sta	(COLOR),y			; store in colour mem for block

	lda	#$e0				; char code for full fill
	sta	(SCREEN),y			; store on screen

inc_y
	; increase y by 16 so that the next loop will draw block one row down
	tya							; shuffle the loop counter value into accumulator
	clc							; CLEAR THE GODDAMNED CARRY BIT
	adc		#$10				; add 16 to accumulator value
	sta 	$05					; store the new counter value on 0-page
	tay							; put the increased value back into the loop counter

	beq 	exit				; when y overflows, exit loop

draw_block
	; print black block to screen
	lda		#$00				; colour code for black
	sta		(COLOR),y			; store in colour memory for block

	lda		#224				; char code for full fill
	sta		(SCREEN),y			; store on screen
	
	; jump back to the timer
	lda 	#$00			; load 0 into accumulator
	sta 	$10				; reset the timer's counter
	jmp 	timer			; jump back to the timer function to waste some time before next loop


exit
	rts						; return to calling code




; update
    
;     lda #0
;     sta $0001

;     ; x and y are offsets of respective character

;     ; we need to store them
;     stx $0004
;     sty $0005

;     txa ; set character offset to x
;     ldy $0002
;     sta $1e00,y
    
;     ldy $0005
    
;     tya ; set character offset to y
;     ldx $0002
;     sta $1e01,x

;     ldx $0004

;     inx
;     dey
    
;     ; update framecount
;     inc $0000
;     lda #4
;     cmp $0000
;     beq reset   

;     jmp timer
