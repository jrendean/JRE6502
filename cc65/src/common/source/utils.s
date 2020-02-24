; Delay subroutines

.export _delay_5us
.export _delay_ms

.segment  "CODE"

;1 Mhz version
;http://forum.6502.org/viewtopic.php?f=12&t=5254#p62595
; ---------------------------------------------------------------------------
; Delay 5us
; there's an additional 15us overhead for each call, so the
; minimum delay is 20us with increments of 5us. The formula is:
; duration = 5*a + 15, where "a" is the value in the accumulator
; note a value of zero in "a" is treated as 256, not zero!
_delay_5us:
   nop
   tax
delay_5us_loop:
   dex
   bne delay_5us_loop
   rts

; ---------------------------------------------------------------------------
; Delay ms
_delay_ms:
   phy
   phx
   tay
   lda #196                            ; 196*5 + 15 = 995 (dey&bne take 5 cycles)
delay_ms_loop1:   
   jsr _delay_5us
   dey
   bne delay_ms_loop1
   plx
   ply
   rts

;4Mhz version
;http://forum.6502.org/viewtopic.php?f=12&t=5254&hilit=HD44780&start=15#p62993
; ---------------------------------------------------------------------------
; Delay's based on 4MHz 65C02 CPU
;
; Delay 4us
; there's an additional 3us overhead for each call, so the
; minimum delay is 7us with increments of 4us. The formula is:
; duration = 4*a + 3, where "a" is the value in the accumulator
; note a value of zero in "a" is treated as 256, not zero!
; range is from 7us to 1027us
;_delay_4us:      ; 6 jsr
;   tax         ; 2
;delay_4us_loop:
;   pha         ; 3
;   pla         ; 4
;   nop         ; 2
;   nop         ; 2
;   dex         ; 2
;   bne delay_4us_loop    ; 2/3
;   rts         ; 6

; ---------------------------------------------------------------------------
; Delay ms
;
;_delay_ms:
;   tay
;   lda #249                            ; 249*4 + 3 = 999
;delay_ms_loop1:   
;   jsr _delay_4us
;   dey
;   bne delay_ms_loop1
;   rts