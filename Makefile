####################################################################################
#	Create Date: 03.01.2024 18:50
#	Goal: create a simple full OS using fasm + mingw-gcc + c + ld + os-dev.org
#	Author: As_Almas
#	Description: wait for write...
#	
#	Status: Created. Configure project
#	Comment 0: null
#	Comment 1: null 
#	Comment 2: null
####################################################################################

TARGET = As_OS.img

SRC_BOOT_PREF = ./src/boot/

BOOT_OBJ_F	  = ./obj/boot/
BIN_PREFIX	  = ./bin/

ISO_app = ./ultraISO/UltraISO.exe
HEX_EDIT = "C:\Program Files\HxD\HxD.exe"

VBOX = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

OS_NAME = startvm "OS"
DEBUG_FLAGS =  -E VBOX_GUI_DBG_ENABLED=true

ASM = FASM
ASM_FLAGS = 

BOOT_OBJ = $(wildcard $(BOOT_OBJ_F)*.bin)


boot: 
	$(ASM) $(ASM_FLAGS) $(SRC_BOOT_PREF)bootloader.asm $(BOOT_OBJ_F)bootloader.bin

hex: $(BOOT_OBJ_F)bootloader.bin
	$(HEX_EDIT) $(BIN_PREFIX)$(TARGET) $(BOOT_OBJ_F)bootloader.bin

fs:
	$(ISO_app) $(BIN_PREFIX)$(TARGET)

clean:	
	del "$(BOOT_OBJ_F)\*.bin"

create_struct:
	mkdir "$(BOOT_OBJ_F)"


debug: $(BIN_PREFIX)$(TARGET)
	$(VBOX) $(OS_NAME) $(DEBUG_FLAGS)
