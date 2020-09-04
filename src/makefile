ASM = ../vasm/vasm6502_oldstyle
ASMFLAGS = -Fbin -dotdir

TARGET = blink

all: $(TARGET)

$(TARGET): $(TARGET).s
	$(ASM) $(ASMFLAGS) -o $(TARGET).bin $(TARGET).s 

install: $(TARGET)
	minpro -p AT28C256 -w $(TARGET).bin
	
test: $(TARGET)
	hexdump -C $(TARGET).bin

clean:
	$(RM) $(TARGET).bin
