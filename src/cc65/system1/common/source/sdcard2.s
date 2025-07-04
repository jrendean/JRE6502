
.include "io.inc"
.include "zeropage.inc"

.import spi_rw_byte, spi_r_byte, spi_select_device, spi_deselect

.export sdcard_init, sdcard_detect
.export sd_select_card, sd_deselect_card
.export sd_read_block, sd_cmd, sd_cmd_lba
.export fullblock
.export sd_busy_wait

.export sd_write_block





;----------------------------------------------------------------------------------------------
; SD Card commands
;----------------------------------------------------------------------------------------------
cmd0     = $40       ; GO_IDLE_STATE
cmd1     = $40 + 1     ; SEND_OP_COND
cmd8     = $40 + 8   ; SEND_IF_COND
cmd12    = $40 + 12  ; STOP_TRANSMISSION
cmd16    = $40 + 16     ; SET_BLOCKLEN
cmd17    = $40 + 17    ; READ_SINGLE_BLOCK
cmd18    = $40 + 18    ; READ_MULTIPLE_BLOCK
cmd24    = $40 + 24    ; WRITE_BLOCK
cmd25    = $40 + 25    ; WRITE_MULTIPLE_BLOCK
cmd55    = $40 + 55    ; APP_CMD
cmd58    = $40 + 58    ; READ_OCR
acmd41    = $40 + 41    ; APP_SEND_OP_COND
acmd23    = $40 + 23    ; SET_WR_BLOCK_ERASE_COUNT - Define number of blocks to pre-erase with next multi-block write command.

sd_data_token = $fe
; SD CArd command parameter/result buffer
sd_cmd_param         = $02a0
sd_cmd_chksum        = sd_cmd_param+4

sd_cmd_response_retries = $08
sd_data_token_retries = $0f ; increase, card specific and must be larger for "huge" cards

; sd card R1 response status bits
sd_card_status_idle             = %00000001
sd_card_status_erase_reset      = %00000010
sd_card_status_illegal_command  = %00000100
sd_card_status_crc_error        = %00001000
sd_card_status_erase_seq_error  = %00010000
sd_card_status_address_error    = %00100000
sd_card_status_parameter_error  = %01000000

sd_card_error_timeout_busy = $c0
sd_card_error_timeout = $c1



.code

  ;    out:
  ;      Z=1 sd card available, Z=0 otherwise A=ENODEV
  sdcard_detect:
    lda SPI_PORT
    and #SDCARD_DETECT
    rts

  ;---------------------------------------------------------------------
  ; Init SD Card
  ; Destructive: A, X, Y
  ;
  ;    out:  Z=1 on success, Z=0 otherwise
  ;
  ;---------------------------------------------------------------------
  sdcard_init:
      lda #spi_device_sdcard
      jsr spi_select_device
      beq @init
      rts
    @init:
        ; 74 SPI clock cycles - !!!Note: spi clock cycle should be in range 100-400Khz!!!
            ldx #74

            ; set ALL CS lines and DO to HIGH
            lda #%11111110
            sta SPI_PORT

            tay
            iny

@l1:
            sty SPI_PORT
            sta SPI_PORT
            dex
            bne @l1

            jsr sd_select_card
            beq @next
            jmp @exit
@next:

            jsr sd_param_init

            ; CMD0 needs CRC7 checksum to be correct
            lda #$95
            sta sd_cmd_chksum

            ldy #sd_cmd_response_retries
@lcmd:
            dey
            bne @l2
            ;debug "sd_i_cmd0_max_retries"
            jmp @exit
