

  .org $8000

  .include "lcd.s"
  .include "led.s"
  .include "console.s"
  .include "macros.inc"


BUFFLEN = 16


NMI:
  rti


IRQ:
  jsr led_flash
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




  lda #14
  jsr lcd_print_hex
  jsr lcd_print_char
  jsr convert_to_dec
  jsr lcd_print_char

  ;jsr primm_lcd
  ;.asciiz "Unknown "

  ;jsr primm_console
  ;.asciiz "Unknown "

loop:

  copyptr console_buffer, ptr2
  lda #BUFFLEN
  jsr console_read_string


  ;copyptr console_buffer, console_out_ptr
  ;jsr console_write_string


  copyptr console_buffer, lcd_out_ptr
  jsr lcd_print_string




  copyptr console_buffer, ptr1
  loadptr ptr2, cmd_on
  jsr str_compare
  cmp $00
  beq .on
  copyptr console_buffer, ptr1
  loadptr ptr2, cmd_off
  jsr str_compare
  cmp $00
  beq .off
  jsr primm_lcd
  .asciiz "Unknown "
  jsr led_flash
  bra loop
.on:
  jsr led_on
  jsr primm_lcd
  .asciiz "LED On "
  bra loop
.off:
  jsr primm_lcd
  .asciiz "LED Off "
  jsr led_off


  jmp loop


;  .section "bss", "uaw"

  console_buffer: .blk BUFFLEN+1


;  .section "rodata","dr"
;.rodata
  lcd_message: .asciiz "Welcome>"
  terminal_message: .byte $0A, "Terminal ready>", $00 ; .byte do need $00 on end
  cmd_on: .asciiz "led on"
  cmd_off: .asciiz "off led"
  cmd_unknown: .asciiz "unknown"


;
;
;
  .org $FFFA
  .word NMI
  .word RESET
  .word IRQ