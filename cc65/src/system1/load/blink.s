        .setcpu "65C02"

.import _led_init, _led_on, _led_off, _led_flash

        .segment "VECTORS"

        .word   $0000
        .word   init
        .word   $0000


        .code
init:
        jsr _led_init
        ldx #10
main_loop:
        jsr _led_flash
        dex
        bne main_loop
        rts