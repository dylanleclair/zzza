; -----------------------------------------------------------------------------
; SUBROUTINE: BEGIN_LEVEL
; - detects when the game is on a level multiple of 4 and updates values for
;   difficulty, level strip offsets (for generating levels), speed
; -----------------------------------------------------------------------------
begin_level
    lda     CURRENT_LEVEL               ; load the current level
    beq     level_changes_exit          ; level is zero, don't change anything
    and     #3                          ; mask out all but the bottom 2 bits
    bne     level_changes_exit          ; if not 0, not a multiple of 4, exit

    ; update border colour
    inc     $900F                       ; change the border to the next color
    
    ; increase speed and make level longer
    dec     GAME_SPEED                  ; increase the speed of the game
    inc     LEVEL_LENGTH                ; increase the length of the level
    inc     LEVEL_LENGTH                ; increase the length of the level

    ; change bit patterns of strips
    ldy     #2

strip_bit_bump

    lda     #0
    sta     LOOP_CTR
strip_bit_bump_loop
    jsr     lfsr
    lda     LFSR_ADDR                   ; grab the random value out of the lfsr
    and     #%00001111                  ; bitmask out top 4 bits, leaving 0<=a<16
    tax
    
    jsr     lfsr
    lda     LFSR_ADDR
    and     #%00001111
    tay

    lda     STRIPS,y
    sta     STRIPS,x

strip_bit_bump_test
    inc     LOOP_CTR
    lda     LOOP_CTR
    cmp     #4
    bne     strip_bit_bump_loop 

    ; tax                                 ; flip to x to use as index
    ; lda     #%01000101                  ; extra bits to turn on
    ; ora     STRIPS,x                    ; add those bits to the pattern
    ; sta     STRIPS,x
    ; dey
    ; bne     strip_bit_bump

    rts

restart_level
; -----------------------------------------------------------------------------
; SUBROUTINE: LEVEL_INIT
; - sets up all values that need to be initialized on a per-level basis 
; -----------------------------------------------------------------------------
level_init
    ldx     CURRENT_LEVEL               ; get the current level
    ; seed the lfsr 
    lda     random_seeds,x              ; get random_seeds[x]
    sta     LFSR_ADDR


    ; reset counters and such
    lda     #00                         ; initialize lots of stuff to 0
    sta     END_LEVEL_INIT              ; set END_LEVEL_INIT to FALSE
    sta     ANIMATION_FRAME             ; set the animation frame to 0                
    sta     PROGRESS_BAR                ; set progress bar to empty
    sta     WORKING_SCREEN              ; lo byte of screen memory should start at 0x00
    sta     LINES_CLEARED
    sta     LEVEL_CLEARED
    sta     IS_GROUNDED

    ; reset stuff associated with ending the level
    lda     #4                         ; index into the end level pattern data
    sta     END_PATTERN_INDEX           ; set the index into end level pattern to 0

    ; reset coordinates
    lda     #$7
    sta     X_COOR                      ; set the x coordinate to 7
    sta     NEW_X_COOR                  ; set the x coordinate to 7
    
    lda     #$1
    sta     Y_COOR                      ; set the y coordinate to 1
    sta     NEW_Y_COOR                  ; set the y coordinate to 1

    lda     #$ff                        ; impossible value for x and y
    sta     BLOCK_X_COOR                ; store in block x
    sta     BLOCK_Y_COOR                ; store in block y
    sta     NEW_BLOCK_X                 ; store in block x
    sta     NEW_BLOCK_Y                 ; store in block y

    ; reset hi-res counters
    lda     #0
    sta     MOVE_DIR_X
    sta     FRAMES_SINCE_MOVE

    lda     #1
    sta     MOVE_DIR_Y

    lda     #1                          ; colour for white
    jsr     init_hud 

    ; draw lives onto HUD
    jsr     draw_lives

    ; initialize data
    jsr     init_level_data              ; ensure that there's valid level data ready to go
    jsr     backup_scrolling             ; make sure hi-res is backed up properly


level_changes_exit

; -----------------------------------------------------------------------------
; SUBROUTINE: INIT_LEVEL_DATA
; - initializes the values of LEVEL_DATA with whitespace
; - also initializes the onscreen characters to all be zeroed out
; - this subroutine can be optimized quite a bit, but it's been left big for now
;   so that it's more readable
; -----------------------------------------------------------------------------
init_level_data
    lda     #0                          ; the level starts out empty so fill with pattern 0
    tay                                 ; initialize loop counter to 0 as well

init_data_loop
    sta     LEVEL_DATA,y                ; store emptiness in LEVEL_DATA[y]

    iny                                 ; increment y
init_data_test
    cpy     #34                         ; 34 elements in LEVEL_DATA
    bne     init_data_loop              ; while y<34, branch to top of loop

    rts