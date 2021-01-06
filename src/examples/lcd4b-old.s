PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

EN  = %10000000
RW = %01000000
RS = %00100000

  .org $8000

delay:
  pha
  txa
  pha
  tya

  ldy #0
innerdelay:
  nop
  nop
  nop
  nop
  cpy #216
  bne innerdelay

  pla
  tay
  pla
  tax
  pla

  rts

cmdwrite:
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #EN        ; Set EN bit to send instruction
  sta PORTA
  jsr delay
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  jsr delay
  rts

datawrite:
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #EN        ; Set EN bit to send instruction
  sta PORTA
  jsr delay
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  jsr delay
  rts

outcmd8bit:
  and #$0f
  sta PORTB

  jsr cmdwrite
  rts


outcmd4bit:
  and #$0f
  sta PORTB

  jsr cmdwrite
  
  pla
  lsr a
  lsr a
  lsr a
  lsr a
  sta PORTB

  jsr cmdwrite
  rts


outdata4bit:
  pha
  and #$0f
  sta PORTB

  jsr cmdwrite
  
  pla
  lsr a
  lsr a
  lsr a
  lsr a
  sta PORTB

  jsr datawrite
  rts


reset:
  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%11100000 ; Set top 3 pins on port A to output
  sta DDRA

  jsr delay

  ; Send 0011 0000 three times
  lda #%00110000
  jsr outcmd8bit
  lda #%00110000
  jsr outcmd8bit
  lda #%00110000
  jsr outcmd8bit

  ; Function set: 4 bit mode [but sent in 8bit mode]
  ; This is soley to get the LCD into 4 bit mode only
  ; Send 0010 0000
  lda #%00100000
  jsr outcmd8bit

  lda #%00100000
  jsr outcmd4bit

  ; Function Set
  ;     001DLNFXX
  ;        DL - Data length 1=8bit, 0=4bit
  ;          N  - Number of lines
  ;           F - Font 
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr outcmd4bit
  
  ; Display Set
  ;     00001DCB
  ;          D - Display 1=on, 0=off
  ;           C - Cursor 1=on, 0=off
  ;             B - Blink cursor 1=on, 0=off
  lda #%00001110 ; Display on; cursor on; blink off
  jsr outcmd4bit
  
  ; Entry Mode
  ;     000001IDS
  ;           ID - Inc or Dec 1=Inc, 0=Dec
  ;             S - Shift display 1=with ID, 0=dont shift
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr outcmd4bit


  ldx #0
displaymessage:
  lda message,x
  beq loop
  jsr outdata4bit
  inx
  jmp displaymessage

loop:
  jmp loop

message:
  .string "Hi 4bit World!"

  .org $fffc
  .word reset
  .word $0000