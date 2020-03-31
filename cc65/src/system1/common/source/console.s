.include "io.inc"
.include "zeropage.inc"

.import _delay_ms

.export _console_init
.export _console_write_string
.export _console_write_char
.export _console_read_char

.code

    _console_init:
        pha
        ;stz ACIA1_STATUS
        ;stz ACIA1_COMMAND
        lda #(ACIA_PARITY_DISABLE | ACIA_ECHO_ENABLE | ACIA_TX_INT_DISABLE_RTS_LOW | ACIA_RX_INT_DISABLE | ACIA_DTR_LOW)
        sta ACIA1_COMMAND
        lda #(ACIA_STOP_BITS_1 | ACIA_DATA_BITS_8 | ACIA_CLOCK_INT | ACIA_BAUD_19200)
        sta ACIA1_CONTROL
        pla
        rts

    _console_write_string:
        pha
        phy

        ldy #0
    @write_loop:
        lda (console_out_ptr), y
        ;beq read
        beq @done
        pha
    @wait_tx_empty:
        lda ACIA1_STATUS
        and #ACIA_STATUS_TX_EMPTY
        beq @wait_tx_empty
        pla
        sta ACIA1_DATA
        ;pha
        ;;WDC 65C51 delay bug fix
        ;lda #1
        ;jsr _delay_ms
        ;pla
        iny
        jmp @write_loop
    @done:
        ply
        pla
        rts

    _console_write_char:
        pha
        lda ACIA1_STATUS
        and #ACIA_STATUS_TX_EMPTY
        beq _console_write_char
        pla
        sta ACIA1_DATA
        ;pha
        ;;WDC 65C51 delay bug fix
        ;lda #1
        ;jsr _delay_ms
        ;pla
        rts

    _console_read_char:
        lda ACIA1_STATUS
        and #ACIA_STATUS_RX_FULL
        beq _console_read_char
        lda ACIA1_DATA
        rts

    ;read:
    ;@wait_rxd_full:
    ;    lda ACIA1_STATUS
    ;    and #ACIA_STATUS_RX_FULL
    ;    beq @wait_rxd_full
    ;    lda ACIA1_DATA
    ;    sta serial_int_ptr
    ;    rts
