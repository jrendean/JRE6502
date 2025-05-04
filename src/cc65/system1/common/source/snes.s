.include "io.inc"
.include "zeropage.inc"

.export joystick_scan, joystick_get
.export joystick_test

.import console_write_byte, console_write_hex, console_write_newline, primm_console
.import delay_ms

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


;----------------------------------------------------------------------
; query_controllers:
;
; byte 0:      | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;         NES  | A | B |SEL|STA|UP |DN |LT |RT |
;         SNES | B | Y |SEL|STA|UP |DN |LT |RT |
;
; byte 1:      | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;         NES  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
;         SNES | A | X | L | R | 1 | 1 | 1 | 1 |
; byte 2:
;         $00 = controller present
;         $FF = controller not present
;
; * Presence can be detected by checking byte 2.
; * NES vs. SNES can be detected by checking bits 0-3 in byte 1.
; * Note that bits 6 and 7 in byte 0 map to different buttons on NES and SNES.
  joystick_get:
    lda controller1
    ldx controller1+1
    ldy controller1+2
    rts


  joystick_test:
      lda controller1+2
      beq @output
      jsr primm_console
      .asciiz "Controller 1 not connected"
      rts

      @output:
      jsr primm_console
      .byte $1B,"[2J",$1B,"[H",$00

      lda controller1
      sta tmp1
      rol tmp1
      bcs @y
      jsr primm_console
      .asciiz "B"
      jsr console_write_newline
      @y:
      rol tmp1
      bcs @sel
      jsr primm_console
      .asciiz "Y"
      jsr console_write_newline
      @sel:
      rol tmp1
      bcs @start
      jsr primm_console
      .asciiz "Select"
      jsr console_write_newline
      @start:
      rol tmp1
      bcs @up
      jsr primm_console
      .asciiz "Start"
      jsr console_write_newline
      @up:
      rol tmp1
      bcs @down
      jsr primm_console
      .asciiz "Up"
      jsr console_write_newline
      @down:
      rol tmp1
      bcs @left
      jsr primm_console
      .asciiz "Down"
      jsr console_write_newline
      @left:
      rol tmp1
      bcs @right
      jsr primm_console
      .asciiz "Left"
      jsr console_write_newline
      @right:
      rol tmp1
      bcs @a
      jsr primm_console
      .asciiz "Right"
      jsr console_write_newline
      @a:
      lda controller1+1
      sta tmp1
      rol tmp1
      bcs @x
      jsr primm_console
      .asciiz "A"
      jsr console_write_newline
      @x:
      rol tmp1
      bcs @lefttrigger
      jsr primm_console
      .asciiz "X"
      jsr console_write_newline
      @lefttrigger:
      rol tmp1
      bcs @righttrigger
      jsr primm_console
      .asciiz "Left Trigger"
      jsr console_write_newline
      @righttrigger:
      rol tmp1
      bcs @done
      jsr primm_console
      .asciiz "Right Trigger"
      jsr console_write_newline

      @done:
      lda #250
      jsr delay_ms

      jmp joystick_test

      rts
