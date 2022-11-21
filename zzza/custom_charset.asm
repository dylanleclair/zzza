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

empty_block ;0
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
quarter_fill ;1
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%11111111
    dc.b #%11111111
half_fill ;2
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
3quarter_fill ;3
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
full_fill ;4
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
quarter_inv ;5
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%00000000
    dc.b #%00000000
half_inv ;6
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
3quarter_inv ;7
    dc.b #%11111111
    dc.b #%11111111
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00000000
eva_front ;18
    dc.b #%00111100
    dc.b #%00111100
    dc.b #%00011000
    dc.b #%00111100
    dc.b #%01011010
    dc.b #%00100100
    dc.b #%11111111
    dc.b #%01100110

hi_res_0_0 ; 19
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_0_1 ; 20
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_0_2  ; 21 
    dc.b #0,#0,#0,#0,#0,#0,#0,#0

hi_res_1_0  ; 22
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_1_1 ; 23
	;19
    dc.b #%00111100             ; start with the "character" in the middle of the buffer
	dc.b #%01000010
	dc.b #%10100101
	dc.b #%10000001
	dc.b #%10100101
	dc.b #%10011001
	dc.b #%01000010
	dc.b #%00111100
hi_res_1_2 ; 24
    dc.b #0,#0,#0,#0,#0,#0,#0,#0

hi_res_2_0 ; 25
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_2_1 ; 26
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_2_2 ; 27
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
0_char ;8
    dc.b #%00111100
    dc.b #%01000010
    dc.b #%01000110
    dc.b #%01011010
    dc.b #%01100010
    dc.b #%01000010
    dc.b #%00111100
    dc.b #%00000000
1_char ;9
    dc.b #%00001000
    dc.b #%00011000
    dc.b #%00101000
    dc.b #%00001000
    dc.b #%00001000
    dc.b #%00001000
    dc.b #%00111110
    dc.b #%00000000
2_char ;10
    dc.b #%00111100
    dc.b #%01000010
    dc.b #%00000010
    dc.b #%00001100
    dc.b #%00110000
    dc.b #%01000000
    dc.b #%01111110
    dc.b #%00000000
3_char ;11
    dc.b #%00111100
    dc.b #%01000010
    dc.b #%00000010
    dc.b #%00001100
    dc.b #%00000010
    dc.b #%01000010
    dc.b #%00111100
    dc.b #%00000000
4_char ;12
    dc.b #%00000100
    dc.b #%00001100
    dc.b #%00010100
    dc.b #%00100100
    dc.b #%01111110
    dc.b #%00000100
    dc.b #%00000100
    dc.b #%00000000
5_char ;13
    dc.b #%01111110
    dc.b #%01000000
    dc.b #%01111000
    dc.b #%00000100
    dc.b #%00000010
    dc.b #%01000100
    dc.b #%00111000
    dc.b #%00000000
6_char ;14
    dc.b #%00011100
    dc.b #%00100000
    dc.b #%01000000
    dc.b #%01111100
    dc.b #%01000010
    dc.b #%01000010
    dc.b #%00111100
    dc.b #%00000000
7_char ;15
    dc.b #%01111110
    dc.b #%01000010
    dc.b #%00000100
    dc.b #%00001000
    dc.b #%00010000
    dc.b #%00010000
    dc.b #%00010000
    dc.b #%00000000
8_char ;16
    dc.b #%00111100
    dc.b #%01000010
    dc.b #%01000010
    dc.b #%00111100
    dc.b #%01000010
    dc.b #%01000010
    dc.b #%00111100
    dc.b #%00000000
9_char ;17
    dc.b #%00111100
    dc.b #%01000010
    dc.b #%01000010
    dc.b #%00111110
    dc.b #%00000010
    dc.b #%00000100
    dc.b #%00111000
    dc.b #%00000000
quarter_horiz: ;18
    dc.b #%11000000
    dc.b #%11000000
    dc.b #%11000000
    dc.b #%11000000
    dc.b #%11000000
    dc.b #%11000000
    dc.b #%11000000
    dc.b #%11000000
half_horiz: ;19
    dc.b #%11110000
    dc.b #%11110000
    dc.b #%11110000
    dc.b #%11110000
    dc.b #%11110000
    dc.b #%11110000
    dc.b #%11110000
    dc.b #%11110000
three_fourths_horiz: ;20
    dc.b #%11111100
    dc.b #%11111100
    dc.b #%11111100
    dc.b #%11111100
    dc.b #%11111100
    dc.b #%11111100
    dc.b #%11111100
    dc.b #%11111100
quarter_empty_horiz: ;21
    dc.b #%00111111
    dc.b #%00111111
    dc.b #%00111111
    dc.b #%00111111
    dc.b #%00111111
    dc.b #%00111111
    dc.b #%00111111
    dc.b #%00111111
half_empty_horiz: ;22
    dc.b #%00001111
    dc.b #%00001111
    dc.b #%00001111
    dc.b #%00001111
    dc.b #%00001111
    dc.b #%00001111
    dc.b #%00001111
    dc.b #%00001111
three_quarter_empty_horiz: ;23
    dc.b #%00000011
    dc.b #%00000011
    dc.b #%00000011
    dc.b #%00000011
    dc.b #%00000011
    dc.b #%00000011
    dc.b #%00000011
    dc.b #%00000011