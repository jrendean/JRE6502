
.include "zeropage.inc"

.import __RAM_START__, __RAM_SIZE__
.export mem_clear

mem_clear:
	lda #$00
	sta ptr1
	lda #>__RAM_START__
	sta ptr1+1
	ldx #>__RAM_SIZE__
:	lda #$00
	tay
:	sta (ptr1),y
	dey
	bne :-
	inc ptr1+1
	dex
	bne :--
  rts