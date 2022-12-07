; -----------------------------------------------------------------------------
; DRAW_TITLE_SCREEN
; - draws the title screen raw data to the screen
;------------------------------------------------------------------------------
draw_title_screen
; SET SCREEN BORDER TO BLACK
    lda     #8                           ; white background, black border
    sta     $900F                        ; set screen border color

    ; change the location of the charset
    lda     #$f0                        ; set location of charset to default
    sta     CHARSET_CTRL                ; store in register controlling base charset

    lda     #4                          ; color code for purple
    jsr     char_color_change           ; set screen characters to purple

    lda     #$10                        ; SCREEN_LOAD: load high byte of title screen data
    sta     DECOMPRESS_HIGH_BYTE
    lda     #$d0                        ; SCREEN_LOAD: low byte of the title screen data 
    sta     DECOMPRESS_LOW_BYTE         
    jsr     zx02_decompress             ; decompress the screen

title_delay1
    ldy     #$78                        ; desired wait time (78 = 2 seconds)
    jsr     delay

title_year_init
    ldx     #0                          ; zero out X (counter of position in string)
    jsr     clear_bottom_line           ; clear the bottom line

title_year_draw
    lda     title_year,x                ; load the character
    beq     title_delay2                ; if character is 0, null terminator, exit loop
    sta     $1EF6,x                     ; store the character on the screen
    inx                                 ; increment x to the next character
    jmp     title_year_draw

title_delay2
    ldy     #$78                        ; desired wait time (78 = 2 seconds)
    jsr     delay

    jsr     clear_bottom_line           ; clear the year off the screen

draw_prompt_init
    ldy     #0                          ; number of loops to draw "PRESS ANY KEY"

draw_prompt
    lda     press_any_key,y             ; load in the character to be displayed
    sta     $1EF1,y                     ; $1ED1 is the start of where we want to draw PRESS_ANY_KEY
    iny                                 ; get the next character
    cpy     #13                         ; check if we're at the end of the loop
    bne     draw_prompt                 ; draw_prompt

any_key_loop
    ldx     #00                         ; set x to 0 for GETTIN kernal call
    jsr     GETIN                       ; get 1 bytes from keyboard buffer

    cmp     #$00                        ; 00 = no key pressed
    beq     any_key_loop                ; keep waiting for a key to be pressed

    rts

; -----------------------------------------------------------------------------
; CLEAR_BOTTOM_LINE
; - clears the bottom line of the title screen
;------------------------------------------------------------------------------
clear_bottom_line
    ldx     #15                     ; set x to 16
    lda     #96                     ; set A to the empty block
clear_bottom_line_loop
    sta     $1ef0,x                 ; store empty character at bottom line
    dex                             ; decrement x
    bne     clear_bottom_line_loop  ; if x != 0, keep looping
    rts

;------------------------------------------------------------------------------
; DRAW_ROBINI
; - draw a base robini with angee eyebrows
;------------------------------------------------------------------------------
draw_robini 
    lda     #0                          ; load black color to set screen to black
    jsr     char_color_change           ; set screen to black (to cover the charset change)
    jsr     set_default_charset         ; set the charset to default for game over screen
    jsr     init_hud                    ; set the hud to empty
    lda     #$56                        ; SCREEN_LOAD: set lower byte for death screen load
    sta     DECOMPRESS_LOW_BYTE         
    lda     #$11                        ; SCREEN_LOAD: set high byyte for death screen load
    sta     DECOMPRESS_HIGH_BYTE
    jsr     zx02_decompress             ; draw the game over screen
    lda     #4                          ; load purple color
    jsr     char_color_change           ; set screen to purple
    rts