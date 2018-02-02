# This is Makefile defines how to compile all of the libraries and applications
# in the SDK.
# See README.txt for instructions on how to get started using this SDK.
# type `make` or `make apps` to make all of the apps in the apps folder
# type `make APPNAME` to make a specific app
# type `make libs` to make all the libraries

.DEFAULT_GOAL := apps

#### Programs used by this Makefile ############################################
CC := sdcc#         C compiler: creates object files (.rel) from C files (.c)
AS := sdas8051#     Assembler:  creates object files (.rel) from assembly files (.s)
AR := sdcclib#      Librarian:  creates .lib
LD := sdld#         Linker:     creates .hex files from .rel/.lib files)
PACKIHX := packihx# makes .hex files smaller
MV := move#         moves files
CP := cp#           copies files
CAT := cat#         outputs files
ECHO := echo#       outputs some text to the standard output
GREP := grep#       outputs lines from a file that match a given pattern
SED := sed#         edits files
WIXELCMD := wixelcmd# loads programs on the Wixel (command-line utility)
WIXELCONFIG := wixelconfig # Wixel Configuration Utility (GUI)

#### Include directories #######################################################
INCDIRS += libraries/include
I_FLAGS = $(patsubst %,-I%,$(INCDIRS))

#### Compilation options #######################################################

# Generate dependency information
C_FLAGS += -Wp,-MD,$(@:%.rel=%.d),-MT,$@,-MP

# Disable warning 110: conditional flow changed by optimizer
WARNING := --disable-warning 110
C_FLAGS += $(WARNINGS)

# Add the include directories
C_FLAGS += $(I_FLAGS)

# Disable pagination in .lst file
C_FLAGS += -Wa,-p
AS_FLAGS += -p

# Put the output in the right place.
PPC_FLAGS += -Wp,-o,$@

MODEL = --model-medium
C_FLAGS += $(MODEL)
LD_FLAGS += $(MODEL)

# Generate debugging information (.cdb files).
C_FLAGS += --debug
LD_FLAGS += --debug

#### Code area options #########################################################
# --code-loc  corresponds to the "-b HOME =" linker argument
# --code-size corresponds to the "-w" argument to the linker

# CODE_AREA_FULL: Uses all 32k on the chip.
CODE_AREA_FULL = --code-loc 0x0000 --code-size 0x8000

# CODE_AREA_APP: Creates an application that can be loaded with the bootloader,
# using only kilobytes 1-29 inclusive.
CODE_AREA_APP = --code-loc 0x0400 --code-size 0x7400

# The default code area is CODE_AREA_APP.
CODE_AREA := $(CODE_AREA_APP)
LD_FLAGS += $(CODE_AREA)

#### Linking options ###########################################################

# The size of internal ram.  ("-a" argument to the linker)
LD_FLAGS += --iram-size 0x0100

# XRAM location.  ("-b XSEG =" and "-b PSEG =" arguments to linker)
LD_FLAGS += --xram-loc 0xF000

# XRAM size. ("-v" argument to linker)
LD_FLAGS += --xram-size 0xF00

# Put the output in the right place.
LD_FLAGS += -o $(@:%.hex=%.ihx)

#### MODULES ###################################################################
TARGETS :=
RELs :=
LIBs :=
HEXs :=

include libraries/libs.mk
include apps.mk

#### FILES TYPES ###############################################################
# .c   : This is a file that contains source code in the C language.
# .h   : Header file in the C language (part of the source code).
# .s   : Assembly language source code.
#
# .rel : This is an Object file, the result of compiling a .s or .c file.
# .lib : This is a library (a collection of several object files).
# .hex : This is a complete program that can be loaded onto a Wixel.
#
# The lists of all .rel/lib/hex files compiled by this Makefile are in the
# following variables: $(RELs) $(LIBs) $(HEXs)

# These files are generated when compiling a .c file.
Ds := $(RELs:%.rel=%.d)      # .d : dependency information
CDBs := $(RELs:%.rel=%.cdb)  # .cdb : debugging information
ADBs := $(RELs:%.rel=%.adb)  # .adb : debugging information
ASMs := $(RELs:%.rel=%.asm)  # .asm : assembly generated by compiler

