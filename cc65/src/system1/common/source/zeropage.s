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

DPL: .res 1
DPH: .res 1
