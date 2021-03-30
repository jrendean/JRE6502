PROJECT_NAME=system1

ASM_SOURCES=main.s
C_SOURCES=
COMMON_DEPS1=via.o led.o utils.o console.o zeropage.o strings.o modem2.o debug.o keyboard.o spi.o sdcard.o fat32.o rtc.o snes.o

LCD_TYPE=20
ifeq ($(LCD_TYPE), 40)
	COMMON_DEPS=$(COMMON_DEPS1) lcd40x4.o
else ifeq ($(LCD_TYPE), 20) 
	COMMON_DEPS=$(COMMON_DEPS1) lcd20x4.o
else
	$(error Invalid lcd type: $(LCD_TYPE))
endif

include ../common/makefile