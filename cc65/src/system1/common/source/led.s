.include "io.inc"

.import _delay_ms

.export _led_init, _led_on, _led_off, _led_flash

.code

    ; Initializes the LED
    ; IN: Nothing
    ; OUT: Nothing
    ; ZP: Nothing
    _led_init:
        pha
        lda VIA2_DDRA  ; load existing pin settings
        ora #%00000001 ; or the value to set pin to write
        sta VIA2_DDRA
        jsr _led_off
        pla
        rts

    ; Turns the LED on
    ; IN: Nothing
    ; OUT: Nothing
    ; ZP: Nothing
    _led_on:
        pha
        lda VIA2_PORTA ; load existing values
        ora #%00000001 ; or the value to set led pin on
        sta VIA2_PORTA
        pla
        rts

    ; Turns the LED off
    ; IN: Nothing
    ; OUT: Nothing
    ; ZP: Nothing
    _led_off:
        pha
        lda VIA2_PORTA ; load existing values
        and #%11111110 ; and the value to set led pin off
        sta VIA2_PORTA
        pla
        rts

    ; Turns the LED on and then off with a 250ms delay in between and before returning
    ; IN: Nothing
    ; OUT: Nothing
    ; ZP: Nothing
    _led_flash:
        jsr _led_on
        lda #$FA
        jsr _delay_ms
        jsr _led_off
        lda #$FA
        jsr _delay_ms
        rts