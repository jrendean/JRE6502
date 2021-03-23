
.include "zeropage.inc"

.export str_length, str_compare, str_trim

  ; 
  ; IN: 
  ; OUT: A is the length of the string
  ; ZP: ptr1
  str_length:
    phy       ; save Y
    ldy #0    ; set Y to 0
  @loop:
    lda (ptr1), y ; load value from ptr1 index Y in to A
    beq @done   ; if value equals 0 branch to @done
    iny       ; increment Y
    bra @loop   ; branch back
  @done:
    tya       ; transfer Y to A
    ply       ; restore Y
    rts       ; return


  ; http://6502.org/source/strings/comparisons.html
  ; 
  ; 
  ; 
  ; 
  str_compare:
      phy
      ldy #$00
  @compare:
      lda (ptr1),y
      beq @ptr1_end
      cmp (ptr2),y
      bne @set_result
      iny
      beq @equal ; prevention against infinite loop
      bra @compare
  @ptr1_end:
      cmp (ptr2),y
  @set_result:
      beq @equal
      bmi @less_than
      lda #$01
      bra @return
  @equal:
      lda #$00
      bra @return
  @less_than:
      lda #$ff
      bra @return
  @return:
      ply
      rts



  ; 
  ; 
  ; 
  ; 
  str_trim:
    phy
    ldy #0
  @loop:
    lda (ptr1), y
    beq @done

  @done:
    ply
    rts
