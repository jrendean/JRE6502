

  .include "io.inc"
  .include "zeropage.inc"


; 
; IN: 
; OUT: 
; ZP: 
console_init:
    pha                       ; save A
    lda #(ACIA_PARITY_DISABLE | ACIA_ECHO_ENABLE | ACIA_TX_INT_DISABLE_RTS_LOW | ACIA_RX_INT_DISABLE | ACIA_DTR_LOW)
    sta ACIA1_COMMAND         ; write the commands to the ACIA Command register
    lda #(ACIA_STOP_BITS_1 | ACIA_DATA_BITS_8 | ACIA_CLOCK_INT | ACIA_BAUD_19200)
    sta ACIA1_CONTROL         ; write the commands to the ACIA Control register
    pla                       ; restore A
    rts                       ; return

; 
; IN: 
; OUT: 
; ZP: 
console_is_data_available:
    pha
    lda ACIA1_STATUS         ; load the ACIA Status register in to A
    and #ACIA_STATUS_RX_FULL ; and with the bits for a fill receive register
    beq .no
    sec
    pla
    rts
.no:
    clc
    pla
    rts

; 
; IN: 
; OUT: 
; ZP: 
console_write_string:
    pha                       ; save A
    phy                       ; save Y
    ldy #0                    ; initialize loop variable Y
.write_loop:
    lda (console_out_ptr), y  ; load byte from pointer in to A
    beq .done                 ; if the byte == 0 then branch to @done
    jsr console_write_byte
    iny                       ; increment Y
    jmp .write_loop           ; jmp to the begining of loop to get next byte
.done:
    ply                       ; restore Y
    pla                       ; restore A
    rts                       ; return


; 
; IN: 
; OUT: 
; ZP: 
console_write_byte:
    pha                       ; save A
.wait_tx_empty:
    lda ACIA1_STATUS          ; load the ACIA Status register in to A
    and #ACIA_STATUS_TX_EMPTY ; and with the bits for an empty transmit register
    beq .wait_tx_empty        ; if the contents of A == 0 branch to _console_write_char
    pla                       ; restore A
    sta ACIA1_DATA            ; write A to ACIA Data register
    ;pha
    ;;WDC 65C51 delay bug fix
    ;lda #1
    ;jsr _delay_ms
    ;pla
    rts                       ; return


; 
; IN: 
; OUT: 
; ZP: 
console_write_hex:
    pha
    phx
    phy
    jsr convert_to_hex
    txa
    jsr console_write_byte
    tya
    jsr console_write_byte
    ply
    plx
    pla
    rts

; 
; IN: 
; OUT: 
; ZP: 
console_read_string:
    pha
    phy

    sta tmp1

    lda #$00
    ldy #$00
.clean_buffer:
    sta (ptr1),y
    iny
    cpy tmp1
    bne .clean_buffer

    ldy #$00
.get_char:
    jsr console_read_byte
    cmp #$0D
    beq .done

    cmp #$08       ; backspace
    beq .backspace
    cmp #$20       ; special chars 0-31, ignore
    bmi .get_char
    cmp #$7e       ; special chars 127-255, ignore
    bpl .get_char 

    cpy tmp1
    beq .done
    ;beq .get_char

    jsr console_write_byte ; echo back to terminal

    sta (ptr1), y
    iny
    bra .get_char

.backspace:
    cpy #$00
    beq .get_char
    dey
    lda #$00
    sta (ptr1), y
    lda #$08
    jsr console_write_byte ; echo back to terminal

    bra .get_char

.done:
    lda #$0D
    jsr console_write_byte
    lda #$0A
    jsr console_write_byte

    ply
    pla
    rts

; 
; IN: 
; OUT: 
; ZP: 
console_read_byte:
    lda ACIA1_STATUS         ; load the ACIA Status register in to A
    and #ACIA_STATUS_RX_FULL ; and with the bits for a fill receive register
    beq console_read_byte    ; if the contents of A == 0 then branch to _console_read_char
    lda ACIA1_DATA           ; load the ACIA Data register in to A
    rts                      ; return
