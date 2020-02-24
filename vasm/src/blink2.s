ROM_START = $8000
RESET_VECTOR = $fffc

PORTB = $6000
DDRB = $6002

  .org ROM_START

reset:
  lda #%11111111
  sta DDRB

  lda #$50
  sta PORTB

loop:
  ror
  sta PORTB

  jmp loop

  .org RESET_VECTOR
  .word reset
  .word ROM_START
