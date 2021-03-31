.setcpu "65C02"

.import KBINIT, KBINPUT
.import console_write_newline, console_write_byte, console_write_hex

  kbtest:
    jsr   KBINIT            ; init the keyboard, LEDs, and flags
  lp0:
    jsr   console_write_newline          ; prints 0D 0A (CR LF) to the terminal
  lp1:
    jsr   KBINPUT           ; wait for a keypress, return decoded ASCII code in A
    cmp   #$0d              ; if CR, then print CR LF to terminal
    beq   lp0               ; 
    cmp   #$1B              ; esc ascii code
    beq   lp2               ; 
    cmp   #$20              ; 
    bcc   lp3               ; control key, print as <hh> except $0d (CR) & $2B (Esc)
    cmp   #$80              ; 
    bcs   lp3               ; extended key, just print the hex ascii code as <hh>
    jsr   console_write_byte            ; prints contents of A reg to the Terminal, ascii 20-7F
    bra   lp1               ; 
lp2:
    rts                     ; done
lp3:
    pha                     ; 
    lda   #$3C              ; <
    jsr   console_write_byte            ; 
    pla                     ; 
    jsr   console_write_hex        ; print 1 byte in ascii hex
    lda   #$3E              ; >
    jsr   console_write_byte            ; 
    bra   lp1               ; 
