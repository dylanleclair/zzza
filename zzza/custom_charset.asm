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

hi_res_0_0 ; 18
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_0_1 ; 19
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_0_2  ; 20 
    dc.b #0,#0,#0,#0,#0,#0,#0,#0

hi_res_1_0  ; 21
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_1_1 ; 22
	;19
    dc.b #%00111100             ; start with the "character" in the middle of the buffer
	dc.b #%01000010
	dc.b #%10100101
	dc.b #%10000001
	dc.b #%10100101
	dc.b #%10011001
	dc.b #%01000010
	dc.b #%00111100
hi_res_1_2 ; 23
    dc.b #0,#0,#0,#0,#0,#0,#0,#0

hi_res_2_0 ; 24
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_2_1 ; 25
    dc.b #0,#0,#0,#0,#0,#0,#0,#0
hi_res_2_2 ; 26
    dc.b #0,#0,#0,#0,#0,#0,#0,#0