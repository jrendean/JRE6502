.include "io.inc"
.include "zeropage.inc"

.import joystick_scan, console_write_byte

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