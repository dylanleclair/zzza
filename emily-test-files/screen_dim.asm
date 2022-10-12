; offsets of important mem
COLUMNS_ADDR = $9002
ROWS_ADDR = $9003

	processor 6502

	org	$1001

	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0

stubend
	dc.w	0

; program to change screen dimensions to 16x16, and center it on the background
start
        lda     #$90                    ; bit pattern 10010000, lower 6 bits = 16
        sta     COLUMNS_ADDR            ; store in columns addr to set screen to 16 cols

        lda     #$20                    ; bit pattern 00101000, bits 1to6 = 16
        sta     ROWS_ADDR               ; store in rows addr to set screen to 16 rows

        lda     #$09                    ; i don't know what i'm doing
        sta     $9000                   ; horizontal screen centering

        lda     #$20                    ; i don't know why this value works but it does
	sta     $9001                   ; vertical screen centering

	rts
