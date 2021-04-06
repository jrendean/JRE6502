

.include "io.inc"
.include "zeropage.inc"

;
; https://bitbucket.org/steckschwein/steckschwein-code/src/master/steckos/libsrc/ds1306/rtc.s
;

.import spi_select_device, spi_deselect, spi_r_byte, spi_rw_byte

;.export spi_select_rtc
.export rtc_settime
.export rtc_systime_update
.export rtc_init

;----------------------------------------------------------------------------
; last known timestamp with date set to 1970-01-01
;rtc_systime_t = $0300

; read rtc
rtc_read = 0
rtc_write = $80

rtc_ctrlreg = $0f


.code

; ; out:
; ;    Z=1 spi for rtc could be selected (not busy), Z=0 otherwise
; spi_select_rtc:
;    lda #spi_device_rtc
;    jmp spi_select_device



rtc_init:
    ; disable RTC interrupts
    ; Select SPI SS for RTC
    lda #spi_device_rtc
    jsr spi_select_device
    lda #rtc_write | rtc_ctrlreg
    jsr spi_rw_byte
    lda #$00 ; disable INT0, INT1, WP (Write Protect)
    jsr spi_rw_byte
    jsr spi_deselect

    jmp rtc_systime_update

    rts



rtc_settime:
    lda #spi_device_rtc
    jsr spi_select_device
    
  lda #rtc_write
  jsr spi_rw_byte
  
  ; second
  lda #00
  jsr spi_rw_byte
  
  ; minute
  lda #%00100001
  jsr spi_rw_byte

  ; hour
  lda #%00100000
  jsr spi_rw_byte

  ; day of the week
  lda #7
  jsr spi_rw_byte

  ; date
  lda #4
  jsr spi_rw_byte

  ; month
  lda #4
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
    beq :+
    rts
:    ;debug "update systime"
    lda #0                ;0 means rtc read, start from first address (seconds)
    jsr spi_rw_byte

    jsr spi_r_byte      ;seconds
    jsr BCD2dec
    sta rtc_systime_t+time_t::tm_sec

    jsr spi_r_byte      ;minute
    jsr BCD2dec
    sta rtc_systime_t+time_t::tm_min

    jsr spi_r_byte      ;hour
    jsr BCD2dec
    sta rtc_systime_t+time_t::tm_hour

    jsr spi_r_byte      ;week day
    sta rtc_systime_t+time_t::tm_wday

    jsr spi_r_byte                          ;day of month
    jsr BCD2dec
    sta rtc_systime_t+time_t::tm_mday

    jsr spi_r_byte                          ;month
    ;dec                                        ;dc1306 gives 1-12, but 0-11 expected
    jsr BCD2dec
    sta rtc_systime_t+time_t::tm_mon

    jsr spi_r_byte                        ;year value - rtc year 2000+year register
    jsr BCD2dec
    ;clc
    ;adc #100                                ;time_t year starts from 1900
    sta rtc_systime_t+time_t::tm_year
    ;debug32 "rtc0", rtc_systime_t
    ;debug32 "rtc1", rtc_systime_t+4
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


