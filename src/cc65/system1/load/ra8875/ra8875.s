.setcpu "65C02"

.include "io.inc"
.include "macros.inc"
.include "zeropage.inc"

.import delay_ms
.import spi_select_device, spi_deselect, spi_r_byte, spi_rw_byte

.export ra8875_init, ra8875_writetext



.rodata
    terminal_message: .asciiz "JRE6502>"

datawrite = $00
dataread  = $40
cmdwrite  = $80
cmdread   = $C0

pwrr_reg = $01
pwrr_dispon = $80
pwrr_normal = $00

gpiox_reg = $C7

p1c1_reg = $8A
p1cr_enable = $80
pwm_clk_div1024 = $0A

p1cdr_reg = $8B

mwcr0_reg = $40
mwcr0_txtmode = $80
mwcr0_cursor = $40
mwcr0_blink = $20

btcr_reg = $44

mrwc_reg = $02


.code

  ra8875_init:
    
    ; toggle reset pin
    ; todo
    ;if (!tft.begin(RA8875_800x480)) {
    ;  Serial.println("RA8875 Not Found!");
    ;  while (1);
    ;}
    lda SPI_PORT ; load existing values
    eor SDCARD_DETECT  ; eor the value to set the led pin off
    sta SPI_PORT
    lda #200
    jsr delay_ms

    lda SPI_PORT ; load existing values
    ora SDCARD_DETECT  ; or the value to set led pin on
    sta SPI_PORT 
    lda #200
    jsr delay_ms

    ; lda SPI_PORT ; load existing values
    ; eor SDCARD_DETECT  ; eor the value to set the led pin off
    ; sta SPI_PORT
    ; lda #100
    ; jsr delay_ms



    ; ;tft.displayOn(true);
    ; ;writeReg(RA8875_PWRR, RA8875_PWRR_NORMAL | RA8875_PWRR_DISPON);
    ; lda #(pwrr_normal | pwrr_dispon)
    ; pha
    ; lda #pwrr_reg
    ; pha
    ; jsr writereg
    lda #pwrr_reg
    jsr writecommand
    lda #(pwrr_normal | pwrr_dispon)
    jsr writedata
    

    ; ; ;tft.GPIOX(true);      // Enable TFT - display enable tied to GPIOX
    ; ; ;writeReg(RA8875_GPIOX, 1);
    ; ; lda #1
    ; ; pha
    ; ; lda #gpiox_reg
    ; ; pha
    ; ; jsr writereg
    ; lda #gpiox_reg
    ; jsr writecommand
    ; lda #1
    ; jsr writedata
    

    ; ;tft.PWM1config(true, RA8875_PWM_CLK_DIV1024); // PWM output for backlight
    ; ;writeReg(RA8875_P1CR, RA8875_P1CR_ENABLE | (clock & 0xF));
    ; ; TODO: replace math at end with calculated value
    ; lda #(p1cr_enable | (pwm_clk_div1024 & $F))
    ; pha
    ; lda #p1c1_reg
    ; pha
    ; jsr writereg
    lda #p1c1_reg
    jsr writecommand
    ;lda #(p1cr_enable | (pwm_clk_div1024 & $F))
    lda #$8A
    jsr writedata


    ; ;tft.PWM1out(255);
    ; ;writeReg(RA8875_P1DCR, p)
    ; lda #255
    ; pha
    ; lda #p1cdr_reg
    ; pha
    ; jsr writereg
    lda #p1cdr_reg
    jsr writecommand
    lda #255
    jsr writedata

    
    ;tft.fillScreen(RA8875_BLACK);
    ;; todo this is larg


    ;tft.textMode();
    jsr textmode
    
    ;tft.cursorBlink(32);
    jsr cursorblink

    ;tft.textTransparent(RA8875_WHITE);
    jsr texttransparent


    loadptr terminal_message, ra8875_out_ptr
    jsr ra8875_writetext


    rts




  ;void Adafruit_RA8875::textWrite(const char *buffer, uint16_t len) {
  ;  if (len == 0)
  ;    len = strlen(buffer);
  ;  writeCommand(RA8875_MRWC);
  ;  for (uint16_t i = 0; i < len; i++) {
  ;    writeData(buffer[i]);
  ra8875_writetext:

    lda #mrwc_reg
    jsr writecommand

    ldy #0              ; start at first byte
    @loop:
      lda (ra8875_out_ptr),y ; get byte at pointer index
      beq @done           ; exit if null character reached
      jsr writedata
      iny                 ; increment to next byre
      jmp @loop           ; loop
    @done:

    rts


  ;void Adafruit_RA8875::textMode(void) {
  ;  /* Set text mode */
  ;  writeCommand(RA8875_MWCR0);
  ;  uint8_t temp = readData();
  ;  temp |= RA8875_MWCR0_TXTMODE; // Set bit 7
  ;  writeData(temp);
  ;  /* Select the internal (ROM) font */
  ;  writeCommand(0x21);
  ;  temp = readData();
  ;  temp &= ~((1 << 7) | (1 << 5)); // Clear bits 7 and 5
  ;  writeData(temp);
  ;}
  textmode:
    lda #mwcr0_reg
    jsr writecommand

    jsr readdata
    ora #mwcr0_txtmode
    jsr writedata

    lda #$21
    jsr writecommand

    jsr readdata
    ;eor #((1 << 7) | (1 << 5))
    eor #$A0
    jsr writedata

    rts


  ;void Adafruit_RA8875::cursorBlink(uint8_t rate) {
  ;  writeCommand(RA8875_MWCR0);
  ;  uint8_t temp = readData();
  ;  temp |= RA8875_MWCR0_CURSOR;
  ;  writeData(temp);
  ;  writeCommand(RA8875_MWCR0);
  ;  temp = readData();
  ;  temp |= RA8875_MWCR0_BLINK;
  ;  writeData(temp);
  ;  if (rate > 255)
  ;    rate = 255;
  ;  writeCommand(RA8875_BTCR);
  ;  writeData(rate);
  ;}
  cursorblink:
    lda #mwcr0_reg
    jsr writecommand
    
    jsr readdata
    ora #mwcr0_cursor
    jsr writedata

    lda #mwcr0_reg
    jsr writecommand
    
    jsr readdata
    ora #mwcr0_blink
    jsr writedata

    lda #btcr_reg
    jsr writecommand
    lda #32
    jsr writedata

    rts


  ;void Adafruit_RA8875::textTransparent(uint16_t foreColor) {
  ;  /* Set Fore Color */
  ;  writeCommand(0x63);
  ;  writeData((foreColor & 0xf800) >> 11);
  ;  writeCommand(0x64);
  ;  writeData((foreColor & 0x07e0) >> 5);
  ;  writeCommand(0x65);
  ;  writeData((foreColor & 0x001f));

  ;  /* Set transparency flag */
  ;  writeCommand(0x22);
  ;  uint8_t temp = readData();
  ;  temp |= (1 << 6); // Set bit 6
  ;  writeData(temp);
  ;}
  texttransparent:
    lda #$63
    jsr writecommand
    lda #$FF
    jsr writedata

    lda #$64
    jsr writecommand
    lda #$FF
    jsr writedata

    lda #$65
    jsr writecommand
    lda #$FF
    jsr writedata

    lda #$22
    jsr writecommand
    jsr readdata
    ;ora #(1<<6)
    ora #$40
    jsr writedata
    rts


  ;void Adafruit_RA8875::writeReg(uint8_t reg, uint8_t val) {
  ;  writeCommand(reg);
  ;  writeData(val);
  ;}
  writereg:
    pla
    jsr writecommand
    pla
    jsr writedata
    rts



  ;void Adafruit_RA8875::writeCommand(uint8_t d) {
  ;  digitalWrite(_cs, LOW);
  ;  spi_begin()
  ;  SPI.transfer(RA8875_CMDWRITE);
  ;  SPI.transfer(d);
  ;  spi_end();
  ;  digitalWrite(_cs, HIGH);
  ;}
  writecommand:
    pha

    lda #spi_device_ra8875
    jsr spi_select_device

    lda #cmdwrite
    jsr spi_rw_byte
    pla
    jsr spi_rw_byte

    jsr spi_deselect

    rts


  ;void Adafruit_RA8875::writeData(uint8_t d) {
  ;  digitalWrite(_cs, LOW);
  ;  spi_begin();
  ;  SPI.transfer(RA8875_DATAWRITE);
  ;  SPI.transfer(d);
  ;  spi_end();
  ;  digitalWrite(_cs, HIGH);
  ;}
  writedata:
    pha

    lda #spi_device_ra8875
    jsr spi_select_device

    lda #datawrite
    jsr spi_rw_byte
    pla
    jsr spi_rw_byte

    jsr spi_deselect

    rts



  ;uint8_t Adafruit_RA8875::readData(void) {
  ;  digitalWrite(_cs, LOW);
  ;  spi_begin();
  ;  SPI.transfer(RA8875_DATAREAD);
  ;  uint8_t x = SPI.transfer(0x0);
  ;  spi_end();
  ;  digitalWrite(_cs, HIGH);
  ;  return x;
  ;}
  readdata:
    lda #spi_device_ra8875
    jsr spi_select_device

    lda #dataread
    jsr spi_rw_byte

    ; does this need to be done too?
    ;jsr spi_r_byte
    lda #0
    jsr spi_rw_byte

    jsr spi_deselect

    rts
