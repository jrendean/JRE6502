

.include "io.inc"

.import spi_readbyte, spi_writebyte, spi_waitresult

.export rtc_init, rtc_gettime, rtc_settime

rtc_init:


  lda #rtc_write | rtc_control
  jsr spi_writebyte
  lda #$00 ; disable INT0, INT1, WP (Write Protect)
  jsr spi_writebyte

  rts



rtc_gettime:
  pha
  
  lda #SPI_MOSI           ; pull CS low to begin command
  sta VIA2_PORTB

  pla
  ;lda #$00
  jsr spi_writebyte

  ;jsr spi_readbyte
  pha

  ; Debug print the result code
  ;jsr print_hex

  ; End command
  lda #SPI_CS_RTC | SPI_MOSI   ; set CS high again
  sta VIA2_PORTB

  pla   ; restore result code

  rts



rtc_settime:
  pha
  
  lda #SPI_MOSI           ; pull CS low to begin command
  sta VIA2_PORTB

  lda #rtc_write | $02
  jsr spi_writebyte

  pla
  jsr spi_writebyte
  pha

  ; Debug print the result code
  ;jsr print_hex

  ; End command
  lda #SPI_CS_RTC | SPI_MOSI   ; set CS high again
  sta VIA2_PORTB

  pla   ; restore result code

  rts



.rodata
  rtc_read = $00
  rtc_write = $80
  rtc_control = $0F
  rtc_nvram = $20