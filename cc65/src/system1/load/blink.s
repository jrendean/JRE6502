.setcpu "65C02"

.import led_init, led_flash

.segment "VECTORS"
  .word $0000
  .word init
  .word $0000

.code
  init:
    ;;jsr led_init
    ldx #10
  main_loop:
    jsr led_flash
    dex
    bne main_loop
    rts