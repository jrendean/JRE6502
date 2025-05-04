

.include "io.inc"

.export via_init

via_init:

  .if lcd_type=20
    ; PA0 LED, PA1 - PA7 LCD
    lda #(PIN_LED | LCD_RS | LCD_RW | LCD_E1 | LCD_D4 | LCD_D5 | LCD_D6 | LCD_D7)
    sta VIA2_DDRA
  .elseif lcd_type=40
    ; still enable led
    lda #PIN_LED
    sta VIA2_DDRA

    ; extra via ports
    lda #(LCD_E2 | LCD_RS | LCD_RW | LCD_E1 | LCD_D4 | LCD_D5 | LCD_D6 | LCD_D7)
    sta VIA1_DDRA
  .endif




  ; P0 and C1 - spi clk
  ; P1 - P4 - select lines
  ; P5 - write protect??
  ; P6 - card detect
  ; P7 - MOSI
  ; C2 - MISO

  ; init shift register and port b for SPI use
  ; SR shift in, External clock on CB1
  lda #%00001100
  sta SPI_ACR

  ; Port b bit 6 and 5 input for sdcard and write protect detection, rest all outputs
  ;lda #%10011111
  ;set 6 to output to test ra8875
  lda #%11011111
  sta SPI_DDR

  ; SPICLK low, MOSI low, SPI_SS HI
  lda #spi_device_deselect
  sta SPI_PORT



  rts