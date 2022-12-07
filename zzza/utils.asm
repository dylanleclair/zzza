; -----------------------------------------------------------------------------
; CHAR_COLOR_CHANGE
; - Sets all the characters on screen to a specific colour
;
; Arguments:
;   a: the colour code you want to set the characters to
;------------------------------------------------------------------------------
char_color_change
    ldx     #0
char_color_change_loop
    sta     COLOR_ADDR,x                ; set character to black
    inx                                 ; increment screen addr
    bne     char_color_change_loop      ; loop if screen isn't filled (0 = 256 positions filled)
    
    rts

; -----------------------------------------------------------------------------
; EMPTY_SCREEN
; - Sets the screen to all empty characters
;
; Arguments:
;   a: the empty character for the desired charset
;------------------------------------------------------------------------------
empty_screen 
    ldx     #0                          ; set x to 0 for screen loop

empty_screen_loop
    sta     SCREEN_ADDR,X               ; store the empty character
    inx                                 ; increment x
    bne     empty_screen_loop           ; keep looping if x hasn't overflowed

    jsr     init_hud                    ; set the HUD back to black

empty_hud
    ldx     #0                          ; set x to 0 for hud loop

empty_hud_loop
    sta     HUD_SCREEN_ADDR,x           ; store the empty character
    inx 
    bne     empty_hud_loop

    rts

; -----------------------------------------------------------------------------
; CUSTOM_CHARSET
; - changes between the default and custom character set
;------------------------------------------------------------------------------
set_custom_charset
    lda     #$fc         ; set location of charset to 7168 ($1c00)
    sta     CHARSET_CTRL ; store in register controlling base charset
    rts

; -----------------------------------------------------------------------------
; DEFAULT_CHARSET
; - changes between the default and custom character set
;------------------------------------------------------------------------------
set_default_charset
    lda     #$f0         ; set location of charset to 7168 ($1c00)
    sta     CHARSET_CTRL ; store in register controlling base charset
    rts

;------------------------------------------------------------------------------
; SUBROUTINE: GET_DATA_INDEX
; - returns in Y reg the LEVEL_DATA index associated with the player's current position
; - comes with a default???? parameter???? we live in the future 
;   - if you expect to use the player's coors, use get_data_index
;   - else if you want to set your own (eg for the falling block), use sneeky
;------------------------------------------------------------------------------
get_data_index
    ldx     NEW_X_COOR
    lda     NEW_Y_COOR                  ; get player's y coord
    
get_data_index_sneeky                   ; used for calls that set their own x,y
    clc
    asl                                 ; multiply by 2 to get the index into LEVEL_DATA
    tay                                 ; put this offset into y

    cpx     #$08                        ; check if player's x coord is less than 8
    bmi     get_data_index_exit         ; if player's x < 8, you're on lhs. don't inc y
    iny                                 ; else you're on rhs. inc y.

get_data_index_exit
    rts

;------------------------------------------------------------------------------
; SUBROUTINE: GET_SCREEN_OFFSET
; - returns in x register the index to draw on screen given a particular set of x,y
; - expects X to already have the desired y coordinate
;------------------------------------------------------------------------------
get_block_screen_offset
    lda     y_lookup,x 
    clc
    adc     NEW_BLOCK_X
    tax
    rts

;------------------------------------------------------------------------------
; SUBROUTINE: STRING_WRITER
; - displays a given string on screen
; - expects that the character set is in DEFAULT mode
; - uses indirect addressing, expects a pointer to the first char of the string 
;   to be in STRING_LOCATION
; - expects the desired screen offset to come in on the a register
; - uses 0x00 as a null terminator because we all need a bit more C in our lives
;------------------------------------------------------------------------------
string_writer
    ldy     #0                          ; initialize index into string
string_writer_loop
    lda     (STRING_LOCATION),y         ; grab a byte of the string         
    cmp     #0                          ; check for null terminator
    beq     level_display               ; if terminator, stop writing
    sta     SCREEN_ADDR,x               ; else, store in desired screen location
    lda     #4                          ; set colour to purple TODO: CAN WE ERASE THESE?
    sta     COLOR_ADDR,x                ; and store in colour mem TODO: CAN WE ERASE THESE?

    iny                                 ; set up y to grab next piece of string
    inx                                 ; set up x to write to new location
    jmp     string_writer_loop          ; and go again

level_display
    ; check if level needs to be displayed for "ORDER UP" screen

    lda     STRING_LOCATION             ; check if STRING_LOCATION = #$b7 (ORDER UP SCREEN)
    cmp     #$b7                        ; check if ORDER UP SCREEN BEING LOADED
    bne     string_writer_delay         ; if not, skip lvl display

    ; set the screen to purple for this part
    lda     #4                          ; purple
    jsr     char_color_change           ; set the screen to purple chars

    ldx     CURRENT_LEVEL               ; load the current level into Y register
    inx                                 ; increment it b/c we index levels at 0 (not 1 - BECAUSE WE LIVE IN A SOCIETY!)
    txa                                 ; put x back into A
    cmp     #10                         ; check if the 10s digit needs to be set
    bmi     single_digit                ; if value is minus, only the 1s digit is set

    ldx     #49                         ; char value for 1
    stx     $1e96                       ; store in the 10s place
    sec                                 ; set carry for subtraction
    sbc     #10                         ; subtract 10 to setup for dealing with 1s position

single_digit
    clc
    adc     #48                         ; 48 is the char 0, we add it to our desired value to get our character
    sta     $1e97                       ; store it on the screen

; delay for the displayed strings
string_writer_delay                     ; give time for string to display on screen
    ldy     #$b4                        ; 3 second delay
    jsr     delay
   
    dey                                 ; prevent off-by-one caused by loop structure
    dex

string_clear                            ; clear the space on screen that we just wrote to
    lda     #96                         ; char for default empty block
    sta     SCREEN_ADDR,x               ; store on screen
    dex                                 ; keep track of where we are onscreen
    dey                                 ; iterate backward thru y until it's back to 0
    bne     string_clear                ; while y != 0, keep clearing

string_writer_exit
    rts

;------------------------------------------------------------------------------
; SUBROUTINE: GET_KEY_INPUT
; - sets up a kernal call to GETTIN to grab a key from the keyboard buffer
; - WE CALCULATED THAT DOING IT THIS WAY SAVES US 2 WHOLE BYTES!  WAHOO!
;
;   RETURNS
;   - A: value of key pressed
;------------------------------------------------------------------------------
get_key_input
    ldx     #00                         ; set x to 0 for GETTIN kernal call
    jsr     GETIN                       ; get 1 bytes from keyboard buffer
    rts