.setcpu "65C02"

.include "zeropage.inc"
.include "io.inc"
.include "macros.inc"

.import delay_ms, convert_to_hex, str_length, str_trim, str_compare, primm_console, primm_lcd
.import via_init
.import led_init, led_on, led_off, led_flash
.import lcd_init, lcd_clear, lcd_goto, lcd_print_string, lcd_print_char, lcd_print_hex
.import console_init, console_write_string, console_write_byte, console_read_byte, console_read_string, console_write_hex, console_write_newline
.import debugger_run
.import modem_receive
.import KBINIT, KBINPUT, KBSCAN, KBGET
.import sdcard_init, sdcard_detect
.import fat32_init, fat32_openroot, fat32_opendirent, fat32_readdirent, fat32_finddirent, fat32_file_read, fat32_file_readbyte
.import rtc_init, rtc_settime, rtc_systime_update
.import mem_clear
.import joystick_scan, joystick_get, joystick_test
;.import ra8875_init, ra8875_writetext

.import b2ad

; define vector
.segment "VECTORS" ;defined in firmware.cfg starting at $FFFA

    .word   nmi     ; $FFFA-$FFFB - MNI
    .word   reset   ; $FFFC-$FFFD - Reset
    .word   irq     ; $FFFE-$FFFF - IRQ/BRK

