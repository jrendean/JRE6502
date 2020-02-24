    .setcpu "65C02"
    .include "io.inc"

.import _delay_ms

    ; define vector
    .segment "VECTORS" ;defined in firmware.cfg starting at $7FFA

    .word   $EAE       ; $FFFA-$FFFB - MNI
    .word   init       ; $FFFC-$FFFD - Reset
    .word   $EAEA      ; $FFFE-$FFFF - IRQ/BRK


    ; define code
    .segment "CODE" ; could instead use shortcut .code

init:
init_acia:        lda #%00001011        ;No parity, no echo, no interrupt
                  sta ACIA1_COMMAND
                  lda #%00011111        ;1 stop bit, 8 data bits, 19200 baud
                  sta ACIA1_CONTROL

write1:           ldx #0
@next_char:       lda hello,x
                  beq read
                  jsr send_char
                  inx
                  jmp @next_char

read:
wait_rxd_full:    lda ACIA1_STATUS
                  and #$08
                  beq wait_rxd_full
                  lda ACIA1_DATA
                  pha

write2:           ldx #0
@next_char:       lda answer,x
                  beq write3
                  jsr send_char
                  inx
                  jmp @next_char

write3:           pla
                  jsr send_char
                  lda #$0d
                  jsr send_char
                  lda #$0a
                  jsr send_char
                  jmp read

send_char:        pha
@wait_txd_empty:  lda ACIA1_STATUS
                  and #$10
                  beq @wait_txd_empty
                  pla
                  sta ACIA1_DATA

                        ;WDC 65C51 delay bug fix
      lda #1
      jsr _delay_ms

                  rts

hello:            .byte $0d, $0a, "Hello World!", $0d, $0a, 0
answer:           .byte $0d, $0a, "You typed: ", 0