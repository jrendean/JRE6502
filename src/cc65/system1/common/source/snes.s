.include "io.inc"
.include "zeropage.inc"

.export joystick_scan, joystick_get
.export joystick_test

.import console_write_byte, console_write_hex, console_write_newline

;
; /---------------------
;| 7  6  5 | 4  3  2  1 |
; \---------------------
;
;Pin Description
;1   +5V
;2  CLK
;3  LATCH
;4  DATA
;5  –
;6  –
;7  GND
;

; https://bitbucket.org/steckschwein/steckschwein-code/src/master/steckos/libsrc/joystick/snes.s
; https://www.pagetable.com/?p=1365
; https://github.com/commanderx16/x16-rom/blob/master/kernal/drivers/x16/joystick.s

joystick_scan:
    lda #$FF-SNES_DATA1-SNES_DATA2
    sta SNES_DDR

    stz SNES_PORT

    ; pulse latch
    lda #SNES_LATCH
    sta SNES_PORT
    stz SNES_PORT

    ; read 3x 8 bits
    ldx #0
  l2:
    ldy #8
  l1:
    lda SNES_PORT
    cmp #SNES_DATA2
    rol controller2,x
    and #SNES_DATA1
    cmp #SNES_DATA1
    rol controller1,x
    lda #SNES_CLK
    sta SNES_PORT
    ;inc SNES_PORT
    stz SNES_PORT

    dey
    bne l1
    inx
    cpx #3
    bne l2
    rts


joystick_get:
  lda controller1
  ldx controller1+1
  ldy controller1+2
  rts


joystick_test:
    jsr joystick_scan
    ;jsr console_write_hex
    ;lda controller1+1
    ;jsr console_write_hex
    ;lda controller1+2
    ;jsr console_write_hex
    rol controller1
    bcs foo1
    lda #'B'
    jsr console_write_byte
foo1:
    rol controller1
    bcs foo2
    lda #'Y'
    jsr console_write_byte
foo2:
    rol controller1
    bcs foo3
    lda #'S'
    jsr console_write_byte
foo3:
    rol controller1
    bcs foo4
    lda #'T'
    jsr console_write_byte
foo4:
    rol controller1
    bcs foo5
    lda #'U'
    jsr console_write_byte
foo5:
    rol controller1
    bcs foo6
    lda #'D'
    jsr console_write_byte
foo6:
    rol controller1
    bcs foo7
    lda #'L'
    jsr console_write_byte
foo7:
    rol controller1
    bcs foo8
    lda #'R'
    jsr console_write_byte
foo8:
    rol controller1+1
    bcs foo9
    lda #'A'
    jsr console_write_byte
foo9:
    rol controller1+1
    bcs foo10
    lda #'X'
    jsr console_write_byte
foo10:
    rol controller1+1
    bcs foo11
    lda #'l'
    jsr console_write_byte
foo11:
    rol controller1+1
    bcs foo12
    lda #'r'
    jsr console_write_byte
foo12:
    jmp joystick_test