@l2:
            ; send CMD0 - init SD card to SPI mode
            lda #cmd0
            phy
            jsr sd_cmd
            ply
            ; debug "CMD0"
            cmp #$01
            bne @lcmd

            lda #$01
            sta sd_cmd_param+2
            lda #$aa
            sta sd_cmd_param+3
            lda #$87
            sta sd_cmd_chksum


            lda #cmd8
            jsr sd_cmd
            ;debug32 "CMD8", sd_cmd_param

            jsr sd_param_init

            cmp #$01
            bne @l5
            ; Invalid Card (or card we can't handle yet)
            ; card must respond with $000001aa, otherwise we can't use it
            ;
            ; screw this
            jsr spi_r_byte
            ; and that
            jsr spi_r_byte

            ; is this $01? we're done if not
            jsr spi_r_byte
            cmp #$01
            beq @l3
            jmp @exit
@l3:

;            bne @exit

            ; is this $aa? we're done if not
            jsr spi_r_byte
            cmp #$aa
            bne @exit

            ; init card using ACMD41 and parameter $40000000
            lda #$40
            sta sd_cmd_param

@l5:
            lda #cmd55
            jsr sd_cmd

            cmp #$01
            bne @exit
            ; Init failed


            lda #acmd41
            jsr sd_cmd
            ;debug32 "ACMD41", sd_cmd_param

            cmp #$00
            beq @l7

            cmp #$01
            beq @l5

            cmp sd_cmd_param
            beq @exit        ; acmd41 with $40000000 and $00000000 failed, TODO: try CMD1

            jsr sd_param_init
            bra @l5

@l7:
            cmp sd_cmd_param
            beq @cmd16        ; acmd41 with $40000000 and $00000000 failed, TODO: try CMD1

            stz sd_cmd_param

            lda #cmd58
            jsr sd_cmd
            ;debug "CMD58"
            ; read result. we need to check bit 30 of a 32bit result
            jsr spi_r_byte
            ;debug "CMD58_r"
        ;    sta krn_tmp
            ;pha
            ; read the other 3 bytes and trash them
        ;    jsr spi_r_byte
        ;    jsr spi_r_byte
        ;    jsr spi_r_byte
            ; or don't read them at all. the next busy_wait will take care of everything

            ;pla
            and #%01000000
            bne @l9
@cmd16:
            jsr sd_param_init

            ; Set block size to 512 bytes
            lda #$02
            sta sd_cmd_param+2

            ;debug32 "cmd16p", sd_cmd_param

            lda #cmd16
            jsr sd_cmd
            ;debug "CMD16"
@exit_ok:
@l9:
    ; SD card init successful
            lda #$00
@exit:
            jmp sd_deselect_card

;---------------------------------------------------------------------
; Send SD Card Command
; in:
;     A - cmd byte
;     sd_cmd_param - parameters
; out:
;    A - SD Card R1 status byte in
;---------------------------------------------------------------------
sd_cmd:
            pha
            jsr sd_busy_wait
            pla
            ; transfer command byte
            jsr spi_rw_byte

            ; transfer parameter buffer
            ldx #$00
@l1:         lda sd_cmd_param,x
            phx
            jsr spi_rw_byte
            plx
            inx
            cpx #$05
            bne @l1

;---------------------------------------------------------------------
; wait for card response for command
; read max. 8 bytes (The response is sent back within command response time (NCR), 0 to 8 bytes for SDC, 1 to 8 bytes for MMC. )
; http://elm-chan.org/docs/mmc/mmc_e.html
; out:
; A - response of card, for error codes see sdcard.inc. $1F if no valid response within NCR
; Z=1 - no error
;---------------------------------------------------------------------
sd_cmd_response_wait:
            ldy #sd_cmd_response_retries
@l:        dey
            beq sd_block_cmd_timeout ; y already 0? then invalid response or timeout
            jsr spi_r_byte
            ;debug "sd_cm_wt"
            bmi @l
            ;debug "sd_cm_wt_e"
            rts
sd_block_cmd_timeout:
            ;debug "sd_cm_wtt"
            lda #$1f ; make up error code distinct from possible sd card responses to mark timeout
            rts


;---------------------------------------------------------------------
; Read block from SD Card
;in:
;    A - sd card cmd byte (cmd17, cmd18, cmd24, cmd25)
;    block lba in lba_addr
;
;out:
;    A - A = 0 on success, error code otherwise
;---------------------------------------------------------------------
sd_read_block:
            jsr sd_select_card

            jsr sd_cmd_lba
            lda #cmd17
            jsr sd_cmd
            bne @exit
            jsr fullblock

@exit:     ; fall through to sd_deselect_card

;---------------------------------------------------------------------
; deselect sd card, puSH CS line to HI and generate few clock cycles
; to allow card to deinit
;---------------------------------------------------------------------
sd_deselect_card:
        pha
        phy

        jsr spi_deselect

        ldy #$04
@l1:
        jsr spi_r_byte
        dey
        bne @l1

        ply
        pla

        rts

fullblock:
            ; wait for sd card data token
            lda #sd_data_token
            jsr sd_wait
            bne @exit

            ldy #$00
            jsr halfblock

            inc read_blkptr+1
            jsr halfblock

            jsr spi_r_byte        ; Read 2 CRC bytes
            jsr spi_r_byte
            lda #$00
@exit:
            rts

halfblock:
@l:
            jsr spi_r_byte
            sta (read_blkptr),y
            iny
            bne @l
            rts

;---------------------------------------------------------------------
; wait for sd card whatever
; in: A - value to wait for
; out: Z = 1, A = 1 when error (timeout)
;---------------------------------------------------------------------
sd_wait:
            sta sd_tmp
            ldy #sd_data_token_retries
            ldx #0
@l1:
            phx
            jsr spi_r_byte
            plx
            cmp sd_tmp
            beq @l2
            dex
            bne @l1
            dey
            bne @l1

            lda #sd_card_error_timeout
            rts
@l2:        lda #0
            rts


;---------------------------------------------------------------------
; select sd card, pull CS line to low
;---------------------------------------------------------------------
sd_select_card:
            lda #spi_device_sdcard
            sta SPI_PORT
            ;TODO FIXME race condition here!

; fall through to sd_busy_wait

;---------------------------------------------------------------------
; wait while sd card is busy
; Z = 1, A = 1 when error (timeout)
;---------------------------------------------------------------------
sd_busy_wait:
            ldx #$ff
@l1:         lda #$ff
            dex
            beq @err

            phx
            jsr spi_rw_byte
            plx
            cmp #$ff
            bne @l1

            lda #$00
            rts
@err:
            lda #sd_card_error_timeout_busy
            rts

;---------------------------------------------------------------------
; clear sd card parameter buffer
;---------------------------------------------------------------------
sd_param_init:
            ldx #$03
@l:
            stz sd_cmd_param,x
            dex
            bpl @l
            lda #$01
            sta sd_cmd_chksum
            rts

;---------------------------------------------------------------------
; write lba_addr in correct order into sd_cmd_param
; in:
;    lba_addr - LBA address
; out:
;    sd_cmd_param
;---------------------------------------------------------------------
sd_cmd_lba:
            ldx #$03
            ldy #$00
@l:
            lda lba_addr,x
            sta sd_cmd_param,y
            iny
            dex
            bpl @l
            rts





;---------------------------------------------------------------------
; Write block to SD Card
;in:
;    A - sd card cmd byte (cmd17, cmd18, cmd24, cmd25)
;    block lba in lba_addr
;
;out:
;    A - A = 0 on success, error code otherwise
;---------------------------------------------------------------------
sd_write_block:
            phx
            phy
            jsr sd_select_card

            jsr sd_cmd_lba
            lda #cmd24
            jsr sd_cmd
            bne @exit

            lda #sd_data_token
            jsr spi_rw_byte

            ldy #$00
@l2:        lda (write_blkptr),y
            phy
            jsr spi_rw_byte
            ply
            iny
            bne @l2

            inc write_blkptr+1

            ldy #$00
@l3:        lda (write_blkptr),y
            phy
            jsr spi_rw_byte
            ply
            iny
            bne @l3



            ; Send fake CRC bytes
            lda #$00
            jsr spi_rw_byte
            lda #$00
            jsr spi_rw_byte
            inc write_blkptr+1
            lda #$00

@exit:
            ply
            plx
            jmp sd_deselect_card

