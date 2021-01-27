
;  .ifndef MACROS_INC
;  .defc MACROS_INC


  .macro loadptr, ptr, val
    ;pha
    lda #<(\val)
    sta \ptr
    lda #>(\val)
    sta \ptr + 1
    ;pla
  .endm

  .macro copyptr, src, dest
    ;pha
    lda \src
    sta \dest
    lda (\src) + 1
    sta \dest + 1
    ;pla
  .endm


;  .endif
  