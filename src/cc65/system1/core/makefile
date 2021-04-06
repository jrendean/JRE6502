PROJECT_NAME=system1

ASM_SOURCES=main.s debugger.s
C_SOURCES=
#COMMON_DEPS1=via.o led.o utils.o console.o zeropage.o strings.o modem2.o debug.o keyboard.o snes.o memory.o spi.o sdcard.o fat32.o rtc.o s
COMMON_DEPS1=via.o led.o utils.o console.o zeropage.o strings.o modem2.o debug.o keyboard.o snes.o memory.o spi.o sdcard2.o rtc.o 

ifndef LCD_TYPE
	LCD_TYPE=40
endif

ifeq ($(LCD_TYPE), 40)
	COMMON_DEPS=$(COMMON_DEPS1) lcd40x4.o
else ifeq ($(LCD_TYPE), 20) 
	COMMON_DEPS=$(COMMON_DEPS1) lcd20x4.o
else
	$(error Invalid lcd type: $(LCD_TYPE))
endif

include ../common/makefile