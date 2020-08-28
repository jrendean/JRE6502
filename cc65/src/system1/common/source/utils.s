.include "zeropage.inc"

.export _delay_ms, _convert_to_hex, _str_length, _str_trim, _str_compare, _primm_console, _primm_lcd
.import _console_write_byte, _lcd_print_char

.code

    ; http://6502.org/source/io/primm.htm
    _primm_console:
        pla               ; get low part of (string address-1)
        sta   DPL
        pla               ; get high part of (string address-1)
        sta   DPH
        bra   @primm3
    @primm2:
        jsr   _console_write_byte        ; output a string char
    @primm3:
        inc   DPL         ; advance the string pointer
        bne   @primm4
        inc   DPH
    @primm4:
        lda   (DPL)       ; get string char
        bne   @primm2      ; output and continue if not NUL
        lda   DPH
        pha
        lda   DPL
        pha
        rts               ; proceed at code following the NUL 

    _primm_lcd:
        pla               ; get low part of (string address-1)
        sta   DPL
        pla               ; get high part of (string address-1)
        sta   DPH
        bra   @primm3
    @primm2:
        jsr   _lcd_print_char        ; output a string char
    @primm3:
        inc   DPL         ; advance the string pointer
        bne   @primm4
        inc   DPH
    @primm4:
        lda   (DPL)       ; get string char
        bne   @primm2      ; output and continue if not NUL
        lda   DPH
        pha
        lda   DPL
        pha
        rts               ; proceed at code following the NUL 

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
    @loop:
        lda (ptr1), y ; load value from ptr1 index Y in to A
        beq @done     ; if value equals 0 branch to @done
        iny           ; increment Y
        bra @loop     ; branch back
    @done:
        dey           ; count currently has \0 so subtract one
        tya           ; transfer Y to A
        ply           ; restore Y
        rts           ; return


    ; 
    ; 
    ; 
    ; 
    _str_trim:
        phy
        ldy #0
    @loop:
        lda (ptr1), y
        beq @done

    @done:
        ply
        rts


    ; http://6502.org/source/strings/comparisons.html
    ; 
    ; 
    ; 
    ; 
    _str_compare999999:
        phy
        ldy #0
    @loop:
        lda (ptr1), y
        beq @check_last_byte
        cmp (ptr2), y
        bne @not_equal
        iny
        beq @loop
    @check_last_byte:
        cmp (ptr2), y
        bne @not_equal
        beq @equal
    @not_equal:
        lda #$FF
        bra @done
    @equal:
        lda #0
        bra @done
    @done:
        ply
        rts

_str_compare:
        phy
        ldy #$00
@strcmp_loop:
        lda (ptr1),y
        beq @ptr1_end
        cmp (ptr2),y
        bne @set_result
        iny
        beq @equal ; prevention against infinite loop
        bra @strcmp_loop
@ptr1_end:
        cmp (ptr2),y
@set_result:
        beq @equal
        bmi @less_than
        lda #$01
        bra @return
@equal:
        lda #$00
        bra @return
@less_than:
        lda #$ff
        bra @return
@return:
        ply
        rts


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


.rodata
    hex_table: .byte "0123456789ABCDEF"
