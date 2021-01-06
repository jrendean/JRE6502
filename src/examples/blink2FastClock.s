ROM_START = $8000
RESET_VECTOR = $fffc

;PORTB = $6000
;DDRB = $6002
PORTB = $FE00
DDRB = $FE02

  .org ROM_START

reset:
  lda #%11111111
  sta DDRB

  lda #$50
  sta PORTB

loop:
  ror
  sta PORTB
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


  .org RESET_VECTOR
  .word reset
  ;.word ROM_START
  .word $0000
