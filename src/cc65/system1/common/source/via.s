

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

  ; PB0 & PB1 are PS2
  ; PB3 - PB6 is for SPI
  ; PB7 - unusded
  lda #(SPI_CLK | SPI_MOSI | SPI_CS_SD | SPI_CS_RTC)
  sta VIA2_DDRB

  rts