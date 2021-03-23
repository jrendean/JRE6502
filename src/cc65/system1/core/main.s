.setcpu "65C02"

.include "zeropage.inc"
;.include "rtc.inc"
.include "io.inc"
.include "macros.inc"

.import delay_ms, convert_to_hex, str_length, str_trim, str_compare, primm_console, primm_lcd
.import via_init
.import led_init, led_on, led_off, led_flash
.import lcd_init, lcd_clear, lcd_goto, lcd_print_string, lcd_print_char, lcd_print_hex
.import console_init, console_write_string, console_write_byte, console_read_byte, console_read_string, console_write_hex, console_write_newline
.import dump_registers, dump_memory, jump_memory, write_memory
.import modem_receive
.import KBINIT, KBINPUT, KBSCAN, KBGET
.import spi_readbyte, spi_writebyte, spi_waitresult
.import sdcard_init
.import fat32_init, fat32_openroot, fat32_opendirent, fat32_readdirent, fat32_finddirent, fat32_file_read, fat32_file_readbyte
.import rtc_init, rtc_gettime, rtc_settime

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
    
  is_vi2_timer:
    lda   VIA2_IFR      ; Read the Interrupt Flag Register from VIA1
    and   #$40
    bne   via2_timer1      ; If it's the timer flag then execute timer routine
    
  via2_timer1:
    BIT   VIA2_T1C_L ; Turn off interrupt early  (as discussed above).
    INC   CNT      ; Increment low byte of variable.
    BNE   @via2_timer1_end    ; Branch to end if the low byte didn't roll over to 00.
    INC   CNT+1    ; Otherwise increment high byte of variable also.
  @via2_timer1_end:
    ;ldx #10
    ;ldy #2
    ;jsr lcd_goto
    ;lda CNT+1
    ;jsr lcd_print_hex
    ;lda CNT
    ;jsr lcd_print_hex
  
  @irq_end:
    RTI



  reset:
    cld
    sei
    ldx #$ff
    txs

    jsr initialize

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

  loadptr cmd_kbtest, ptr2
  jsr str_compare
  cmp #$00
  beq @kbtest

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

@kbtest:
    jmp kbtest

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

kbtest:

               jsr   KBINIT            ; init the keyboard, LEDs, and flags
lp0:            jsr   console_write_newline          ; prints 0D 0A (CR LF) to the terminal
lp1:            jsr   KBINPUT           ; wait for a keypress, return decoded ASCII code in A
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
lp2:            jmp loop
               ;rts                     ; done
lp3:            pha                     ; 
               lda   #$3C              ; <
               jsr   console_write_byte            ; 
               pla                     ; 
               jsr   console_write_hex        ; print 1 byte in ascii hex
               lda   #$3E              ; >
               jsr   console_write_byte            ; 
               bra   lp1               ; 


initialize:

  @init_console:
    jsr console_init
  @init_console_success:
    jsr primm_console
    .byte $1B,"[2J",$1B,"[91mJRE6502",$1B,"[0m initializing...",$00
    jsr console_write_newline

  @init_via:
    jsr via_init

  @init_led:
    jsr led_init
    jsr led_flash

  @init_lcd:
    jsr primm_console
    .asciiz "Initializing LCD..."
    jsr lcd_init
    loadptr lcd_message, lcd_out_ptr
    jsr lcd_print_string
  @init_lcd_success:
    loadptr init_complete, console_out_ptr
    jsr console_write_string
    jsr console_write_newline
 
  @init_sdcard:
    jsr primm_console
    .asciiz "Initializing SD card..."
    jsr sdcard_init
    cmp #$00
    beq @init_sdcard_success
  @init_sdcard_failure:
    loadptr init_failed, console_out_ptr
    jsr console_write_string
    jsr console_write_hex
    bra @init_sdcard_done
  @init_sdcard_success:
    loadptr init_complete, console_out_ptr
    jsr console_write_string
  @init_sdcard_done:
    jsr console_write_newline

;jmp @init_rtc_success

  @init_fat32:
    jsr primm_console
    .asciiz "Initializing FAT32 filesystem..."
    jsr fat32_init
    bcc @init_fat32_success
  @init_fat32_failure:
    loadptr init_failed, console_out_ptr
    jsr console_write_string
    lda fat32_errorstage
    jsr console_write_hex
    bra @init_fat32_done
  @init_fat32_success:
    loadptr init_complete, console_out_ptr
    jsr console_write_string
  @init_fat32_done:
    jsr console_write_newline

  @init_rtc:
    jsr primm_console
    .asciiz "Initializing RTC..."
    jsr rtc_init
  @init_rtc_success:
    loadptr init_complete, console_out_ptr
    jsr console_write_string
    jsr console_write_newline


  ;lda #$00
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex
  ;lda #$01
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex
  lda #$02
  jsr console_write_hex
  jsr rtc_gettime
  jsr console_write_hex
  ;lda #$03
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex
  ;lda #$04
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex
  ;lda #$05
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex
  ;lda #$06
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex
  ;lda #$07
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex
  ;lda #$08
  ;jsr console_write_hex
  ;;jsr rtc_gettime
  ;jsr console_write_hex
  ;lda #$09
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex
  ;lda #$0A
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex
  ;lda #$0B
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex
  ;lda #$0C
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex
  ;lda #$0D
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex
  ;lda #$0E
  ;jsr console_write_hex
  ;jsr rtc_gettime
  ;jsr console_write_hex


jsr console_write_newline
lda #$10
jsr rtc_settime
  jsr console_write_hex
  jsr rtc_gettime
  jsr console_write_hex
  

TMR_SETUP: 
  STZ  CNT         ; Initialize the count that will be incremented by
  STZ  CNT+1       ; the ISR at every time-out of T1.
  ;LDA  #$20         ; Put $C34E (50,000-2) in the VIA's timer 1 counter
  ;STA  VIA2_T1C_L    ; low and high bytes.  Note:  you must write to the
  ;LDA  #$4E        ; counters to get T1 going.  After that, you can
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


    jsr primm_console
    .asciiz "Initialization complete"
    jsr console_write_newline
    jsr console_write_newline
    

  rts



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
    cmd_kbtest:.asciiz "kbtest"
    unknown_command: .asciiz "Unknown command"
    init_complete: .byte $1B,"[92mdone",$1B,"[0m",$00
    init_failed:  .byte $1B,"[91m failed - ",$1B,"[0m",$00

