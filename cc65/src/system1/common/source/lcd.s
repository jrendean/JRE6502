.include "io.inc"
.include "zeropage.inc"

.import delay_ms, convert_to_hex

.export lcd_init
.export lcd_clear
.export lcd_print_string
.export lcd_print_char
.export lcd_goto
.export lcd_print_hex
.export primm_lcd

; code from https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd.s
; code from https://github.com/grappendorf/homecomputer-6502/blob/master/firmware/lcd.s65

.code

  ; Initializes the LCD display
  ; IN: Nothing
  ; OUT: Nothing
  ; ZP: Nothing
  lcd_init:
    pha

    ; set the pins to output, keeping pin 0 what is is set to (though should always be output?)
    lda VIA2_DDRA
    ora #%11111110 ; Set all pins on port B to output
    sta VIA2_DDRA

    ; wait 50ms for startup
    lda #50
    jsr delay_ms

    ; https://en.wikipedia.org/wiki/Hitachi_HD44780_LCD_controller
    ; 3x force to 8bit - 0011 0000 (8bit write)
    lda #(CMD_FUNCTION_SET | FS_DATA_LENGTH_8)
    jsr init_write_to_lcd
    lda #5
    jsr delay_ms
    lda #(CMD_FUNCTION_SET | FS_DATA_LENGTH_8)
    jsr init_write_to_lcd
    lda #1
    jsr delay_ms
    lda #(CMD_FUNCTION_SET | FS_DATA_LENGTH_8)
    jsr init_write_to_lcd
    lda #1
    jsr delay_ms
    ; set to 4bit - 0010 0000 (8bit write)
    lda #(CMD_FUNCTION_SET)
    jsr init_write_to_lcd
    lda #1
    jsr delay_ms

    ; actual initialization
    clc  ; carry flag cleared = command operation
    lda #(CMD_FUNCTION_SET | FS_DATA_LENGTH_4 | FS_NUM_LINES_2 | FS_FONT_5X8)
    jsr write_to_lcd
    lda #(CMD_DISPLAY_CONTROL | DC_DISPLAY_ON | DC_CURSOR_ON)
    jsr write_to_lcd
    lda #(CMD_ENTRY_MODE_SET | EM_CURSOR_INC | EM_SHIFT_CURSOR)
    jsr write_to_lcd

    jsr lcd_clear

    pla
    rts


  ; Prints null terminated string references in ZP pointer "lcd_out_ptr" to LCD
  ; IN: lcd_out_ptr - ZP pointer to null terminated string
  ; OUT: Nothing
  ; ZP: tmp1, tmp2, tmp3 (see write and read)
  lcd_print_string:
    pha          ; save A
    phy          ; save Y
    ldy #0         ; start at first byte
  @loop:
    lda (lcd_out_ptr), y ; get byte at pointer index
    beq @done      ; exit if null character reached
    sec          ; carry flag set = data operation
    jsr write_to_lcd   ; jump to write to output the byte
    iny          ; increment to next byre
    jsr check_line_wrap  ; check character positioning and lines
    jmp @loop      ; loop
  @done:
    ply          ; restore Y
    pla          ; restore A
    rts          ; return


  ; Prints byte in A to LCD
  ; IN: A byte to write
  ; OUT: Nothing
  ; ZP: tmp1, tmp2, tmp3 (see write and read)
  lcd_print_char:
    pha         ; save A
    sec         ; carry flag set = data operation
    jsr write_to_lcd  ; jump to write to output the byte
    jsr check_line_wrap ; check character positioning and lines
    pla         ; restore A
    rts         ; return


  lcd_print_hex:
    pha
    phx
    phy
    jsr convert_to_hex
    txa
    jsr lcd_print_char
    tya
    jsr lcd_print_char
    ply
    plx
    pla
    rts

  ; Clears the LCD
  ; IN: Nothing
  ; OUT: Nothing
  ; ZP: tmp1, tmp2, tmp3 (see write and read)
  lcd_clear:
    pha            ; save A
    lda #(CMD_CLEAR_DISPLAY) ; load the clear command
    clc            ; carry flag cleared = command operation
    jsr write_to_lcd     ; jump to write to output the byte
    pla            ; restore A
    rts            ; return


  ; Goes to positon specified in X and Y registers
  ; IN: X - column, Y - row
  ; OUT: Nothing
  ; ZP: tmp1, tmp2, tmp3 (see write and read)
  lcd_goto:
    pha             ; save A
    txa             ; move X in to A
    clc             ; clear carry - why?
    adc row_offsets, y    ; add in the row length offset from the row Y
    clc             ; clear carry - why?
    ora #(CMD_SET_DDRAM_ADDR) ; add in command
    clc             ; carry flag cleared = command operation
    jsr write_to_lcd      ; jump to write to output the byte
    pla             ; restore A
    rts             ; return




  ; http://6502.org/source/io/primm.htm
  primm_lcd:
    pla         ; get low part of (string address-1)
    sta   DPL
    pla         ; get high part of (string address-1)
    sta   DPH
    bra   @primm3
  @primm2:
    jsr   lcd_print_char    ; output a string char
  @primm3:
    inc   DPL     ; advance the string pointer
    bne   @primm4
    inc   DPH
  @primm4:
    lda   (DPL)     ; get string char
    bne   @primm2    ; output and continue if not NUL
    lda   DPH
    pha
    lda   DPL
    pha
    rts         ; proceed at code following the NUL 


  ; Called after a byte is written to LCD bus. Part of write operation is a read that will have LCD's address counter in A. Checks to see if counter is on line break and addjust address accordingly.
  ; IN: 
  ; OUT: 
  ; ZP: 
  check_line_wrap:
    pha             ; save A
    phx             ; save X
    ldx #0            ;
  @loop:
    cmp lcd_wordwrap_sources, x ;
    beq @line_wrap        ;
    inx             ;
    cpx #4            ; rows
    beq @no_wrap        ;
    bra @loop           ;
  @line_wrap:
    lda lcd_wordwrap_targets, x ;
    ora #(CMD_SET_DDRAM_ADDR)   ; add in command
    clc             ; carry flag cleared = command operation
    jsr write_to_lcd      ; jump to write to output the byte
  @no_wrap:
    plx             ; restore X
    pla             ; restore A
    rts             ; return


  ; Writes the byte to the LCD bus, preserving VIA pins
  ; IN:
  ;  A - command byte to write
  ;  CLC - command
  ;  SEC - data
  ; OUT: Nothing
  ; ZP:
  ;  tmp1 - temp storage for input data
  ;  tmp2 - temp storage for commands and other pins
  write_to_lcd:
    sta tmp1             ; save A to tmp1
    bcs @write_data        ; if carry set, branch to data commands
    lda #(LCD_WRITE | LCD_COMMAND) ; else set command write
    sta tmp2             ; save commands to tmp2
    bra @write_internal
  @write_data:
    lda #(LCD_WRITE | LCD_DATA)  ; set data write
    sta tmp2             ; save commands to tmp2
  
  @write_internal:
    ; set the pins to output, keeping pin 0 what is is set to (though should always be output?)
    lda VIA2_DDRA
    ora #%11111110
    sta VIA2_DDRA

    ; save off current state of pin 0
    lda VIA2_PORTA         ; load current data on port
    and #%00000001         ; save off state of pin 0
    ora tmp2             ; add commnads to data
    sta tmp2             ; store back to tmp2

    ; process MSB
    lda tmp1             ; load tmp1 to A (which was A when entering subroutine)
    and #%11110000         ; mask msb
    ora tmp2             ; add the commands in
    sta VIA2_PORTA         ; send first 4 bits
    ; toggle ENABLE
    ora #(LCD_ENABLE)        ; add enable
    sta VIA2_PORTA
    eor #(LCD_ENABLE)        ; remove enable
    sta VIA2_PORTA

    ; process LSB
    lda tmp1             ; load tmp1 to A (which was A when entering subroutine)
    and #%00001111         ; mask lsb
    asl              ; shift left 4 times
    asl
    asl
    asl
    ora tmp2             ; add the commands in
    sta VIA2_PORTA         ; send first 4 bits
    ; toggle ENABLE
    ora #(LCD_ENABLE)        ; add enable
    sta VIA2_PORTA
    eor #(LCD_ENABLE)        ; remove enable
    sta VIA2_PORTA

  @wait_for_busy:          ; wait for busy flag to not be set
    clc              ; carry flag clear = command operation
    jsr read_from_lcd        ; jupm to read subroutine
    bmi @wait_for_busy       ; loop until bit7/BusyFlag is set
    rts              ; return


  ; Reads byte from LCD bus, preserving VIA pins. Bit 7 is BF and reset is LCD address counter
  ; IN:
  ;  CLC - command
  ;  SEC - data
  ; OUT: A - the byte read where bit 7 is busy flag and the rest is the address counter in the LCD, used for knowing cursor location
  ; ZP:
  ;  tmp1 - temp storage for commands and other pins
  ;  tmp2 - temp storage for MSB
  ;  tmp3 - temp storage for LSB
  read_from_lcd:
    bcs @read_data        ; if carry set, branch to data commands
    lda #(LCD_READ | LCD_COMMAND) ; else set command read
    sta tmp1            ; save commands to tmp1
    bra @read_internal
  @read_data:
    lda #(LCD_READ | LCD_DATA)  ; set data read
    sta tmp1            ; save commands to tmp1
  @read_internal:
    ; preserve direction of last 4 DDRA and change data lines to input, keeping pin 0 what is is set to (though should always be output?)
    lda VIA2_DDRA
    and #%00000001
    ora #%00001110
    sta VIA2_DDRA
    
    ; read MSBs
    lda VIA2_PORTA        ; load current data on port
    and #%00000001        ; save off state of pin 0
    ora tmp1            ; add the commands in
    sta VIA2_PORTA
    
    ora #(LCD_ENABLE)       ; add enable
    sta VIA2_PORTA
    
    lda VIA2_PORTA        ; read result
    and #%11110000        ; mask
    sta tmp2            ; store data
    
    lda VIA2_PORTA
    eor #(LCD_ENABLE)       ; remove enable
    sta VIA2_PORTA

    ; read LSBs
    ;lda VIA2_PORTA ; load current data on port
    and #%00000001        ; save off state of pin 0
    ora tmp1            ; add the commands in
    sta VIA2_PORTA
    
    ora #(LCD_ENABLE)       ; add enable
    sta VIA2_PORTA

    lda VIA2_PORTA
    sta tmp3

    eor #(LCD_ENABLE)       ; remove enable
    sta VIA2_PORTA

    ; put result from tmp2 and tmp3 in to A
    sta tmp3            ; LSB from tmp3
    and #%11110000        ; mask
    lsr               ; shit right 4 times
    lsr
    lsr
    lsr
    ora tmp2            ; MSB from tmp2

    rts               ; return


  ; Used in the initial force initialization routines
  ; IN: A - command byte to write
  ; OUT: Nothing
  ; ZP: tmp1 - temp storage for input data
  init_write_to_lcd:
    sta tmp1      ; save A to tmp1
    lda VIA2_PORTA  ; load current data on port
    and #%00000001  ; save off state of pin 0
    ora tmp1      ; add commands to data
    ora #(LCD_ENABLE) ; add enable
    sta VIA2_PORTA  ; write
    eor #(LCD_ENABLE) ; remove enable
    sta VIA2_PORTA  ; write
    rts         ; return


