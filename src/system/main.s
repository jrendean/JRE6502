

  .org $8000

  .include "lcd.s"
  .include "led.s"
  .include "console.s"
  .include "macros.inc"


lcd_message: .asciiz "Welcome>"
terminal_message: .byte $0A, "Terminal ready>", $00

NMI:
  rti


IRQ:
  jsr _led_on
  rti


RESET:

  cld
  sei

  ldx #$ff
  txs

  jsr _led_init

  jsr _lcd_init
  loadptr lcd_out_ptr, lcd_message
  jsr _lcd_print_string

  jsr _console_init
  loadptr console_out_ptr, terminal_message
  jsr _console_write_string



loop:
  jmp loop


  .org $FFFA
  .word NMI
  .word RESET
  .word IRQ