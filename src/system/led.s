

  .include "io.inc"

; Initializes the LED
; IN: Nothing
; OUT: Nothing
; ZP: Nothing
led_init:
    pha
    lda VIA2_DDRA  ; load existing pin settings
    ora #%00000001 ; or the value to set pin to write
    sta VIA2_DDRA
    jsr led_off
    pla
    rts

; Turns the LED on
; IN: Nothing
; OUT: Nothing
; ZP: Nothing
led_on:
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
led_off:
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
led_flash:
    jsr led_on
    lda #$FA
    jsr delay_ms
    jsr led_off
    lda #$FA
    jsr delay_ms
    rts
