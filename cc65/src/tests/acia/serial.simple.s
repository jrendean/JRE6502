    .setcpu "65C02"
    .include "io.inc"

    ; define vector
    .segment "VECTORS" ;defined in firmware.cfg starting at $7FFA

    .word   $EAEA       ; $FFFA-$FFFB - MNI
    .word   init       ; $FFFC-$FFFD - Reset
    .word   $EAEA      ; $FFFE-$FFFF - IRQ/BRK


    ; define code
    .segment "CODE" ; could instead use shortcut .code

init:
      ldx #$ff
      txs

      ;stz ACIA1_STATUS
      ;stz ACIA1_COMMAND

      lda #(ACIA_PARITY_DISABLE | ACIA_ECHO_DISABLE | ACIA_TX_INT_DISABLE_RTS_LOW | ACIA_RX_INT_DISABLE | ACIA_DTR_LOW)
      sta ACIA1_COMMAND
      lda #(ACIA_STOP_BITS_1 | ACIA_DATA_BITS_8 | ACIA_CLOCK_INT | ACIA_BAUD_19200)
      sta ACIA1_CONTROL

send_loop:
      ldx #$00
write_char:
      lda prompt, x
      beq read_loop
      pha
wait_txd_empty:
      lda ACIA1_STATUS
      and #ACIA_STATUS_TX_EMPTY
      beq wait_txd_empty
      pla 
      sta ACIA1_DATA
      inx
      bra write_char

read_loop:
wait_rxd_full:
      lda ACIA1_STATUS
      and #ACIA_STATUS_RX_FULL
      beq wait_rxd_full
      lda ACIA1_DATA
      bra send_loop

prompt:
      .byte "Hello>", $0a, $0d, $00