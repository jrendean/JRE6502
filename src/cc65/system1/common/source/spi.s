
.include "io.inc"
.include "zeropage.inc"

; 
; https://bitbucket.org/steckschwein/steckschwein-code/src/master/steckos/libsrc/spi/
; 

.export spi_select_device, spi_deselect, spi_r_byte, spi_rw_byte

EOK = 0
EBUSY = 6

.code


  ; select spi device given in A. the method is aware of the current processor state, especially the interrupt flag
  ; in:
  ;    A = spi device - one of
  ;        spi_device_sdcard    =   %00011100 ;spi device number 1110??? (SPI_SS1)
  ;        spi_device_keyboard =   %00011010 ;spi device number 1101??? (SPI_SS2)
  ;        spi_device_rtc        =   %00010110 ;spi device number 1011??? (SPI_SS3)
  ; out:
  ;    Z = 1 spi for given device could be selected (not busy), Z=0 otherwise
  spi_select_device:
        php
        sei ;critical section start
        pha

        ;check busy and select within sei => !ATTENTION! is busy check and spi device select must be "atomic", otherwise the spi state may change in between
        ;    Z=1 not busy, Z=0 spi is busy and A=#EBUSY
  spi_isbusy:
        lda SPI_PORT
        and #%00011110
        cmp #%00011110
        bne @l_exit        ;busy, leave section, device could not be selected

        pla
        sta SPI_PORT

        plp
        lda #EOK            ;exit ok
        rts
  @l_exit:
        pla
        plp                ;restore P (interrupt flag)
        lda #EBUSY
        rts



  spi_deselect:
        pha
        lda #spi_device_deselect
        sta SPI_PORT
        pla
        rts


;----------------------------------------------------------------------------------------------
; Receive byte VIA SPI
; Received byte in A at exit, Z, N flags set accordingly to A
; Destructive: A,X
;----------------------------------------------------------------------------------------------
spi_r_byte:
        lda SPI_PORT    ; Port laden
        AND #$fe          ; Takt ausschalten
        TAX                         ; aufheben
        INC

        STA SPI_PORT ; Takt An 1
        STX SPI_PORT ; Takt aus
        STA SPI_PORT ; Takt An 2
        STX SPI_PORT ; Takt aus
        STA SPI_PORT ; Takt An 3
        STX SPI_PORT ; Takt aus
        STA SPI_PORT ; Takt An 4
        STX SPI_PORT ; Takt aus
        STA SPI_PORT ; Takt An 5
        STX SPI_PORT ; Takt aus
        STA SPI_PORT ; Takt An 6
        STX SPI_PORT ; Takt aus
        STA SPI_PORT ; Takt An 7
        STX SPI_PORT ; Takt aus
        STA SPI_PORT ; Takt An 8
        STX SPI_PORT ; Takt aus

        lda SPI_SR
        rts


;----------------------------------------------------------------------------------------------
; Transmit byte VIA SPI
; Byte to transmit in A, received byte in A at exit
; Destructive: A,X,Y
;----------------------------------------------------------------------------------------------
spi_rw_byte:
        sta spi_sr    ; zu transferierendes byte im akku retten

        ldx #$08

        lda SPI_PORT    ; Port laden
        and #$fe          ; SPICLK loeschen

        asl                ; Nach links rotieren, damit das bit nachher an der richtigen stelle steht
        tay                 ; bunkern

@l:
        rol spi_sr
        tya                ; portinhalt
        ror                ; datenbit reinschieben

        sta SPI_PORT    ; ab in den port
        inc SPI_PORT    ; takt an
        sta SPI_PORT    ; takt aus

        dex
        bne @l            ; schon acht mal?

        lda SPI_SR        ; Schieberegister auslesen

        rts
