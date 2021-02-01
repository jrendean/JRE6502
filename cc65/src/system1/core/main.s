.setcpu "65C02"

.include "zeropage.inc"
;.include "rtc.inc"
.include "io.inc"
.include "macros.inc"

.import delay_ms, convert_to_hex, str_length, str_trim, str_compare, primm_console, primm_lcd
.import led_init, led_on, led_off, led_flash
.import lcd_init, lcd_clear, lcd_goto, lcd_print_string, lcd_print_char, lcd_print_hex
.import console_init, console_write_string, console_write_byte, console_read_byte, console_read_string, console_write_hex, console_write_newline
.import dump_registers, dump_memory, jump_memory, write_memory
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
    ;jsr led_flash
    
    ;bit ACIA1_STATUS
    ;bpl check_via1
    ;jsr _handle_acia_irq

  check_via1:
    BIT   VIA2_T1C_L ; Turn off interrupt early  (as discussed above).
    INC   CNT      ; Increment low byte of variable.
    BNE   @isr1    ; Branch to end if the low byte didn't roll over to 00.
    INC   CNT+1    ; Otherwise increment high byte of variable also.
  @isr1:  RTI            ; Exit the ISR, restoring the previous processor status.
    ;rti



  reset:
    cld
    sei
    ldx #$ff
    txs


    ; init led
    jsr led_init
    jsr led_flash

    ; init lcd
    jsr lcd_init
    ; print welcome mesage
    loadptr lcd_message, lcd_out_ptr
    jsr lcd_print_string

    ; init serial console
    jsr console_init
    jsr console_write_newline
    jsr console_write_newline



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




  loop:

    ; print welcome message
    loadptr terminal_message, console_out_ptr
    jsr console_write_string

  ;lda CNT+1
  ;jsr console_write_hex
  ;lda CNT
  ;jsr console_write_hex
  ;lda #$0D
  ;jsr console_write_byte
  

;  loop:


  
  loadptr console_buffer, ptr1
  lda #BUFFLEN
  jsr console_read_string


  jsr lcd_clear



  ;loadptr console_buffer, ptr1

  lda console_buffer
  bne @actual_command
  jmp loop

@actual_command:
  loadptr cmd_on, ptr2
  jsr str_compare
  cmp #$00
  beq @on

  loadptr cmd_off, ptr2
  jsr str_compare
  cmp #$00
  beq @off

  loadptr cmd_xmodem, ptr2
  jsr str_compare
  cmp #$00
  beq @xmodem

  loadptr cmd_dump, ptr2
  jsr str_compare
  cmp #$00
  beq @dumpreg

  lda console_buffer
  cmp #'m'
  beq @dumpmem

  cmp #'w'
  beq @writemem

  cmp #'j'
  beq @jumpmem

@unknown:
  loadptr unknown_command, console_out_ptr
  jsr console_write_string
  jsr console_write_newline
  loadptr unknown_command, lcd_out_ptr
  jsr lcd_print_string
  jmp loop

@on:
  jsr led_on
  ;jsr primm_lcd
  ;.asciiz " LED On "
  jmp loop

@off:
  jsr led_off
  ;jsr primm_lcd
  ;.asciiz " LED Off "
  jmp loop

@xmodem:
  ;jsr primm_lcd
  ;.asciiz " XMODEM "
  jsr modem_receive
  jsr $1000
  jmp loop

@dumpreg:
  ;jsr primm_lcd
  ;.asciiz " DUMP "
  jsr dump_registers
  jmp loop

@dumpmem:
  ;loadptr console_buffer + 2, ptr1
  jsr dump_memory
  jmp loop

@jumpmem:
  ;loadptr console_buffer + 2, ptr1
  jsr jump_memory
  jmp loop

@writemem:
  ;loadptr console_buffer + 2, ptr1
  jsr write_memory
  jmp loop


  jmp loop




.bss
    BUFFLEN = 20
    console_buffer: .res BUFFLEN + 1, 0

.rodata
    lcd_message: .asciiz "Line A -- A1A2A3A4A5Line B -- B1B2B3B4B5Line C -- C1C2C3C4C5Line D -- D1D2D3D4D5"
    ;lcd_message: .asciiz "Welcome"
    terminal_message: .asciiz "JRE6502>"
    cmd_on: .asciiz "led on"
    cmd_off: .asciiz "off led"
    cmd_xmodem: .asciiz "xmodem"
    cmd_dump: .asciiz "dump"
    cmd_m:.asciiz "m "
    unknown_command: .asciiz "Unknown command"
    
