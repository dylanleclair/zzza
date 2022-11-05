; -----------------------------------------------------------------------------
; SETUP: INIT_CHARSET
; - activates custom charset starting at 1c00
; - copies desired characters from ROM into proper memory for easy addressing
; -----------------------------------------------------------------------------

    ; change the location of the charset
    lda     #255 ; set location of charset to 7168 ($1c00)
    sta     CHARSET_CTRL ; store in register controlling base charset 

    ; copy the 8 character bytes at given address to the custom character set memory (CUSTOM_CHAR_ADDR)
    ldx     #0
copy_char

    lda     CUSTOM_CHAR_0,x
    sta     CUSTOM_CHAR_ADDR_0,x

    lda     CUSTOM_CHAR_1,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_1,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_2,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_2,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_3,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_3,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_4,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_4,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_5,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_5,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_6,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_6,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_7,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_7,x        ; store that byte in our custom location

    inx

copychar_test
    cpx     #8                          ; we have 8 bytes to load for each char 
    bne     copy_char