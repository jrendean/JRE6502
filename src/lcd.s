PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

EN  = %10000000
RW = %01000000
RS = %00100000

  .org $8000

outcmd:
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #EN         ; Set E bit to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  rts

outdata:
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | EN)   ; Set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts

reset:
  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%11100000 ; Set top 3 pins on port A to output
  sta DDRA

  ; Function Set
  ;     001DLNFXX
  ;        DL - Data length 1=8bit, 0=4bit
  ;          N  - Number of lines
  ;           F - Font 
  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  jsr outcmd
  
  ; Display Set
  ;     00001DCB
  ;          D - Display 1=on, 0=off
  ;           C - Cursor 1=on, 0=off
  ;             B - Blink cursor 1=on, 0=off
  lda #%00001110 ; Display on; cursor on; blink off
  jsr outcmd
  
  ; Entry Mode
  ;     000001IDS
  ;           ID - Inc or Dec 1=Inc, 0=Dec
  ;             S - Shift display 1=with ID, 0=dont shift
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr outcmd


  ldx #0
displaymessage:
  lda message,x
  beq loop
  jsr outdata
  inx
  jmp displaymessage

loop:
  jmp loop

message:
  .string "Hi World!"

  .org $fffc
  .word reset
  .word $0000