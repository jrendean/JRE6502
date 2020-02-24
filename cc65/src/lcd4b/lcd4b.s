    .setcpu "65C02"
    .include "lcd.inc"

    .import _delay_ms

    ; define vector
    .segment "VECTORS" ;defined in firmware.cfg starting at $7FFA

    .word   $EAEA      ; $FFFA-$FFFB - MNI
    .word   init       ; $FFFC-$FFFD - Reset
    .word   $EAEA      ; $FFFE-$FFFF - IRQ/BRK


    ; define code
    .segment "CODE" ; could instead use shortcut .code

EN = %00010000
RS = %00100000

init:
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


displaymessage:
  ldx #0
@displaymessageloop:
  lda message,x
  cmp #0
  beq loop
  jsr datawrite
  inx
  jmp @displaymessageloop

loop:
  jmp loop



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

    .segment "RODATA"

message:
  .byte "Line 1 -- 0123456789Line 2 -- 0123456789Line 3 -- 0123456789Line 4 -- 0123456789", $0
