ASM = ../../vasm/vasm6502_oldstyle
ASMFLAGS = -Fbin -dotdir -c02 -ignore-mult-inc -chklabels

#ASM = ../../vasm/vasm6502_std
#ASMFLAGS = -Fbin -c02 -ignore-mult-inc -chklabels

TARGET = main

all: $(TARGET)

$(TARGET): $(TARGET).s
	mkdir ./out || true
	$(ASM) $(ASMFLAGS) -o ./out/$(TARGET).bin $(TARGET).s 

install: $(TARGET)
	minipro -p AT28C256 -w ./out/$(TARGET).bin
	
test: $(TARGET)
	hexdump -C ./out/$(TARGET).bin

clean:
	$(RM) ./out/$(TARGET).bin
