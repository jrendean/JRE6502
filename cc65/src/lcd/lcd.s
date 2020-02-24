    .include "lcd.inc"
    .include "zeropage.inc"

    .import _delay_ms

    .export _lcd_init
    .export _lcd_print

    ; define code
    .segment "CODE" ; could instead use shortcut .code


_lcd_init:
  pha

  lda #%11111111 ; Set all pins on port B to output
  sta VIA1_DDRA

  ; wait for startup
  lda #50
  jsr _delay_ms

  ; https://en.wikipedia.org/wiki/Hitachi_HD44780_LCD_controller
  ;3x force to 8bit - 0011 0000 (8bit write)
  lda #(CMD_FUNCTION_SET | FS_DATA_LENGTH_8)
  jsr cmdwrite8
  lda #1
  jsr _delay_ms
  lda #(CMD_FUNCTION_SET | FS_DATA_LENGTH_8)
  jsr cmdwrite8
  lda #1
  jsr _delay_ms
  lda #(CMD_FUNCTION_SET | FS_DATA_LENGTH_8)
  jsr cmdwrite8
  lda #1
  jsr _delay_ms
  ;set to 4bit - 0010 0000 (8bit write)
  lda #CMD_FUNCTION_SET
  jsr cmdwrite8
  lda #1
  jsr _delay_ms

  ; Actual initialization
  lda #(CMD_FUNCTION_SET | FS_DATA_LENGTH_4 | FS_NUM_LINES_2 | FS_FONT_5X8)
  jsr cmdwrite4
  lda #2
  jsr _delay_ms 
  lda #(CMD_DISPLAY_CONTROL | DC_DISPLAY_ON | DC_CURSOR_OFF)
  jsr cmdwrite4
  lda #2
  jsr _delay_ms
  lda #(CMD_ENTRY_MODE_SET | EM_CURSOR_INC | EM_SHIFT_CURSOR)
  jsr cmdwrite4
  lda #2
  jsr _delay_ms
  lda #CMD_CLEAR_DISPLAY
  jsr cmdwrite4
  lda #2
  jsr _delay_ms

  pla
  rts


_lcd_print:
  pha
  phy

  ldy #0
@lcd_print_loop:
  lda (lcd_out_ptr),y
  beq @lcd_print_end
  jsr datawrite
  iny
  jmp @lcd_print_loop
@lcd_print_end:
  ply
  pla
  rts



EN = %00010000
RS = %00100000

cmdwrite8:

  lsr
  lsr
  lsr
  lsr

  AND #$DF

  ora #EN
  sta VIA1_ORA
  ;eor #EN
  AND #$EF
  sta VIA1_ORA

  rts

cmdwrite4:

  pha ; save A
  
  lsr ; shift right
  lsr ; shift right
  lsr ; shift right
  lsr ; shift right

  AND #$DF ; 1101 1111 set RS = 0 

  ora #EN   ; add enable
  sta VIA1_ORA
  ;eor #EN
  AND #$EF  ; remove enable
  sta VIA1_ORA

  pla    ; restore A

  AND #$DF

  ora #EN
  sta VIA1_ORA
  ;eor #EN
  AND #$EF
  sta VIA1_ORA

  rts

datawrite:
  pha
  
  lsr
  lsr
  lsr
  lsr

  ora #(RS | EN)
  sta VIA1_ORA
  ;eor #EN
  AND #$EF
  sta VIA1_ORA

  pla

  ora #(RS | EN)
  sta VIA1_ORA
  ;eor #EN
  AND #$EF
  sta VIA1_ORA

  rts