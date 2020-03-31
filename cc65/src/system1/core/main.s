.setcpu "65C02"

.include "zeropage.inc"
.include "rtc.inc"
.include "io.inc"

.import _delay_ms, _convert_to_hex
.import _led_init, _led_on, _led_off, _led_flash
.import _lcd_init, _lcd_clear, _lcd_goto, _lcd_print_string, _lcd_print_char
.import _console_init, _console_write_string, _console_write_char, _console_read_char


.import spi_r_byte, spi_rw_byte, spi_deselect, spi_select_rtc
.import init_rtc, rtc_systime, __rtc_systime_update
.import sdcard_init, sd_read_block, sd_write_block


; define vector
.segment "VECTORS" ;defined in firmware.cfg starting at $7FFA

    .word   nmi     ; $FFFA-$FFFB - MNI
    .word   reset   ; $FFFC-$FFFD - Reset
    .word   irq     ; $FFFE-$FFFF - IRQ/BRK

.code
    nmi:
        rti

    irq:
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
        lda #<lcd_message
        sta lcd_out_ptr
        lda #>lcd_message
        sta lcd_out_ptr + 1
        jsr _lcd_print_string

        ; init serial console
        jsr _console_init
        ;; print welcome message
        lda #<terminal_message
        sta console_out_ptr
        lda #>terminal_message
        sta console_out_ptr + 1
        jsr _console_write_string

        ;cli


        ; Port b bit 6 and 5 input for sdcard and write protect detection, rest all outputs
        ;lda #%10011111
        ;sta VIA2_DDRB

        ; SPICLK low, MOSI low, SPI_SS HI
        ;lda #%01111110
        ;sta VIA2_DDRB

        ;jsr init_rtc
        ;jsr spi_select_rtc
        ;lda #$80
        ;jsr spi_rw_byte
        ;lda #0
        ;jsr spi_rw_byte
        ;lda #$81
        ;jsr spi_rw_byte
        ;lda #0
        ;jsr spi_rw_byte
        ;lda #$82
        ;jsr spi_rw_byte
        ;lda #0
        ;jsr spi_rw_byte
        ;jsr rtc_systime


    loop:
        jsr _console_read_char

        sta console_out_ptr
        jsr _console_write_char

        sta lcd_out_ptr
        jsr _lcd_print_char

        ;jsr __rtc_systime_update
        ;lda rtc_systime_t+time_t::tm_sec
        ;sta console_out_ptr
        ;jsr _console_write_char

        jmp loop


.rodata
    ;lcd_message: .byte "Line A -- A1A2A3A4A5Line B -- B1B2B3B4B5Line C -- C1C2C3C4C5Line D -- D1D2D3D4D5", 0
    lcd_message: .byte "Line A -- A1A2A3A4A5Line B -- B1B2B3B4B5Line C -- C1C2C3C4C5Line D -- D1D2D3D4D", 0
    terminal_message: .byte $0A, "Terminal ready>", 0
