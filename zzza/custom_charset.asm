; actually starts at character 2 + 8 = 10


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