    .setcpu "65C02"

    .include "zeropage.inc"

    .import _lcd_init
    .import _lcd_print

    ; define vector
    .segment "VECTORS" ;defined in firmware.cfg starting at $7FFA

    .word   $EAEA     ; $FFFA-$FFFB - MNI
    .word   reset   ; $FFFC-$FFFD - Reset
    .word   $EAEA     ; $FFFE-$FFFF - IRQ/BRK


    ; define code
    .segment "CODE" ; could instead use shortcut .code

reset:
    ;sei
    ;cld
    ;ldx #$ff
    ;txs

    jsr _lcd_init

    lda #<message
    sta lcd_out_ptr
    lda #>message
    sta lcd_out_ptr+1
    jsr _lcd_print

    ;cli

loop:
    jmp loop

    .segment "RODATA"

message:
  .byte "Line 1 -- 0123456789Line 2 -- 0123456789Line 3 -- 0123456789Line 4 -- 0123456789", $00
