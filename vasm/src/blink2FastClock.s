ROM_START = $8100
RESET_VECTOR = $fffc
FILL_START = $8000

;PORTB = $6000
;DDRB = $6002
PORTB = $8000
DDRB = $8002

  .org FILL_START

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
