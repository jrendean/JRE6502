





; _convert_to_hex: Converts the value in A to hex by putting MSB in X and LSB in Y
; https://github.com/dbuchwald/6502/blob/master/Software/common/source/utils.s
; IN: A - the value to convert to hex
; OUT: X - MSB, Y- LSB
; ZP: Nothing
_convert_to_hex:
    pha              ; save A
    pha              ; save A for use in MSB
    and #%00001111   ; mask off MSB
    tax              ; transfer A to X for use in lookup indexing
    ldy hex_table, x ; store the value from lookup table to Y
    pla              ; restore A for MSB
    lsr              ; shift 4 times
    lsr
    lsr
    lsr
    tax              ; transfer A to X for use in lookup indexing
    lda hex_table, x ; load value from table in to A
    tax              ; transfer A to X (cannot do this  directly since X is being used above)
    pla              ; restore A
    rts              ; return


; 
; IN: 
; OUT: A is the length of the string
; ZP: ptr1
_str_length:
    phy           ; save Y
    ldy #0        ; set Y to 0
.loop:
    lda (ptr1), y ; load value from ptr1 index Y in to A
    beq .done     ; if value equals 0 branch to @done
    iny           ; increment Y
    bra .loop     ; branch back
.done:
    dey           ; count currently has \0 so subtract one
    tya           ; transfer Y to A
    ply           ; restore Y
    rts           ; return




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
_delay_4us:      ; 6 jsr
   tax         ; 2
delay_4us_loop:
   pha         ; 3
   pla         ; 4
   nop         ; 2
   nop         ; 2
   dex         ; 2
   bne delay_4us_loop    ; 2/3
   rts         ; 6

; ---------------------------------------------------------------------------
; Delay ms
;
;_delay_ms:
;   phy
;   phx
;   tay
;   lda #249                            ; 249*4 + 3 = 999
;delay_ms_loop1:   
;   jsr _delay_4us
;   dey
;   bne delay_ms_loop1
;   plx
;   ply
;   rts





.rodata
    hex_table: .byte "0123456789ABCDEF"