# These files are generated when compiling a .s or .c file.
SYMs := $(RELs:%.rel=%.sym)  # .sym : symbol table
LSTs := $(RELs:%.rel=%.lst)  # .lst : listing without absolute addresses
RSTs := $(RELs:%.rel=%.rst)  # .rst : listing with absolute addresses

# These files are generated when linking:
MEMs := $(HEXs:%.hex=%.mem)  # .mem : summary of memory usage
MAPs := $(HEXs:%.hex=%.map)  # .map : list of all addresses and memory sections
LKs  := $(HEXs:%.hex=%.lk)   # .lk  : args used by the linker
LNKs := $(HEXs:%.hex=%.lnk)  # .lnk : args used by the linker (prior to SDCC 3.1.0)
CDBs := $(HEXs:%.hex=%.cdb)  # .cdb : debugging information
OMFs := $(HEXs:%.hex=%) $(HEXs:%.hex=%.omf) # .omf : had no extension prior to SDCC 3.1.0

# These files can be generated from a .hex and .cdb file.
WXLs := $(HEXs:%.hex=%.wxl)  # .wxl : Wixel application
WXLs += $(HEXs:%.hex=%.wxl.tmp)

#### TARGETS ###################################################################
TARGETS += $(RELs) $(HEXs) $(LIBs)

all: $(TARGETS) apps

.PHONY: clean
clean:
	-@rm -fv $(TARGETS)
	-@rm -fv $(CLEAN)
	-@rm -fv $(Ds)
	-@rm -fv $(SYMs)
	-@rm -fv $(CDBs)
	-@rm -fv $(MEMs)
	-@rm -fv $(RSTs)
	-@rm -fv $(MAPs)
	-@rm -fv $(LSTs)
	-@rm -fv $(LKs)
	-@rm -fv $(LNKs)
	-@rm -fv $(BINs)
	-@rm -fv $(ASMs)
	-@rm -fv $(OMFs)
	-@rm -fv $(ADBs)
	-@rm -fv $(CDBs)
	-@rm -fv $(WXLs)

#### COMPLETE COMMANDS #########################################################

ifdef VERBOSE
COMPILE_COMMAND  = $(CC) -c $< $(C_FLAGS) -o $@
ASSEMBLE_COMMAND = $(AS) -glos $(AS_FLAGS) $<
ARCHIVE_COMMAND  = $(AR) $@ $^
LINK_COMMAND     = $(CC) $(LD_FLAGS) libraries/xpage/xpage.rel $^
else
V=@
COMPILE_COMMAND  = @echo Compiling  $@ && $(CC) -c $< $(C_FLAGS) -o $@
ASSEMBLE_COMMAND = @echo Assembling $@ && $(AS) -glos $(AS_FLAGS) $<
ARCHIVE_COMMAND  = @echo Creating   $@ && $(AR) $@ $^
LINK_COMMAND     = @echo Linking    $@ && $(CC) $(LD_FLAGS) libraries/xpage/xpage.rel $^
endif

#### IMPLICIT RULES ############################################################

%.rel: %.c
	$(COMPILE_COMMAND)

%.rel: %.s
	$(ASSEMBLE_COMMAND)

%.lib:
	$(V)rm -f $@
	$(ARCHIVE_COMMAND)

#%.hex: %.rel
#   $(LINK_COMMAND)
#	@mv -f $(@:%.hex=%.ihx) $@

%.wxl: %.hex
	@echo Packaging  $@
	$(V)$(ECHO) Pololu Wixel Application - www.pololu.com> $@.tmp
	$(V)$(ECHO) 1.0>> $@.tmp
	$(V)$(ECHO) ====== license>> $@.tmp
	$(V)$(CAT) LICENSE.txt >> $@.tmp
	$(V)$(ECHO) ====== cdb>> $@.tmp
	$(V)$(GREP) param $(<:%.hex=%.cdb) >> $@.tmp || echo "(This app has no params.)"
	$(V)$(ECHO) ====== hex>> $@.tmp
	$(V)$(PACKIHX) $< >> $@.tmp
	$(V)$(SED) -e "s/\r//g" $@.tmp > $@
	$(V)$(RM) $@.tmp

# Include all the dependency files generated during compilation so that Make
# knows which .rel files to recompile when a .h file changes.
-include $(Ds)
