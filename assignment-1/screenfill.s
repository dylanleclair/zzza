	processor 6502

	org	$1001
stub		; BASIC stub that transfers control to machine language
	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0

stubend
	dc.w	0

start				; start of assembly instructions

; $1e00 (7680 in binary) is the location of the screen display
; $9600 (38400 in binary) is the location of the colour control table

	; set low-order bytes
	lda 	#$00		; accumulator = 0x00
	sta 	$01		; put accumulator value (0x00) into zero-page location $01 (1st base index)
	sta 	$10		; put accumulator value (0x00) into zero-page location $10 (2nd base index)
	sta	$fe		; put accumulator value (0x00) into zero-page location $fe (3rd base index)
	sta	$a0		; put accumulator value (0x00) into zero-page location $a0 (4th base index)

	; set high-order bytes
	lda	#$1e		; accumulator = 0x1e
	sta	$02		; put accumulator value (0x1e) into zero-page location $0002

	lda	#$1f		; accumulator = 0x1f
	sta	$11		; put accumulator value (0x1f) into zero-page location $0011

	lda	#$96		; accumulator = 0x96
	sta	$ff		; put accumulator value (0x96) into memory location $00ff

	lda	#$97		; accumulator = 0x97
	sta	$a1		; put accumulator value (0x97) into memory location $00a1
	
	; put a particular character on the screen
	ldy	#$00		; initialize loop counter to 0
fill
	lda	#$53		; accumulator = 0x53 (heart)
	sta	($01),y		; store accumulator value (0x53) at location (0x1e00+y) 
	sta	($10),y		; store accumulator value (0x53) at location (0x1f00+y)

	; set the colour
	lda	#$02		; accumulator = 0x02 (red)
	sta	($fe),y		; store accumulator value (0x02) at location (0x9600+y)
	sta	($a0),y		; store accumulator value (0x02) at location (0x9700+y)

	iny			; increment index (y) by 1
	bne	fill		; branch back to top of loop

;	rts			; return to calling code
