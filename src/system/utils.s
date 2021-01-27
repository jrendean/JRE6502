




hex_table: .byte "0123456789ABCDEF"

; _convert_to_hex: Converts the value in A to hex by putting MSB in X and LSB in Y
; https://github.com/dbuchwald/6502/blob/master/Software/common/source/utils.s
; IN: A - the value to convert to hex
; OUT: X - MSB, Y- LSB
; ZP: Nothing
convert_to_hex:
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
    tax              ; transfer A to X (cannot do this directly since X is being used above)
    pla              ; restore A
    rts              ; return



dec_table: .word $01, $02, $04, $08, $16, $32, $64, $128
;
; TODO
;
convert_to_dec:
    sed
    stz ptr2
    stz ptr2+1

    sta tmp2

    ldx #$0E
.loop:
    asl tmp2
    bcc .htd1
    lda ptr2
    clc
    adc dec_table, x
    sta ptr2
    lda ptr2+1
    adc dec_table+1, x
    sta ptr2+1
.htd1:
    dex
    dex
    bpl .loop

    cld

    ldy #$00
    lda (ptr2), y

    rts





; http://6502.org/source/io/primm.htm
primm_console:
    pla               ; get low part of (string address-1)
    sta DPL
    pla               ; get high part of (string address-1)
    sta DPH
    bra .primm3
.primm2:
    jsr console_write_byte        ; output a string char
.primm3:
    inc DPL         ; advance the string pointer
    bne .primm4
    inc DPH
.primm4:
    lda (DPL)       ; get string char
    bne .primm2      ; output and continue if not NUL
    lda DPH
    pha
    lda DPL
    pha
    rts               ; proceed at code following the NUL 



primm_lcd:
    pla                 ; get low part of (string address-1)
    sta DPL
    pla                 ; get high part of (string address-1)
    sta DPH
    bra .primm3
.primm2:
    jsr lcd_print_char  ; output a string char
.primm3:
    inc DPL             ; advance the string pointer
    bne .primm4
    inc DPH
.primm4:
    lda (DPL)           ; get string char
    bne .primm2         ; output and continue if not NUL
    lda DPH
    pha
    lda DPL
    pha
    rts                 ; proceed at code following the NUL 






;1 Mhz version
;http://forum.6502.org/viewtopic.php?f=12&t=5254#p62595
; ---------------------------------------------------------------------------
; Delay 5us
; there's an additional 15us overhead for each call, so the
; minimum delay is 20us with increments of 5us. The formula is:
; duration = 5*a + 15, where "a" is the value in the accumulator
; note a value of zero in "a" is treated as 256, not zero!
delay_5us:
   nop
   tax
delay_5us_loop:
   dex
   bne delay_5us_loop
   rts

; ---------------------------------------------------------------------------
; Delay ms
delay_ms:
   phy
   phx
   tay
   lda #196                            ; 196*5 + 15 = 995 (dey&bne take 5 cycles)
delay_ms_loop1:
   jsr delay_5us
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
delay_4us:      ; 6 jsr
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
;delay_ms:
;   phy
;   phx
;   tay
;   lda #249                            ; 249*4 + 3 = 999
;delay_ms_loop1:   
;   jsr delay_4us
;   dey
;   bne delay_ms_loop1
;   plx
;   ply
;   rts
