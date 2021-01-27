.setcpu "65C02"

.include "zeropage.inc"
;.include "rtc.inc"
.include "io.inc"
.include "macros.inc"

.import delay_ms, convert_to_hex, str_length, str_trim, str_compare, primm_console, primm_lcd
.import led_init, led_on, led_off, led_flash
.import lcd_init, lcd_clear, lcd_goto, lcd_print_string, lcd_print_char, lcd_print_hex
.import console_init, console_write_string, console_write_char, console_read_char, console_read_string, console_write_hex
.import modem_receive


; define vector
.segment "VECTORS" ;defined in firmware.cfg starting at $7FFA

    .word   nmi     ; $FFFA-$FFFB - MNI
    .word   reset   ; $FFFC-$FFFD - Reset
    .word   irq     ; $FFFE-$FFFF - IRQ/BRK

.code

  nmi:
    rti

  irq:
    jsr led_flash
    rti


  reset:
    cld
    sei

    ldx #$ff
    txs


    ; init led
    jsr led_init
    ;jsr _led_on

    ; init lcd
    jsr lcd_init
    ; print welcome mesage
    loadptr lcd_out_ptr, lcd_message
    jsr lcd_print_string

    ; init serial console
    jsr console_init


  loop:

    ; print welcome message
    loadptr console_out_ptr, terminal_message
    jsr console_write_string

;  loop:


  copyptr console_buffer, ptr1
  lda #BUFFLEN
  jsr console_read_string


  jsr lcd_clear



  copyptr console_buffer, ptr1
  loadptr ptr2, cmd_on
  jsr str_compare
  cmp #$00
  beq @on

  copyptr console_buffer, ptr1
  loadptr ptr2, cmd_off
  jsr str_compare
  cmp #$00
  beq @off

  copyptr console_buffer, ptr1
  loadptr ptr2, cmd_xmodem
  jsr str_compare
  cmp #$00
  beq @xmodem

  jsr primm_lcd
  .asciiz " Unknown "
  jmp loop

@on:
  jsr led_on
  jsr primm_lcd
  .asciiz " LED On "
  jmp loop

@off:
  jsr led_off
  jsr primm_lcd
  .asciiz " LED Off "
  jmp loop

@xmodem:
  jsr primm_lcd
  .asciiz " XMODEM "
  jsr modem_receive
  jmp loop


  jmp loop



.bss
    BUFFLEN = 16
    console_buffer: .res BUFFLEN

.rodata
    ;lcd_message: .byte "Line A -- A1A2A3A4A5Line B -- B1B2B3B4B5Line C -- C1C2C3C4C5Line D -- D1D2D3D4D5", 0
    ;lcd_message: .byte "Line A -- A1A2A3A4A5Line B -- B1B2B3B4B5Line C -- C1C2C3C4C5Line D -- D1D2D3D4D", 0
    lcd_message: .asciiz "Welcome>"
    terminal_message: .byte $0A, "Terminal ready>", $00
    cmd_on: .asciiz "led on"
    cmd_off: .asciiz "off led"
    cmd_unknown: .asciiz "unknown"
    cmd_xmodem: .asciiz "xmodem"

