
.import  _console_write_string, _console_write_char, _console_write_hex

; 
.macro loadptr ptr, val
    lda #<(val)
    sta ptr
    lda #>(val)
    sta ptr + 1
.endmacro




.macro copypointer fromptr, toptr
	.repeat 2, i
		lda fromptr+i
		sta toptr	+i
	.endrepeat
.endmacro

.macro saveptr ptr
	lda ptr
	pha
	lda ptr+1
	pha
.endmacro

.macro restoreptr ptr
	pla
	sta ptr+1
	pla
	sta ptr
.endmacro


.macro memcpy src, dest, n
		.local @l
		;.assert n<$80, error, "n must not >=$80"
		ldy #n-1
@l:
		lda src,y
		sta dest,y
		dey
		bpl @l
.endmacro

.macro memcpy2ptr src, ptr, n
		.local @l
		;.assert n<$80, error, "n must not >=$80"
		ldy #n-1
@l:		lda src,y
		sta (ptr),y
		dey
		bpl @l
.endmacro

.macro memset dest, value, n
		.local @l
		;.assert n<$80, error, "n must not >=$80"
		ldy #n-1
		lda #value
@l:		sta dest,y
		dey
		bpl @l
.endmacro

.macro memclr dest, n
		;.assert n<$80, error, "n must not >=$80"
		.local @l
		ldx #n-1
@l:		stz dest,x
		dex
		bpl @l
.endmacro





.macro consoleprint msg
    ldstr console_out_ptr, msg
    jsr _console_write_string
.endmacro

.macro debug msg
    ldstr console_out_ptr, msg
    jsr _console_write_string
.endmacro

.macro debug32 msg, addr
    ldstr console_out_ptr, msg
    jsr _console_write_string
    lda addr
    jsr _console_write_hex
.endmacro






.macro _incZPWord wordp
	inc wordp
	;db	0xd0, 0x02
	.dbyt	$d0, $02
	inc wordp+1
.endmacro


.macro _cpyZPWord worda,wordb
	lda worda
	sta wordb
	lda worda+1
	sta wordb+1
.endmacro

