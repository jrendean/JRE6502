

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
  jsr led_on
  rti


RESET:

  cld
  sei

  ldx #$ff
  txs

  jsr led_init

  jsr lcd_init
  loadptr lcd_out_ptr, lcd_message
  jsr lcd_print_string

  jsr console_init
  loadptr console_out_ptr, terminal_message
  jsr console_write_string




loop:

  ;jsr led_flash
  ;lda #$FA
  ;jsr delay_ms
  jmp loop


  .org $FFFA
  .word NMI
  .word RESET
  .word IRQ