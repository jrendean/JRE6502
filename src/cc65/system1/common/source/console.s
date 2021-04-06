.include "io.inc"
.include "zeropage.inc"

.import delay_ms, convert_to_hex

.export console_init, console_is_data_available 
.export console_write_string, console_write_byte, console_write_hex, console_write_newline
.export console_read_byte, console_read_string
.export primm_console

.export b2ad, b2ad2, dpb2ad

.code

  ; 
  ; IN: 
  ; OUT: 
  ; ZP: 
  console_init:
    pha             ; save A
    lda #(ACIA_PARITY_DISABLE | ACIA_ECHO_ENABLE | ACIA_TX_INT_DISABLE_RTS_LOW | ACIA_RX_INT_DISABLE | ACIA_DTR_LOW)
    sta ACIA1_COMMAND     ; write the commands to the ACIA Command register
    lda #(ACIA_STOP_BITS_1 | ACIA_DATA_BITS_8 | ACIA_CLOCK_INT | ACIA_BAUD_19200)
    sta ACIA1_CONTROL     ; write the commands to the ACIA Control register
    pla             ; restore A
    rts             ; return

  ; 
  ; IN: 
  ; OUT: 
  ; ZP: 
  console_is_data_available:
    pha
    lda ACIA1_STATUS     ; load the ACIA Status register in to A
    and #ACIA_STATUS_RX_FULL ; and with the bits for a fill receive register
    beq @no
    sec
    pla
    rts
  @no:
    clc
    pla
    rts

  ; 
  ; IN: 
  ; OUT: 
  ; ZP: 
  console_write_string:
    pha             ; save A
    phy             ; save Y
    ldy #0          ; initialize loop variable Y
  @write_loop:
    lda (console_out_ptr), y  ; load byte from pointer in to A
    beq @done         ; if the byte == 0 then branch to @done
    jsr console_write_byte
    iny             ; increment Y
    jmp @write_loop       ; jmp to the begining of loop to get next byte
  @done:
    ply             ; restore Y
    pla             ; restore A
    rts             ; return


  ; 
  ; IN: 
  ; OUT: 
  ; ZP: 
  console_write_byte:
    pha             ; save A
  @wait_tx_empty:
    lda ACIA1_STATUS      ; load the ACIA Status register in to A
    and #ACIA_STATUS_TX_EMPTY ; and with the bits for an empty transmit register
    beq @wait_tx_empty    ; if the contents of A == 0 branch to _console_write_char
    pla             ; restore A
    sta ACIA1_DATA      ; write A to ACIA Data register
    ;;pha
    ;;WDC 65C51 delay bug fix
    ;lda #1
    ;jsr delay_ms
    ;;pla
    rts             ; return


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
  ; ZP: tmp1, ptr1
  console_read_string:
    pha
    phy

    sta tmp1

    lda #$00
    ldy #$00
  @clean_buffer:
    sta (ptr1),y
    iny
    cpy tmp1
    bne @clean_buffer

    ldy #$00
  @get_char:
    jsr console_read_byte
    cmp #$0D
    beq @done

    cmp #$08       ; backspace
    beq @backspace
    cmp #$20       ; special chars 0-31, ignore
    bmi @get_char
    cmp #$7E       ; special chars 127-255, ignore
    bpl @get_char 

    cpy tmp1
    beq @done
    ;beq @get_char

    jsr console_write_byte ; echo back to terminal

    sta (ptr1), y
    iny
    bra @get_char

  @backspace:
    cpy #$00
    beq @get_char
    dey
    lda #$00
    sta (ptr1), y
    lda #$08
    jsr console_write_byte ; echo back to terminal
    bra @get_char

  @done:
    jsr console_write_newline

    ply
    pla
    rts


  ; 
  ; IN: 
  ; OUT: 
  ; ZP: 
  console_read_byte:
    lda ACIA1_STATUS     ; load the ACIA Status register in to A
    and #ACIA_STATUS_RX_FULL ; and with the bits for a fill receive register
    beq console_read_byte   ; if the contents of A == 0 then branch to _console_read_char
    lda ACIA1_DATA       ; load the ACIA Data register in to A
    rts            ; return


  console_write_newline:
    pha
    lda #$0D
    jsr console_write_byte
    lda #$0A
    jsr console_write_byte
    pla
    rts


  ; http://6502.org/source/io/primm.htm
  primm_console:
    pla         ; get low part of (string address-1)
    sta   DPL
    pla         ; get high part of (string address-1)
    sta   DPH
    bra   @primm3
  @primm2:
    jsr   console_write_byte    ; output a string char
  @primm3:
    inc   DPL     ; advance the string pointer
    bne   @primm4
    inc   DPH
  @primm4:
    lda   (DPL)     ; get string char
    bne   @primm2    ; output and continue if not NUL
    lda   DPH
    pha
    lda   DPL
    pha
    rts         ; proceed at code following the NUL 




b2ad:		phx
			ldx #$00
@c10:		cmp #10
			bcc @out2
			sbc #10
			inx
			bra @c10
@out2:		jsr putout
			clc
			adc #$30
			jsr console_write_byte
			plx
			rts

putout:		pha
			txa
			adc #$30
			jsr console_write_byte
			pla
			rts

b2ad2:		phx
			ldx #$00
@c100:		cmp #100
			bcc @out1
			sbc #100
			inx
			bra @c100
@out1:		jsr putout
			ldx #$00
@c10:		cmp #10
			bcc @out2
			sbc #10
			inx
			bra @c10
@out2:		jsr putout
			clc
			adc #$30
			jsr console_write_byte
			plx
			rts


dpb2ad:
			sta tmp3
			stx tmp1
			ldy #$00
			sty tmp2
nxtdig:

			ldx #$00
subem:		lda tmp3
			sec
			sbc subtbl,y
			sta tmp3
			lda tmp1
			iny
			sbc subtbl,y
			bcc adback
			sta tmp1
			inx
			dey
			bra subem

adback:

			dey
			lda tmp3
			adc subtbl,y
			sta tmp3
			txa
			bne setlzf
			bit tmp2
			bmi cnvta
			bpl printspc
setlzf:		ldx #$80
			stx tmp2

cnvta:		ora #$30
			jsr console_write_byte
			bra uptbl
printspc:
			lda #' '
			jsr console_write_byte

uptbl:		iny
			iny
			cpy #08
			bcc nxtdig
			lda tmp3
			ora #$30


			jmp console_write_byte
;			rts


subtbl:		.word 10000
			.word 1000
			.word 100
			.word 10