

;
;
;
  .org $FFFA
  .word NMI
  .word RESET
  .word IRQ


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
  BIT   VIA2_T1C_L ; Turn off interrupt early  (as discussed above).
  INC   CNT      ; Increment low byte of variable.
  BNE   .isr1    ; Branch to end if the low byte didn't roll over to 00.
  INC   CNT+1    ; Otherwise increment high byte of variable also.
.isr1:  RTI            ; Exit the ISR, restoring the previous processor status.
  ;rti


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
  ;jsr primm_console
  ;.byte $1B,'[','2','J',$00
  loadptr console_out_ptr, terminal_message
  jsr console_write_string


TMR_SETUP: 
  STZ  CNT         ; Initialize the count that will be incremented by
  STZ  CNT+1       ; the ISR at every time-out of T1.
  ;LDA  #$4E         ; Put $C34E (50,000-2) in the VIA's timer 1 counter
  ;STA  VIA2_T1C_L    ; low and high bytes.  Note:  you must write to the
  ;LDA  #$C3        ; counters to get T1 going.  After that, you can
  ;STA  VIA2_T1C_H    ; write to the latches.  $C34E will make T1 time out
                  ; 100 times per second at 5MHz.
  ;LDA  VIA2_ACR     ; Clear the ACR's bit that
  ;AND  #%01111111  ; tells T1 to toggle PB7 upon time-out, and
  ;ORA  #%01000000  ; set the bit that tells T1 to automatically
  ;STA  VIA2_ACR     ; produce an interrupt at every time-out and
                  ; just reload from the latches and keep going.
  ;LDA  #%11000000
  ;STA  VIA2_IER     ; Enable the T1 interrupt in the VIA.
  ;CLI



  ;lda #14
  ;jsr lcd_print_hex
  ;jsr lcd_print_char
  ;jsr convert_to_dec
  ;jsr lcd_print_char


loop:

  ;;loadptr console_out_ptr, CNT
  ;;copyptr CNT, console_out_ptr
  ;;jsr console_write_string
  ;lda CNT+1
  ;jsr console_write_hex
  ;lda CNT
  ;jsr console_write_hex
  ;lda #$0D
  ;jsr console_write_byte
  



  copyptr console_buffer, ptr1
  lda #BUFFLEN
  jsr console_read_string



  jsr lcd_clear



  copyptr console_buffer, ptr1
  loadptr ptr2, cmd_on
  jsr str_compare
  cmp #$00
  beq .on

  copyptr console_buffer, ptr1
  loadptr ptr2, cmd_off
  jsr str_compare
  cmp #$00
  beq .off

  jsr primm_lcd
  .asciiz " Unknown "
  bra loop

.on:
  jsr led_on
  jsr primm_lcd
  .asciiz " LED On "
  bra loop

.off:
  jsr primm_lcd
  .asciiz " LED Off "
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