
.include "macros.inc"
.include "zeropage.inc"

.import console_write_byte, console_write_hex, console_write_newline, primm_console
.import str_length

.export dump_registers, dump_memory, jump_memory, write_memory


dump_registers:
  pha

  jsr primm_console
  .asciiz "A=$"
  jsr console_write_hex

  jsr primm_console
  .asciiz ", X=$"
  txa
  jsr console_write_hex

  jsr primm_console
  .asciiz ", Y=$"
  tya
  jsr console_write_hex

  jsr primm_console
  .asciiz ", SP=$"
  tsx
  txa
  jsr console_write_hex

  php
  jsr primm_console
  .asciiz ", P="
  pla
  sta tmp1
  and #$80
  beq @n0
  lda #'n'
  bra @n1
  @n0: lda #'N'
  @n1: jsr console_write_byte
  lda tmp1
  and #$40
  beq @v0
  lda #'v'
  bra @v1
  @v0: lda #'V'
  @v1: jsr console_write_byte
  lda tmp1
  and #$20
  beq @b0
  lda #'b'
  bra @b1
  @b0: lda #'B'
  @b1: jsr console_write_byte
  lda tmp1
  and #$10
  beq @b2
  lda #'b'
  bra @b3
  @b2: lda #'B'
  @b3: jsr console_write_byte
  lda tmp1
  and #$08
  beq @d0
  lda #'d'
  bra @d1
  @d0: lda #'D'
  @d1: jsr console_write_byte
  lda tmp1
  and #$04
  beq @i0
  lda #'i'
  bra @i1
  @i0: lda #'I'
  @i1: jsr console_write_byte
  lda tmp1
  and #$02
  beq @z0
  lda #'z'
  bra @z1
  @z0: lda #'Z'
  @z1: jsr console_write_byte
  lda tmp1
  and #$01
  beq @c0
  lda #'c'
  bra @c1
  @c0: lda #'C'
  @c1: jsr console_write_byte
  jsr console_write_newline

  pla
  rts





jump_memory:
    ldy #$02
    jsr scan_hex16_offset

@print_address:
    lda #'*'
    jsr console_write_byte
    lda ptr2 + 1
    jsr console_write_hex
    lda ptr2
    jsr console_write_hex
    jsr console_write_newline

@jump:
    jmp (ptr2)





write_memory:
    ldy #$02
    jsr scan_hex16_offset

@print_address:
    lda ptr2 + 1
    jsr console_write_hex
    lda ptr2
    jsr console_write_hex
    lda #':'
    jsr console_write_byte

@read_and_print_byte:
    ldy #$07
    jsr scan_hex_offset
    jsr console_write_hex
    jsr console_write_newline

@store_value:
    ldy #0
    sta (ptr2),y
    rts




dump_memory:
    jsr str_length
    cmp #$07
    bmi @no_length
    cmp #$08
    beq @one_digit_length
    ldy #$07
    jsr scan_hex_offset
    tax
    jmp @start

@one_digit_length:
    ldy #$07
    lda (ptr1),y
    jsr scan_hex_char
    tax
    jmp @start

@no_length:
    ldx #$01

@start:
    ldy #$02
    jsr scan_hex16_offset

@print_address:
    lda ptr2 + 1
    jsr console_write_hex
    lda ptr2
    jsr console_write_hex
    lda #' '
    jsr console_write_byte
    jsr console_write_byte

@print_bytes:
    ldy #0
@next_byte:
    lda (ptr2),y
    jsr console_write_hex
    
    lda #' '
    jsr console_write_byte
    cpy #7
    bne @skip_mid_sep
    jsr console_write_byte
@skip_mid_sep:
    iny
    cpy #16
    bne @next_byte

@print_chars:
    lda #' '
    jsr console_write_byte
    jsr console_write_byte
    lda #'|'
    jsr console_write_byte
    ldy #0
@next_char:
    lda (ptr2),y
    cmp #$20
    bcc @non_printable
    cmp #$7e
    bcs @non_printable
    jmp @printable
@non_printable:
    lda #'.'
@printable:
    jsr console_write_byte
    iny
    cpy #16
    bne @next_char
    lda #'|'
    jsr console_write_byte
    jsr console_write_newline

    dex
        php
        pha
        clc
        lda ptr2
        adc #16
        sta ptr2
        lda ptr2+1
        adc #$00
        sta ptr2+1
        pla
        plp 
    cpx #0
    bne @print_address

    rts


; Convert the hex character in the accu to its integer value
; The integer value is returned in the accu
scan_hex_char:
    cmp #'0'
    bcc @invalid
    cmp #('9' + 1)
    bcs @no_digit
    sec
    sbc #'0'
    rts
@no_digit:
    cmp #'A'
    bcc @invalid
    cmp #('F' + 1)
    bcs @no_upper_hex
    sec
    sbc #('A' - 10)
    rts
@no_upper_hex:
    cmp #'a'
    bcc @invalid
    cmp #('f' + 1)
    bcs @invalid
    sec
    sbc #('a' - 10)
    rts
@invalid:
    lda #0
    rts

; Convert two hex characters starting at (R0) into an integer value
; The integer value is returned in the accu
scan_hex:
    ldy #$00

scan_hex_offset:
    ;tya
    ;pha
    ;ldy #0
    lda (ptr1),y
    jsr scan_hex_char
    asl
    asl
    asl
    asl
    sta tmp1
    iny
    lda (ptr1),y
    jsr scan_hex_char
    ora tmp1
    sta tmp1
    ;pla
    ;tay
    lda tmp1
    rts

; Convert four hex characters starting at (R0) into an integer value
; The integer value is returned in RES..RES+1
scan_hex16:
    ldy #$00

scan_hex16_offset:
    pha
    phy
    ;ldy #0
    lda (ptr1),y
    jsr scan_hex_char
    asl
    asl
    asl
    asl
    sta ptr2 + 1
    iny
    lda (ptr1),y
    jsr scan_hex_char
    ora ptr2 + 1
    sta ptr2 + 1
    iny
    lda (ptr1),y
    jsr scan_hex_char
    asl
    asl
    asl
    asl
    sta ptr2
    iny
    lda (ptr1),y
    jsr scan_hex_char
    ora ptr2
    sta ptr2
    ply
    pla
    rts
