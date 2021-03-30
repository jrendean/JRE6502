.setcpu "65C02"

.import led_flash

  ldx #5
main_loop:
  jsr led_flash
  dex
  bne main_loop
  rts