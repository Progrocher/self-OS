####################################################################################
#	Create Date: 03.01.2024 18:50
#	Goal: create a simple bootloader and simple core
#	Author: As_Almas
#	Description: wait for write...
#	
#	Status: 
####################################################################################

TARGET = As_OS.img

SRC_BOOT_PREF = ./src/boot/

BOOT_OBJ_F	  = ./obj/
BIN_PREFIX	  = ./bin/

ISO_app = UltraISO.exe
HEX_EDIT = HxD.exe

VBOX = VBoxManage.exe startvm

OS_NAME = "AS_OS" 
DEBUG_FLAGS =  -E VBOX_GUI_DBG_ENABLED=true

ASM = FASM
ASM_FLAGS = 

boot: 
	$(ASM) $(ASM_FLAGS) $(SRC_BOOT_PREF)bootloader.asm $(BOOT_OBJ_F)bootloader.bin

hex: $(BOOT_OBJ_F)bootloader.bin
	$(HEX_EDIT) $(BIN_PREFIX)$(TARGET) $(BOOT_OBJ_F)bootloader.bin

fs:
	$(ISO_app) $(BIN_PREFIX)$(TARGET)

clean:	
	del "$(BOOT_OBJ_F)\*.bin"

debug: $(BIN_PREFIX)$(TARGET)
	$(VBOX) $(OS_NAME) $(DEBUG_FLAGS)
