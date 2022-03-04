## Copyright Cypress Semiconductor Corporation, 2010-2011,
## All Rights Reserved
## UNPUBLISHED, LICENSED SOFTWARE.
##
## CONFIDENTIAL AND PROPRIETARY INFORMATION
## WHICH IS THE PROPERTY OF CYPRESS.
##
## Use of this file is governed
## by the license agreement included in the file
##
##      <install>/license/license.txt
##
## where <install> is the Cypress software
## installation root directory path.
##

FX3FWROOT=$(FX3_INSTALL_PATH)

all:elf2img

include $(FX3FWROOT)/fw_build/fx3_fw/fx3_build_config.mak

MODULE = slfifo_uart

SOURCE= cyfxslfifosync.c 		\
	cyfxslfifousbdscr.c	\
	cyfxtx.c

ifeq ($(CYFXBUILD),arm)
SOURCE_ASM=cyfx_startup.S
else
SOURCE_ASM=cyfx_gcc_startup.S
endif

C_OBJECT=$(SOURCE:%.c=./%.o)
A_OBJECT=$(SOURCE_ASM:%.S=./%.o)

EXES = $(MODULE).$(EXEEXT)

$(MODULE).$(EXEEXT): $(A_OBJECT) $(C_OBJECT)
	$(LINK)

cyfxtx.c:
	cp $(FX3FWROOT)/fw_build/fx3_fw/cyfxtx.c .

cyfx_startup.S:
	cp $(FX3FWROOT)/fw_build/fx3_fw/cyfx_startup.S .

cyfx_gcc_startup.S:
	cp $(FX3FWROOT)/fw_build/fx3_fw/cyfx_gcc_startup.S .

$(C_OBJECT) : %.o : %.c
	$(COMPILE)

$(A_OBJECT) : %.o : %.S
	$(ASSEMBLE)

clean:
	rm -f ./$(MODULE).$(EXEEXT)
	rm -f ./$(MODULE).map
	rm -f ./*.o
	rm -f cyfxtx.c cyfx_startup.S cyfx_gcc_startup.S
	rm -f ./*.img


compile: $(C_OBJECT) $(A_OBJECT) $(EXES)

elf2img: compile
	$(FX3_INSTALL_PATH)/util/elf2img/elf2img -i $(MODULE).elf \
	-o $(MODULE).img -vectorload yes
	$(FX3_INSTALL_PATH)/util/elf2img/elf2img -i $(MODULE).elf \
	-o $(MODULE)_spi.img -vectorload yes -i2cconf
	$(FX3_INSTALL_PATH)/util/elf2img/elf2img -i $(MODULE).elf \
	-o $(MODULE)_i2c.img -vectorload yes -i2cconf 1E
