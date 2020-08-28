.setcpu "65C02"

.include "zeropage.inc"
;.include "rtc.inc"
.include "io.inc"
.include "macros.inc"

.import _delay_ms, _convert_to_hex, _str_length, _str_trim, _str_compare, _primm_console, _primm_lcd
.import _led_init, _led_on, _led_off, _led_flash
.import _lcd_init, _lcd_clear, _lcd_goto, _lcd_print_string, _lcd_print_char, _lcd_print_hex
.import _console_init, _console_write_string, _console_write_char, _console_read_char, _console_read_string, _console_write_hex
.import _modem_receive


; define vector
.segment "VECTORS" ;defined in firmware.cfg starting at $7FFA

    .word   nmi     ; $FFFA-$FFFB - MNI
    .word   reset   ; $FFFC-$FFFD - Reset
    .word   irq     ; $FFFE-$FFFF - IRQ/BRK

.code

    nmi:
        rti

    irq:
        jsr _led_on
        rti


    reset:
        cld
        sei

        ldx #$ff
        txs


        ; init led
        jsr _led_init
        ;jsr _led_on

        ; init lcd
        jsr _lcd_init
        ; print welcome mesage
        loadptr lcd_out_ptr, lcd_message
        jsr _lcd_print_string

        ; init serial console
        jsr _console_init
        ; print welcome message
        loadptr console_out_ptr, terminal_message
        jsr _console_write_string




    ;main_loop:
        ;jsr _modem_receive
        ;bcc main_loop
        ;jsr $1000
        ;jmp main_loop

        ;jsr _primm_console
        ;.asciiz " hello "

        ;jsr _primm_console
        ;.asciiz " world !"
        
 
        ;cli



    loop:
        ;jsr _console_read_char
    loadptr lcd_out_ptr, _console_buffer
        jsr _lcd_print_string
        ;sta console_out_ptr
        ;jsr _console_write_char

        ;sta lcd_out_ptr
        ;jsr _lcd_print_char


        loadptr ptr1, _console_buffer
        lda #BUFFLEN
        jsr _console_read_string

        ;;loadptr console_out_ptr, _console_buffer
        ;;jsr _console_write_string

        loadptr lcd_out_ptr, _console_buffer
        jsr _lcd_print_string

        
        ;loadptr ptr1, _console_buffer
        ;jsr _str_length
        ;jsr _console_write_hex

        loadptr ptr1, _console_buffer
        loadptr ptr2, cmd_on
        jsr _str_compare
        beq @on
        loadptr ptr1, _console_buffer
        loadptr ptr2, cmd_off
        jsr _str_compare
        beq @off
        jsr _primm_lcd
        .asciiz "Unknown "
        jsr _led_flash
        bra loop
    @on:
        jsr _led_on
        jsr _primm_lcd
        .asciiz "LED On "
        bra loop
    @off:
        jsr _primm_lcd
        .asciiz "LED Off "
        jsr _led_off


        ;jsr __rtc_systime_update
        ;lda rtc_systime_t+time_t::tm_sec
        ;sta console_out_ptr
        ;jsr _console_write_char

        jmp loop


.bss
    BUFFLEN = 16
    _console_buffer: .res BUFFLEN

.rodata
    ;lcd_message: .byte "Line A -- A1A2A3A4A5Line B -- B1B2B3B4B5Line C -- C1C2C3C4C5Line D -- D1D2D3D4D5", 0
    ;lcd_message: .byte "Line A -- A1A2A3A4A5Line B -- B1B2B3B4B5Line C -- C1C2C3C4C5Line D -- D1D2D3D4D", 0
    lcd_message: .asciiz "Welcome>"
    terminal_message: .byte $0A, "Terminal ready>", $00
    cmd_on: .asciiz "led on"
    cmd_off: .asciiz "off led"
    cmd_unknown: .asciiz "unknown"

