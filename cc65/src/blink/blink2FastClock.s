    .setcpu "65C02"
    .include "io.inc"

    ; define vector
    .segment "VECTORS" ;defined in firmware.cfg starting at $7FFA

    .word   $EAEA      ; $FFFA-$FFFB - MNI
    .word   init       ; $FFFC-$FFFD - Reset
    .word   $EAEA      ; $FFFE-$FFFF - IRQ/BRK


    ; define code
    .segment "CODE" ; could instead use shortcut .code

init:
    lda #$ff
    sta VIA1_DDRB

    lda #$50
    sta VIA1_ORB

loop:
    ror
    sta VIA1_ORB
    jsr delay
    jmp loop


delay:
    ldx #100
delayinner:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dex
    bne delayinner
    rts 