.rodata
  ;https://github.com/grappendorf/homecomputer-6502/blob/748c43e96795b9f0a5946ac8117e01654bb7794e/firmware/lcd.s65

  LCD_ENABLE =  %00001000
  LCD_READ =    %00000100
  LCD_WRITE =   %00000000
  LCD_DATA =    %00000010
  LCD_COMMAND = %00000000

  CMD_CLEAR_DISPLAY    = %00000001
  CMD_RETURN_HOME      = %00000010
  CMD_ENTRY_MODE_SET   = %00000100
  CMD_DISPLAY_CONTROL  = %00001000
  CMD_CURSOR_SHIFT     = %00010000
  CMD_FUNCTION_SET     = %00100000
  CMD_SET_CGRAM_ADDR   = %01000000
  CMD_SET_DDRAM_ADDR   = %10000000

  EM_SHIFT_CURSOR  = %00000000
  EM_SHIFT_DISPLAY = %00000001
  EM_CURSOR_DEC    = %00000000
  EM_CURSOR_INC    = %00000010

  DC_CURSOR_BLINK  = %00000001
  DC_CURSOR_OFF    = %00000000
  DC_CURSOR_ON     = %00000010
  DC_DISPLAY_OFF   = %00000000
  DC_DISPLAY_ON    = %00000100

  CS_SHIFT_LEFT    = %00000000
  CS_SHIFT_RIGHT   = %00000100
  CS_CURSOR_MOVE   = %00000000
  CS_DISPLAY_SHIFT = %00001000

  FS_FONT_5X8      = %00000000
  FS_FONT_5X10     = %00000100
  FS_NUM_LINES_1   = %00000000
  FS_NUM_LINES_2   = %00001000
  FS_DATA_LENGTH_4 = %00000000
  FS_DATA_LENGTH_8 = %00010000

  ;http://forum.6502.org/viewtopic.php?f=4&t=5336&p=64722&hilit=hd44780+memory#p64722
  row_offsets:       .byte $00, $40, $14, $54

  lcd_wordwrap_sources:  .byte 20, $40+20, $40, 00
  lcd_wordwrap_targets:  .byte $40, 20, $40+20, 00