.code


  nmi:
      rti


  ; http://wilsonminesco.com/6502interrupts/index.html
  irq:
      pha
      phx
      phy

      bit  VIA1_IFR   ; Check 6522 VIA1's status register without loading.
      bmi  @service_via1  ; If it caused the interrupt, branch to service it.
      bit  VIA2_IFR   ; Otherwise, check VIA2's status register.
      bmi  @service_via2
      jmp @irq_done

    @service_via1:
      BIT   VIA1_T1CL
      jsr joystick_scan
    @service_via2:
      BIT   VIA2_T1CL
      ;jsr led_flash
      ;jsr joystick_scan

    @irq_done:
      ply
      plx
      pla

      rti



  reset:
      cld         ; clear decimal (use hex)

      sei         ; set interupt disable (do not take interupts)

      ldx #$00    ; clear the zero page and stack
    : stz $0000,x ;zero page
      stz $0100,x ;user buffers and vars
      inx
      bne :-

      ldx #$ff    ; load FF in to X register
      txs         ; set the stack pointer to the top (00FF)

      jsr initialize

      cli         ; clear interupt disable (start taking interupts)





  loop:

      ; print welcome message
      loadptr terminal_message, console_out_ptr
      jsr console_write_string



      loadptr console_buffer, ptr1
      lda #BUFFLEN
      jsr console_read_string


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

      loadptr cmd_kbtest, ptr2
      jsr str_compare
      cmp #$00
      beq @kbtest

      loadptr cmd_debugger, ptr2
      jsr str_compare
      cmp #$00
      beq @debugger


      lda console_buffer
      cmp #'s'
      beq @snes

      cmp #'t'
      beq @time

      ;cmp #'y'
      ;jsr rtc_settime

      ;cmp #'h'
      ;beq @ra8875

    @unknown:
      loadptr unknown_command, console_out_ptr
      jsr console_write_string
      jsr console_write_newline
      jmp loop

    @on:
      jsr led_on
      jmp loop

    @off:
      jsr led_off
      jmp loop

    @xmodem:
      jsr modem_receive
      jsr $1000
      jmp loop

    @kbtest:
      jmp kbtest
      jmp loop

    @debugger:
      jsr debugger_run
      jmp loop

    @snes:
      ;;jsr joystick_test
      ;jsr joystick_get
      ;phy
      ;phx
      ;jsr console_write_hex
      ;jsr console_write_newline
      ;pla
      ;jsr console_write_hex
      ;jsr console_write_newline
      ;pla
      ;jsr console_write_hex
      ;jsr console_write_newline
      ;jmp loop

      jsr joystick_test
      jmp loop
     




    @time:
      jsr rtc_systime_update
      jsr console_write_newline
      lda rtc_systime_t+time_t::tm_hour
      jsr b2ad
      lda #':'
      jsr console_write_byte
      lda rtc_systime_t+time_t::tm_min
      jsr b2ad
      lda #':'
      jsr console_write_byte
      lda rtc_systime_t+time_t::tm_sec
      jsr b2ad
      lda #' '
      jsr console_write_byte
      lda rtc_systime_t+time_t::tm_mon
      jsr b2ad
      lda #'/'
      jsr console_write_byte
      lda rtc_systime_t+time_t::tm_mday
      jsr b2ad
      lda #'/'
      jsr console_write_byte
      lda rtc_systime_t+time_t::tm_year
      jsr b2ad
      jsr console_write_newline
      jmp loop

    ; @ra8875:
    ;   loadptr terminal_message, ra8875_out_ptr
    ;   jsr ra8875_writetext
    ;   jmp loop


      jmp loop


      kbtest:
        jsr KBINIT            ; init the keyboard, LEDs, and flags
      lp0:
        jsr console_write_newline          ; prints 0D 0A (CR LF) to the terminal
      lp1:
        jsr KBINPUT           ; wait for a keypress, return decoded ASCII code in A
        cmp #$0d              ; if CR, then print CR LF to terminal
        beq lp0               ; 
        cmp #$1B              ; esc ascii code
        beq lp2               ; 
        cmp #$20              ; 
        bcc lp3               ; control key, print as <hh> except $0d (CR) & $2B (Esc)
        cmp #$80              ; 
        bcs lp3               ; extended key, just print the hex ascii code as <hh>
        jsr console_write_byte            ; prints contents of A reg to the Terminal, ascii 20-7F
        bra lp1               ; 
      lp2:
        jmp loop
        ;rts                     ; done
      lp3:
        pha                     ; 
        lda #$3C              ; <
        jsr console_write_byte            ; 
        pla                   ; 
        jsr console_write_hex        ; print 1 byte in ascii hex
        lda #$3E              ; >
        jsr console_write_byte            ; 
        bra lp1               ; 




  initialize:

    ; zero out all the RAM 
    jsr mem_clear

    ; initialize the console and write out
    jsr console_init
    jsr primm_console
    .byte $1B,"[2J",$1B,"[H",$1B,"[91mJRE6502",$1B,"[0m initializing...",$00
    jsr console_write_newline

    ; initialize the VIAs
    jsr via_init

    ; initialize the LED
    jsr led_init
    jsr led_flash

    ; initialize the LCD
    jsr primm_console
    .asciiz "Initializing LCD..."
    jsr lcd_init
    loadptr lcd_message, lcd_out_ptr
    jsr lcd_print_string
    loadptr init_success, console_out_ptr
    jsr console_write_string
    jsr console_write_newline

    ; initialize the RTC
    @init_rtc:
      jsr primm_console
      .asciiz "Initializing RTC..."
      jsr rtc_init
    @init_rtc_success:
      loadptr init_success, console_out_ptr
      jsr console_write_string
      jsr console_write_newline

    ; initialize the SD Card
    @init_sdcard:
      jsr primm_console
      .asciiz "Initializing SD card..."
      jsr sdcard_init
      beq @init_sdcard_success
    @init_sdcard_failure:
      loadptr init_failed, console_out_ptr
      jsr console_write_string
      jsr console_write_hex
      bra @init_sdcard_done
    @init_sdcard_success:
      loadptr init_success, console_out_ptr
      jsr console_write_string
    @init_sdcard_done:
      jsr console_write_newline


    ; setup timers on VIA1 for interupt processing
    ; http://wilsonminesco.com/6502interrupts/index.html
    lda #$FF        ; put FFFF (65535) in VIA timer 1 counter
    sta VIA1_T1CL   ; this will make the timeout 61 times per
    sta VIA1_T1CH   ; second with the 4mhz clock

    lda VIA1_ACR    ; Clear the ACR's bit that
    and #%01111111  ; tells T1 to toggle PB7 upon time-out, and
    ora #%01000000  ; set the bit that tells T1 to automatically
    sta VIA1_ACR    ; produce an interrupt at every time-out and
                    ; just reload from the latches and keep going.
    lda #%11000000
    sta VIA1_IER    ; Enable the T1 interrupt in the VIA.

    ; initialization complete
    jsr primm_console
    .asciiz "Initialization complete"
    jsr console_write_newline
    jsr console_write_newline

    rts



.bss
    BUFFLEN = 20
    console_buffer: .res BUFFLEN + 1, 0

.rodata
    ;lcd_message: .asciiz "Line A -- A1A2A3A4A5Line B -- B1B2B3B4B5Line C -- C1C2C3C4C5Line D -- D1D2D3D4D5"
    lcd_message: .asciiz "Line A -- A1A2A3A4A5Line B -- B1B2B3B4B5Line C -- C1C2C3C4C5Line D -- D1D2D3D4D5Line E -- A1A2A3A4A5Line F -- B1B2B3B4B5Line G -- C1C2C3C4C5Line H -- D1D2D3D4D"
    ;lcd_message: .asciiz "Welcome"
    terminal_message: .asciiz "JRE6502>"
    cmd_on: .asciiz "led on"
    cmd_off: .asciiz "off led"
    cmd_xmodem: .asciiz "load"
    cmd_debugger: .asciiz "debug"
    cmd_kbtest:.asciiz "kbtest"
    unknown_command: .asciiz "Unknown command"
    init_success: .byte $1B,"[92mdone",$1B,"[0m",$00
    init_failed:  .byte $1B,"[91m failed - ",$1B,"[0m",$00


