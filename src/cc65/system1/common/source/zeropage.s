.include "zeropage.inc"

.zeropage

;??
; [$00-$13] reserved for cc65 runtime library
;           (but could be used by machine code programs)
;??
sp:          .res 2
sreg:        .res 2
regsave:     .res 4

ptr1:        .res 2
ptr2:        .res 2
ptr3:        .res 2
ptr4:        .res 2
tmp1:        .res 1
tmp2:        .res 1
tmp3:        .res 1
tmp4:        .res 1
;tmp5:        .res 1

console_out_ptr: .res 2
lcd_out_ptr: .res 2

zp_sd_address:           .res 2  ; 2 bytes
zp_sd_currentsector:     .res 4  ; 4 bytes
fat32_fatstart:          .res 4  ; 4 bytes
fat32_datastart:         .res 4  ; 4 bytes
fat32_rootcluster:       .res 4  ; 4 bytes
fat32_sectorspercluster: .res 1  ; 1 byte
fat32_pendingsectors:    .res 1  ; 1 byte
fat32_address:           .res 2  ; 2 bytes
fat32_nextcluster:       .res 4  ; 4 bytes
fat32_bytesremaining:    .res 4  ; 4 bytes
fat32_errorstage = fat32_bytesremaining
fat32_filenamepointer = fat32_bytesremaining


DPL: .res 1
DPH: .res 1

lcd_enable_pins:  .res 1
lcd_row:          .res 1
lcd_column:       .res 1

controller1: .res 3
controller2: .res 3