ROM_START = $8100
RESET_VECTOR = $fffc
FILL_START = $8000

PORTA = $8001
DDRA = $8003

EN = %00010000
RS = %00100000

  .org FILL_START

  .org ROM_START

cmdwrite8:

  lsr
  lsr
  lsr
  lsr

  AND #$DF

  ora #EN
  sta PORTA
  jsr delay
  ;eor #EN
  AND #$EF
  sta PORTA

  rts

cmdwrite4:

  pha ; save A
  
  lsr ; shift right
  lsr ; shift right
  lsr ; shift right
  lsr ; shift right

  AND #$DF ; 1101 1111 set RS = 0 

  ora #EN   ; add enable
  sta PORTA
  jsr delay
  ;eor #EN
  AND #$EF  ; remove enable
  sta PORTA

  pla    ; restore A

  AND #$DF

  ora #EN
  sta PORTA
  jsr delay
  ;eor #EN
  AND #$EF
  sta PORTA

  rts

datawrite:
  pha
  
  lsr
  lsr
  lsr
  lsr

  ora #RS
  ora #EN
  sta PORTA
  jsr delay
  ;eor #EN
  AND #$EF
  sta PORTA

  pla

  ora #RS
  ora #EN
  sta PORTA
  jsr delay
  ;eor #EN
  AND #$EF
  sta PORTA

  rts


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


reset:
  lda #%11111111 ; Set all pins on port B to output
  sta DDRA

  ; https://en.wikipedia.org/wiki/Hitachi_HD44780_LCD_controller
  ;3x force to 8bit - 0011 0000 (8bit write)
  lda #%00110000
  jsr cmdwrite8
  lda #%00110000
  jsr cmdwrite8
  lda #%00110000
  jsr cmdwrite8
  ;set to 4bit - 0010 0000 (8bit write)
  lda #%00100000
  jsr cmdwrite8


  ; Function Set - set to 4bit, 2line, 5x8 dots - 0010 1000
  lda #%00101000
  jsr cmdwrite4

  ; Display Control - display on, cursor on, blink off - 0000 1110
  lda #%00001110
  jsr cmdwrite4

  ; Clear Display Control
  lda #%00000001
  jsr cmdwrite4

  ; Entry Mode - Increment on, shift off - 0000 0110 
  lda #%00000110
  jsr cmdwrite4



  ldy #0
displaymessage:
  lda message,y
  cmp #0
  beq loop
  jsr datawrite
  iny
  jmp displaymessage


loop:
  jmp loop

message:
  .string "Line 1 -- 0123456789Line 2 -- 0123456789Line 3 -- 0123456789Line 4 -- 0123456789"

  .org RESET_VECTOR
  .word reset
  .word ROM_START
