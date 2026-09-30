BUILD_FOLDER=build
ROM_FOLDER=$(BUILD_FOLDER)/rom

ADDRESS_MODE=basic

FIRMWARE_PROJECTS = blink \
                    lcd4b \
					acia

FIRMWARE_BINARIES=$(FIRMWARE_PROJECTS:%=$(ROM_FOLDER)/%.$(ADDRESS_MODE).bin)

$(ROM_FOLDER)/%.$(ADDRESS_MODE).bin:
	$(MAKE) -C $(@:$(ROM_FOLDER)/%.$(ADDRESS_MODE).bin=%) ADDRESS_MODE=$(ADDRESS_MODE) all

all: $(FIRMWARE_BINARIES)

clean:
ifeq ($(OS),Windows_NT)
	@if exist "$(subst /,\,$(BUILD_FOLDER))" rmdir /S /Q "$(subst /,\,$(BUILD_FOLDER))"
else
	rm -rf "$(BUILD_FOLDER)"
endif
