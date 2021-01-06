


  .macro loadptr, ptr, val
    lda #<(\val)
    sta \ptr
    lda #>(\val)
    sta \ptr + 1
  .endm
