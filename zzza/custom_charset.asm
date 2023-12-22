; actually starts at character 2 + 8 = 10

; -----------------------------------------------------------------------------
; High resolution graphics buffer
;
;   * occupies characters 18 to 26
;   * is a buffer of 9 characters, with EVA at the center by default
;       * is 9 characters so all tiles adjacent to EVA are included
;       * this means EVA can go anywhere in the buffer
;       * buffer can go anywhere on screen!
;
;   Mapping of character to buffer (i,j):
;
;   -------------------
;   | 0,0 | 0,1 | 0,2 |
;   -------------------
;   | 1,0 | 1,1 | 1,2 |
;   -------------------
;   | 2,0 | 2,1 | 2,2 |
;   -------------------
;
;   To keep scrolling logic intact, and since it looked much better than re-drawing the whole screen, we actually 
;   back up the section of screen memory where high-res graphics are being displayed. We restore it to the screen 
;   just before calling the scrolling code (which updates it), then save it again before it is masked onto the 
;   high-resolution graphics. 
;
;   It's also very important that any time EVA's position is updated that 1. we put the backed-up data back onto the screen
;   before updating her position and 2. after her position changes, we backup the data again so so it (and any screen data) 
;   doesn't get lost / clobbered.
;
;   Finally, the high resolution graphics characters are drawn to screen based on EVA's position.
;
;   The buffer is always centered around EVAs position, and a number of "shifts" either left, right, up or down. 
;   Each "shift" function shifts the ENTIRE high-res framebuffer by one bit in the appropriate direction. 
;   
;   For example, to draw EVA 3/4 of a block down and 3/4 of a block to the right, you must call the shift_down and shift_left functions each 6 times (order doesn't matter).
;
;   After EVA reaches the edge of the buffer, it should be reset (clear out all data, put EVA back in the center of the buffer), with her position (X_COOR, Y_COOR) updated
;   s.t. her new position is where had effectively moved to. For example, if you shift 8 down, you should revert the graphics buffer & increment Y_COOR. 
;   
;   This gives the illusion that EVA has moved from one block to the next, while preparing the buffer to move once more. 
;
; -----------------------------------------------------------------------------

empty_block ;2
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000

quarter_fill ;3
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%01010101
    dc.b #%01010101

half_fill ;4
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101

3quarter_fill ;5
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101

full_fill ;6
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
quarter_inv ;7
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%00000000
    dc.b #%00000000

half_inv ;8
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000

3quarter_inv ;9
    dc.b #%01010101
    dc.b #%01010101
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000

eva_front ;10
    dc.b #%00101000
    dc.b #%10111110
    dc.b #%10111110
    dc.b #%11010111
    dc.b #%00101000
    dc.b #%01000001
    dc.b #%11111111
    dc.b #%10000010

hi_res_0_0 ; 11
    dc.b #0,#0,#0,#0,#0,#0,#0,#0    ; square above eva in hi-res
hi_res_0_1 ; 12
    ; dc.b #0,#0,#0,#0,#0,#0,#0,#0    ; eva's square in hi-res
    dc.b #%00111100             ; start with the "character" in the middle of the buffer
	dc.b #%01000010
	dc.b #%10100101
	dc.b #%10000001
	dc.b #%10100101
	dc.b #%10011001
	dc.b #%01000010
	dc.b #%00111100
hi_res_0_2  ; 13 
    dc.b #0,#0,#0,#0,#0,#0,#0,#0    ; square below eva in hi-res

; -----------------------------------------------------------------------------
; hi-res below this point is no longer needed
; -----------------------------------------------------------------------------

hi_res_1_0  ; 14
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_1_1 ; 15
    dc.b #%00111100             ; start with the "character" in the middle of the buffer
	dc.b #%01000010
	dc.b #%10100101
	dc.b #%10000001
	dc.b #%10100101
	dc.b #%10011001
	dc.b #%01000010
	dc.b #%00111100
hi_res_1_2 ; 16
    dc.b #0,#0,#0,#0,#0,#0,#0,#0

hi_res_2_0 ; 17
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_2_1 ; 18
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_2_2 ; 19
    dc.b #0,#0,#0,#0,#0,#0,#0,#0

eva_left_sprite ; 20
    dc.b #%00101010
    dc.b #%00111010
    dc.b #%00111000
    dc.b #%00010111
    dc.b #%11101000
    dc.b #%00010001
    dc.b #%11111111
    dc.b #%10001000
eva_right_sprite ; 21
    dc.b #%10101000
    dc.b #%10101100
    dc.b #%00101100
    dc.b #%11010100
    dc.b #%00101011
    dc.b #%01000100
    dc.b #%11111111
    dc.b #%00100010

falling_block: ; 22
    dc.b #%10101010
    dc.b #%10101010
    dc.b #%10101010
    dc.b #%10101010
    dc.b #%10101010
    dc.b #%10101010
    dc.b #%10101010
    dc.b #%10101010
secret_block: ; 23
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
p_zzza; 24
    dc.b #%11111111
    dc.b #%11100111
    dc.b #%11010001
    dc.b #%11001100
    dc.b #%10100010
    dc.b #%10001001
    dc.b #%01000111
    dc.b #%00111111
door: ; 25
    dc.b #%11111111
    dc.b #%10000001
    dc.b #%10000001
    dc.b #%10000001
    dc.b #%10000101
    dc.b #%10000001
    dc.b #%10000001
    dc.b #%10000001

