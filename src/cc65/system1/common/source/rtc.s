

.include "io.inc"
.include "zeropage.inc"

;
; https://bitbucket.org/steckschwein/steckschwein-code/src/master/steckos/libsrc/ds1306/rtc.s
;

.import spi_select_device, spi_deselect, spi_r_byte, spi_rw_byte

.export rtc_init, rtc_systime_update
.export rtc_settime

;----------------------------------------------------------------------------
; last known timestamp with date set to 1970-01-01
;rtc_systime_t = $0300

; read rtc
rtc_read = $00
rtc_write = $80

rtc_ctrlreg = $0F

.code

  ; out:
  ;    Z=1 spi for rtc could be selected (not busy), Z=0 otherwise
  rtc_init:
    ; Select SPI SS for RTC
    lda #spi_device_rtc
    jsr spi_select_device

    ; disable RTC interrupts
    lda #rtc_write | rtc_ctrlreg
    jsr spi_rw_byte
    lda #$00 ; disable INT0, INT1, WP (Write Protect)
    ; this is super noisy
    ;lda #4 ; output 1hz signal

    jsr spi_rw_byte

    jsr spi_deselect

    jmp rtc_systime_update

    rts




  rtc_settime:
    lda #spi_device_rtc
    jsr spi_select_device
    
    lda #rtc_write
    jsr spi_rw_byte
    
    ;; all bcd

    ; second
    lda #00
    jsr spi_rw_byte
    
    ; minute
    lda #%00001010
    jsr spi_rw_byte

    ; hour
    lda #%00001000
    jsr spi_rw_byte

    ; day of the week
    lda #2
    jsr spi_rw_byte

    ; date
    lda #%00100111
    jsr spi_rw_byte

    ; month
    lda #%00000100
    jsr spi_rw_byte

    ; year
    lda #%00100001
    jsr spi_rw_byte

    jsr spi_deselect

  rts




  ;in:
  ;  -
  ;out:
  ;  - rtc_systime_t updated
  rtc_systime_update:
    lda #spi_device_rtc
    jsr spi_select_device
    beq @continue
    ; cannot select device
    rts

  @continue:
    lda #0            ;0 means rtc read, start from first address (seconds)
    jsr spi_rw_byte

    jsr spi_r_byte    ;seconds
    jsr BCD2dec
    sta rtc_systime_t+time_t::tm_sec

    jsr spi_r_byte    ;minute
    jsr BCD2dec
    sta rtc_systime_t+time_t::tm_min

    jsr spi_r_byte    ;hour
    jsr BCD2dec
    sta rtc_systime_t+time_t::tm_hour

    jsr spi_r_byte    ;week day
    sta rtc_systime_t+time_t::tm_wday

    jsr spi_r_byte    ;day of month
    jsr BCD2dec
    sta rtc_systime_t+time_t::tm_mday

    jsr spi_r_byte    ;month
    jsr BCD2dec
    sta rtc_systime_t+time_t::tm_mon

    jsr spi_r_byte    ;year
    jsr BCD2dec
    sta rtc_systime_t+time_t::tm_year


    jsr spi_deselect

    sec
    rts


  ; dec = (((BCD>>4)*10) + (BCD&0xf))
  BCD2dec:
    tax
    and #%00001111
    sta tmp1
    txa
    and #%11110000        ; highbyte => 10a = 8a + 2a
    lsr                     ; 2a
    sta tmp2
    lsr                      ;
    lsr                      ; 8a
    adc tmp2      ; = *10
    adc tmp1
    rts
