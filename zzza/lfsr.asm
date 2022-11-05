; -----------------------------------------------------------------------------
; SUBROUTINE: LFSR
; - this is the lfsr presented in class
; - performs a left shift on the LFSR, and uses bits 6 and 7 as taps
; -----------------------------------------------------------------------------
lfsr 
    lda     LFSR_ADDR                   ; get the old lfsr value
    asl                                 ; arithmetic shift the accumulator, carry now has b7
    eor     LFSR_ADDR                   ; accumulator XOR lfsr
    asl                                 ; arithmetic shift the accumulator again, carry now has b6 XOR b7
    rol     LFSR_ADDR                   ; rotate the lfsr, fill in the lsb with b6 XOR b7

lfsr_exit
    rts