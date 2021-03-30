.include "io.inc"
.include "zeropage.inc"

.import delay_ms, convert_to_hex

.export lcd_init
.export lcd_print_string, lcd_print_char, lcd_print_hex
.export primm_lcd
.export lcd_clear, lcd_goto

; code from https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd.s
; code from https://github.com/grappendorf/homecomputer-6502/blob/master/firmware/lcd.s65

.data
  display_data: .res 4 * 40, ' '

.code
  ;
  ; Initializes the LCD display
  ; IN: Nothing
  ; OUT: Nothing
  ; ZP: Nothing
  ;
  lcd_init:
    pha

    ; wait 40ms for startup
    lda #40
    jsr delay_ms

    ; store 0 in zeropage variables
    stz lcd_row
    stz lcd_column
    ; set both LCD controllers to be acted upon
    lda #(LCD_E1 | LCD_E2)
    sta lcd_enable_pins

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
    lda #(CMD_FUNCTION_SET | FS_DATA_LENGTH_4 | FS_NUM_LINES_2 | FS_FONT_5X8)
    jsr write_command
    lda #(CMD_DISPLAY_CONTROL | DC_DISPLAY_ON | DC_CURSOR_OFF)
    jsr write_command
    lda #(CMD_ENTRY_MODE_SET | EM_CURSOR_INC | EM_SHIFT_CURSOR)
    jsr write_command

    ; clear out the data buffer and set cursor at 0,0
    jsr lcd_clear

    ; set the first/top controller to be acted upon
    lda #(LCD_E1)
    sta lcd_enable_pins

    pla
    rts


  ;
  ; Prints null terminated string references in ZP pointer "lcd_out_ptr" to LCD
  ; IN: lcd_out_ptr - ZP pointer to null terminated string
  ; OUT: Nothing
  ; ZP: tmp1, tmp2, tmp3 (see write and read)
  ;
  lcd_print_string:
    pha                 ; save A
    phy                 ; save Y
    ldy #0              ; start at first byte
  @loop:
    lda (lcd_out_ptr),y ; get byte at pointer index
    beq @done           ; exit if null character reached
    jsr lcd_print_char
    iny                 ; increment to next byre
    jmp @loop           ; loop
  @done:
    ply                 ; restore Y
    pla                 ; restore A
    rts                 ; return


  ;
  ; Prints byte in A to LCD
  ; IN: A byte to write
  ; OUT: Nothing
  ; ZP: tmp1, tmp2, tmp3 (see write and read)
  ;
  lcd_print_char:
    ;phaxy
    pha
    phx
    phy
    cmp #$0a
    beq @newline
    pha
    jsr write_data
    lda lcd_column
    ldx lcd_row
    beq @l1
  @l2:
    clc
    adc #40
    dex
    bne @l2
  @l1:
    tax
    pla
    sta display_data,x
    inc lcd_column
    ldx lcd_column
    cpx #40
    beq @newline
    ;plaxy
    ply
    plx
    pla
    rts
  @newline:
    ldy lcd_row
    cpy #3
    beq @scroll
    iny
    ldx #0
    jsr lcd_goto
    ;plaxy
    ply
    plx
    pla
    rts
  @scroll:
    ldx #0
    ldy #0
    jsr lcd_goto
  @scroll_line1:
    lda display_data + 40,x
    sta display_data,x
    phx
    jsr write_data
    plx
    inx
    cpx #40
    bne @scroll_line1
    ldx #0
    ldy #1
    jsr lcd_goto
  @scroll_line2:
    lda display_data + 80,x
    sta display_data + 40,x
    phx
    jsr write_data
    plx
    inx
    cpx #40
    bne @scroll_line2
    ldx #0
    ldy #2
    jsr lcd_goto
  @scroll_line3:
    lda display_data + 120,x
    sta display_data + 80,x
    phx
    jsr write_data
    plx
    inx
    cpx #40
    bne @scroll_line3
    ldx #0
    ldy #3
    jsr lcd_goto
  @scroll_line4:
    lda #' '
    sta display_data + 120,x
    phx
    jsr write_data
    plx
    inx
    cpx #40
    bne @scroll_line4
    ldx #0
    ldy #3
    jsr lcd_goto
    ;plaxy
    ply
    plx
    pla
    rts


  ;
  ;
  ;
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


  ;
  ;
  ;
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


  ;
  ; Clears the LCD
  ; IN: Nothing
  ; OUT: Nothing
  ; ZP: tmp1, tmp2, tmp3 (see write and read)
  ;
  lcd_clear:
    pha            ; save A
    phx
    phy

    ; set both LCD controllers to be acted upon
    lda #(LCD_E1 | LCD_E2)
    sta lcd_enable_pins
    lda #(CMD_CLEAR_DISPLAY)
    jsr write_command
    ; this command takes a while (1.52ms) and either the busy flag check isnt working right for it, or it doesnt work for it
    lda #2
    jsr delay_ms

    ; clear data buffer
    ldx #0
    ldy #0
    jsr lcd_goto
    ldx #(4 * 40 - 1)
    lda #' '
  @clear:
    sta display_data,x
    dex
    bpl @clear

    ply
    plx
    pla            ; restore A
    rts            ; return


  ;
  ; Goes to positon specified in X and Y registers
  ; IN: X - column, Y - row
  ; OUT: Nothing
  ; ZP: tmp1, tmp2, tmp3 (see write and read)
  ;
  lcd_goto:
    pha
    phx
    phy

    stx lcd_column
    sty lcd_row
    lda row_enables,y
    sta lcd_enable_pins
    lda lcd_column
    clc
    adc row_offsets,y
    adc #CMD_SET_DDRAM_ADDR
    jsr write_command

    ply
    plx
    pla
    rts



  ;
  ; Writes the byte to the LCD bus
  ; IN:
  ;  A - command byte to write
  ; OUT: Nothing
  ; ZP:
  ;  tmp1 - temp storage for input data
  ;  tmp2 - temp storage for commands
  ;
  write_data:
    pha
    jsr lcd_wait_bf_clear
    pla

    sta tmp1                    ; save A to tmp1
    lda #(LCD_WRITE | LCD_DATA) ; set data write
    sta tmp2                    ; save commands to tmp2
    jmp write_internal          ; jump to function that sends data

  write_command:
    pha
    jsr lcd_wait_bf_clear
    pla

    sta tmp1                       ; save A to tmp1
    lda #(LCD_WRITE | LCD_COMMAND) ; else set command write
    sta tmp2                       ; save commands to tmp2
    jmp write_internal             ; jump to function that sends data
  
  write_internal:
    ; set the pins to output
    lda LCD_DDR
    ora #(LCD_D4 | LCD_D5 | LCD_D6 | LCD_D7)
    sta LCD_DDR

    ; process MSB
    lda tmp1            ; load tmp1 to A (which was A when entering subroutine)
    and #%11110000      ; mask msb
    ora tmp2            ; add the commands in
    sta LCD_PORT        ; send first 4 bits
    ; toggle ENABLE
    ora lcd_enable_pins ; add enable
    sta LCD_PORT        ; write to the via port
    eor lcd_enable_pins ; remove enable
    sta LCD_PORT        ; write to the via port

    ; process LSB
    lda tmp1            ; load tmp1 to A (which was A when entering subroutine)
    and #%00001111      ; mask lsb
    asl                 ; shift left 4 times
    asl
    asl
    asl
    ora tmp2            ; add the commands in
    sta LCD_PORT        ; send first 4 bits
    ; toggle ENABLE
    ora lcd_enable_pins ; add enable
    sta LCD_PORT        ; write to the via port
    eor lcd_enable_pins ; remove enable
    sta LCD_PORT        ; write to the via port

    rts                 ; return



  ;
  ;
  ;
  ;
  lcd_wait_bf_clear:
    jsr read_from_lcd   ; jump to read subroutine
    bmi lcd_wait_bf_clear  ; loop until bit7/BusyFlag is set
    rts



  ;
  ; Reads byte from LCD bus, preserving VIA pins. Bit 7 is BF and rest is LCD address counter
  ; IN: Nothing
  ; OUT: A - the byte read where bit 7 is busy flag and the rest is the address counter in the LCD, used for knowing cursor location
  ; ZP:
  ;  tmp1 - temp storage for commands
  ;  tmp2 - temp storage for MSB
  ;  tmp3 - temp storage for LSB
  ;
  read_from_lcd:
    lda #(LCD_READ | LCD_COMMAND) ; set command read
    sta tmp1            ; save commands to tmp1

    ; preserve direction of last 4 DDRA and change data lines to input
    lda LCD_DDR
    ora #<~(LCD_D4 | LCD_D5 | LCD_D6 | LCD_D7) ; compliment bits
    sta LCD_DDR

    ; read MSBs
    lda tmp1
    sta LCD_PORT        ; write to the via port
    
    ora lcd_enable_pins ; add enable
    sta LCD_PORT        ; write to the via port
    
    lda LCD_PORT        ; read result
    and #%11110000      ; mask
    sta tmp2            ; store data
    
    lda LCD_PORT        ; load current data on the port
    eor lcd_enable_pins ; remove enable
    sta LCD_PORT        ; write to the via port

    ; read LSBs
    ora tmp1            ; add the commands in
    sta LCD_PORT
    
    ora lcd_enable_pins ; add enable
    sta LCD_PORT        ; write to the via port

    lda LCD_PORT
    sta tmp3

    eor lcd_enable_pins ; remove enable
    sta LCD_PORT        ; write to the via port

    ; put result from tmp2 and tmp3 in to A
    sta tmp3            ; LSB from tmp3
    and #%11110000      ; mask
    lsr                 ; shit right 4 times
    lsr
    lsr
    lsr
    ora tmp2            ; MSB from tmp2

    rts               ; return


  ;
  ; Used in the initial force initialization routines
  ; IN: A - command byte to write
  ; OUT: Nothing
  ; ZP: tmp1 - temp storage for input data
  ;
  init_write_to_lcd:
    sta tmp1            ; save A to tmp1
    lda LCD_PORT        ; load current data on port
    ora tmp1            ; add commands to data
    ora lcd_enable_pins ; add enable
    sta LCD_PORT        ; write
    eor lcd_enable_pins ; remove enable
    sta LCD_PORT        ; write
    rts                 ; return


.rodata
  LCD_READ =    %00000100
  LCD_WRITE =   %00000000
  LCD_DATA =    %00000010
  LCD_COMMAND = %00000000

  CMD_CLEAR_DISPLAY   = %00000001
  CMD_RETURN_HOME     = %00000010
  CMD_ENTRY_MODE_SET  = %00000100
  CMD_DISPLAY_CONTROL = %00001000
  CMD_CURSOR_SHIFT    = %00010000
  CMD_FUNCTION_SET    = %00100000
  CMD_SET_CGRAM_ADDR  = %01000000
  CMD_SET_DDRAM_ADDR  = %10000000

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

  row_offsets:        .byte $00, $40, $00, $40
  row_enables:        .byte LCD_E1, LCD_E1, LCD_E2, LCD_E2