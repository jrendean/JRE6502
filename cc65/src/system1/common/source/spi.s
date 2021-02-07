
.include "io.inc"

.export spi_readbyte, spi_writebyte, spi_waitresult



spi_readbyte:
  ; Enable the card and tick the clock 8 times with MOSI high, 
  ; capturing bits from MISO and returning them

  ldx #8                      ; we'll read 8 bits
@loop:

  lda #SPI_MOSI                ; enable card (CS low), set MOSI (resting state), SCK low
  sta VIA2_PORTB

  lda #SPI_MOSI | SPI_CLK       ; toggle the clock high
  sta VIA2_PORTB

  lda VIA2_PORTB                   ; read next bit
  and #SPI_MISO

  clc                         ; default to clearing the bottom bit
  beq @bitnotset              ; unless MISO was set
  sec                         ; in which case get ready to set the bottom bit
@bitnotset:

  tya                         ; transfer partial result from Y
  rol                         ; rotate carry bit into read result
  tay                         ; save partial result back to Y

  dex                         ; decrement counter
  bne @loop                   ; loop if we need to read more bits

  rts



spi_writebyte:
  ; Tick the clock 8 times with descending bits on MOSI
  ; SD communication is mostly half-duplex so we ignore anything it sends back here

  ldx #8                      ; send 8 bits

@loop:
  asl                         ; shift next bit into carry
  tay                         ; save remaining bits for later

  lda #0
  bcc @sendbit                ; if carry clear, don't set MOSI for this bit
  ora #SPI_MOSI

@sendbit:
  sta VIA2_PORTB                   ; set MOSI (or not) first with SCK low
  eor #SPI_CLK
  sta VIA2_PORTB                   ; raise SCK keeping MOSI the same, to send the bit

  tya                         ; restore remaining bits to send

  dex
  bne @loop                   ; loop if there are more bits to send

  rts



spi_waitresult:
  ; Wait for the SD card to return something other than $ff
  jsr spi_readbyte
  cmp #$ff
  beq spi_waitresult
  rts
