

.include "io.inc"
.include "zeropage.inc"

.import spi_readbyte, spi_writebyte, spi_waitresult

.export sdcard_init, sd_readsector

sdcard_init:
  ; We need to apply around 80 clock pulses with CS and MOSI high.
  ; Normally MOSI doesn't matter when CS is high, but the card is
  ; not yet is SPI mode, and in this non-SPI state it does care.
  lda #(SPI_CS_SD | SPI_MOSI)
  ldx #160               ; toggle the clock 160 times, so 80 low-high transitions
@preinitloop:
  eor #SPI_CLK
  sta VIA2_PORTB
  dex
  bne @preinitloop

@cmd0: ; GO_IDLE_STATE - resets card to idle state, and SPI mode
  lda #<cmd0_bytes
  sta zp_sd_address
  lda #>cmd0_bytes
  sta zp_sd_address+1

  jsr sd_sendcommand

  ; Expect status response $01 (not initialized)
  cmp #$01
  bne @initfailed

  ;jsr longdelay

@cmd8: ; SEND_IF_COND - tell the card how we want it to operate (3.3V, etc)
  lda #<cmd8_bytes
  sta zp_sd_address
  lda #>cmd8_bytes
  sta zp_sd_address+1

  jsr sd_sendcommand

  ; Expect status response $01 (not initialized)
  cmp #$01
  bne @initfailed

  ; Read 32-bit return value, but ignore it
  jsr spi_readbyte
  jsr spi_readbyte
  jsr spi_readbyte
  jsr spi_readbyte

  ;jsr longdelay

@cmd55: ; APP_CMD - required prefix for ACMD commands
  lda #<cmd55_bytes
  sta zp_sd_address
  lda #>cmd55_bytes
  sta zp_sd_address+1

  jsr sd_sendcommand

  ; Expect status response $01 (not initialized)
  cmp #$01
  bne @initfailed

  ;jsr longdelay

@cmd41: ; APP_SEND_OP_COND - send operating conditions, initialize card
  lda #<cmd41_bytes
  sta zp_sd_address
  lda #>cmd41_bytes
  sta zp_sd_address+1

  jsr sd_sendcommand

  ; Status response $00 means initialised
  cmp #$00
  beq @initialized

  ; Otherwise expect status response $01 (not initialized)
  cmp #$01
  bne @initfailed

  ; Not initialized yet, so wait a while then try again.
  ; This retry is important, to give the card time to initialize.
  ;jsr longdelay
  ;jsr longdelay
  jmp @cmd55


@initialized:
  ;jsr longdelay
  rts

@initfailed:
  ;lda #'X'
  ;jsr print_char
  rts


sd_sendcommand:
  ; Debug print which command is being executed
  ;jsr lcd_cleardisplay

  ;lda #'c'
  ;jsr print_char
  ;ldx #0
  ;lda (zp_sd_address,x)
  ;jsr print_hex

  lda #SPI_MOSI           ; pull CS low to begin command
  sta VIA2_PORTB

  ldy #0
  lda (zp_sd_address),y    ; command byte
  jsr spi_writebyte
  ldy #1
  lda (zp_sd_address),y    ; data 1
  jsr spi_writebyte
  ldy #2
  lda (zp_sd_address),y    ; data 2
  jsr spi_writebyte
  ldy #3
  lda (zp_sd_address),y    ; data 3
  jsr spi_writebyte
  ldy #4
  lda (zp_sd_address),y    ; data 4
  jsr spi_writebyte
  ldy #5
  lda (zp_sd_address),y    ; crc
  jsr spi_writebyte

  jsr spi_waitresult
  pha

  ; Debug print the result code
  ;jsr print_hex

  ; End command
  lda #SPI_CS_SD | SPI_MOSI   ; set CS high again
  sta VIA2_PORTB

  pla   ; restore result code
  rts


sd_readsector:
  ; Read a sector from the SD card.  A sector is 512 bytes.
  ;
  ; Parameters:
  ;    zp_sd_currentsector   32-bit sector number
  ;    zp_sd_address     address of buffer to receive data
  
  lda #SPI_MOSI
  sta VIA2_PORTB

  ; Command 17, arg is sector number, crc not checked
  lda #$51                    ; CMD17 - READ_SINGLE_BLOCK
  jsr spi_writebyte
  lda zp_sd_currentsector+3   ; sector 24:31
  jsr spi_writebyte
  lda zp_sd_currentsector+2   ; sector 16:23
  jsr spi_writebyte
  lda zp_sd_currentsector+1   ; sector 8:15
  jsr spi_writebyte
  lda zp_sd_currentsector     ; sector 0:7
  jsr spi_writebyte
  lda #$01                    ; crc (not checked)
  jsr spi_writebyte

  jsr spi_waitresult
  cmp #$00
  bne @fail

  ; wait for data
  jsr spi_waitresult
  cmp #$fe
  bne @fail

  ; Need to read 512 bytes - two pages of 256 bytes each
  jsr @readpage
  inc zp_sd_address+1
  jsr @readpage
  dec zp_sd_address+1

  ; End command
  lda #SPI_CS_SD | SPI_MOSI
  sta VIA2_PORTB

  rts


@fail:
  ;lda #'s'
  ;jsr print_char
  ;lda #':'
  ;jsr print_char
  ;lda #'f'
  ;jsr print_char
  
@failloop:
  jmp @failloop


@readpage:
  ; Read 256 bytes to the address at zp_sd_address
  ldy #0
@readloop:
  jsr spi_readbyte
  sta (zp_sd_address),y
  iny
  bne @readloop
  rts


.rodata
  cmd0_bytes:
    .byte $40, $00, $00, $00, $00, $95
  cmd8_bytes:
    .byte $48, $00, $00, $01, $aa, $87
  cmd55_bytes:
    .byte $77, $00, $00, $00, $00, $01
  cmd41_bytes:
    .byte $69, $40, $00, $00, $00, $01
