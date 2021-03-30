.include "io.inc"

.import delay_ms

.export led_init, led_on, led_off, led_flash

.code

  ; Initializes the LED
  ; IN: Nothing
  ; OUT: Nothing
  ; ZP: Nothing
  led_init:
    pha
    jsr led_off
    pla
    rts

  ; Turns the LED on
  ; IN: Nothing
  ; OUT: Nothing
  ; ZP: Nothing
  led_on:
    pha
    lda LED_PORT ; load existing values
    ora PIN_LED  ; or the value to set led pin on
    sta LED_PORT 
    pla
    rts

  ; Turns the LED off
  ; IN: Nothing
  ; OUT: Nothing
  ; ZP: Nothing
  led_off:
    pha
    lda LED_PORT ; load existing values
    eor PIN_LED  ; eor the value to set the led pin off
    sta LED_PORT
    pla
    rts

  ; Turns the LED on and then off with a 150ms delay in between and before returning
  ; IN: Nothing
  ; OUT: Nothing
  ; ZP: Nothing
  led_flash:
    jsr led_on
    lda #150
    jsr delay_ms
    jsr led_off
    jsr delay_ms
    rts
