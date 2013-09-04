# Copyright (C) 2013 - Adam Green (http://mbed.org/users/AdamGreen/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# Can skip parsing of this makefile if user hasn't requested this library.
ifeq "$(findstring $(LIBRARY),$(MBED_LIBS))" "$(LIBRARY)"


# Directories where source files are found and output files should be placed.
ROOT            :=$(GCC4MBED_DIR)/external/mbed/libraries/$(LIBRARY)
RELEASE_DIR     :=$(GCC4MBED_DIR)/external/mbed/libraries/Release/$(MBED_TARGET)
DEBUG_DIR       :=$(GCC4MBED_DIR)/external/mbed/libraries/Debug/$(MBED_TARGET)
RELEASE_OBJ_DIR :=$(RELEASE_DIR)/$(LIBRARY)
DEBUG_OBJ_DIR   :=$(DEBUG_DIR)/$(LIBRARY)


# Release and Debug target libraries for C and C++ portions of library.
LIB_NAME     := $(LIBRARY).a
RELEASE_LIB  := $(RELEASE_DIR)/$(LIB_NAME)
DEBUG_LIB    := $(DEBUG_DIR)/$(LIB_NAME)


# Build up list of all C, C++, and Assembly Language files to be compiled/assembled.
C_SRCS   := $(wildcard $(ROOT)/*.c $(ROOT)/*/*.c $(ROOT)/*/*/*.c $(ROOT)/*/*/*/*.c $(ROOT)/*/*/*/*/*.c)
ASM_SRCS :=  $(wildcard $(ROOT)/*.S $(ROOT)/*/*.S $(ROOT)/*/*/*.S $(ROOT)/*/*/*/*.S $(ROOT)/*/*/*/*/*.S)
ifneq "$(OS)" "Windows_NT"
ASM_SRCS +=  $(wildcard $(ROOT)/*.s $(ROOT)/*/*.s $(ROOT)/*/*/*.s $(ROOT)/*/*/*/*.s $(ROOT)/*/*/*/*/*.s)
endif
CPP_SRCS := $(wildcard $(ROOT)/*.cpp $(ROOT)/*/*.cpp $(ROOT)/*/*/*.cpp $(ROOT)/*/*/*/*.cpp $(ROOT)/*/*/*/*/*.cpp)


# Convert list of source files to corresponding list of object files to be generated.
# Debug and Release object files to go into separate sub-directories.
OBJECTS := $(patsubst $(ROOT)/%.cpp,__Output__/%.o,$(CPP_SRCS))
OBJECTS += $(patsubst $(ROOT)/%.c,__Output__/%.o,$(C_SRCS))
OBJECTS += $(patsubst $(ROOT)/%.s,__Output__/%.o,$(patsubst $(ROOT)/%.S,__Output__/%.o,$(ASM_SRCS)))

DEBUG_OBJECTS   := $(patsubst __Output__%,$(DEBUG_OBJ_DIR)%,$(OBJECTS))
RELEASE_OBJECTS := $(patsubst __Output__%,$(RELEASE_OBJ_DIR)%,$(OBJECTS))


# List of the header dependency files, one per object file.
DEBUG_DEPFILES   := $(patsubst %.o,%.d,$(DEBUG_OBJECTS))
RELEASE_DEPFILES := $(patsubst %.o,%.d,$(RELEASE_OBJECTS))


# Include path based on all directories in this library.
SUBDIRS       := $(wildcard $(ROOT)/* $(ROOT)/*/* $(ROOT)/*/*/* $(ROOT)/*/*/*/* $(ROOT)/*/*/*/*/*)
PROJINCS      := $(sort $(dir $(SUBDIRS)))


# Append to main project's include path.
MBED_INCLUDES += $(ROOT) $(PROJINCS)


# Optimization levels to be used for Debug and Release versions of the library.
DEBUG_OPTIMIZATION   := 0
RELEASE_OPTIMIZATION := 2


# Compiler flags used to enable creation of header dependency files.
DEP_FLAGS := -MMD -MP


# Preprocessor defines to use when compiling/assembling code with GCC.
GCC_DEFINES := -DTARGET_$(MBED_TARGET_DEVICE) -DTARGET_$(MBED_DEVICE) -DTOOLCHAIN_GCC_ARM -DTOOLCHAIN_GCC $(MBED_DEFINES)

# Flags to be used with C/C++ compiler that are shared between Debug and Release builds.
C_FLAGS := -g3 $(MBED_TARGET_C_FLAGS) 
C_FLAGS += -ffunction-sections -fdata-sections -fno-exceptions -fno-delete-null-pointer-checks -fomit-frame-pointer
C_FLAGS += -Wall -Wextra
C_FLAGS += -Wno-unused-parameter -Wno-missing-field-initializers -Wno-missing-braces
C_FLAGS += $(patsubst %,-I%,$(INCLUDE_DIRS))
C_FLAGS += $(GCC_DEFINES)
C_FLAGS += $(DEP_FLAGS)

CPP_FLAGS := $(C_FLAGS) -fno-rtti -std=gnu++11
C_FLAGS   += -std=gnu99


# Customize C/C++ flags for Debug and Release builds.
$(DEBUG_LIB): C_FLAGS   := $(C_FLAGS) -O$(DEBUG_OPTIMIZATION)
$(DEBUG_LIB): CPP_FLAGS := $(CPP_FLAGS) -O$(DEBUG_OPTIMIZATION)

$(RELEASE_LIB): C_FLAGS   := $(C_FLAGS) -O$(RELEASE_OPTIMIZATION) -DNDEBUG
$(RELEASE_LIB): CPP_FLAGS := $(CPP_FLAGS) -O$(RELEASE_OPTIMIZATION) -DNDEBUG


# Flags used to assemble assembly languages sources.
ASM_FLAGS := -g3 $(MBED_ASM_FLAGS) -x assembler-with-cpp
ASM_FLAGS += $(GCC_DEFINES)
ASM_FLAGS += $(patsubst %,-I%,$(INCLUDE_DIRS))
$(RELEASE_LIB): ASM_FLAGS := $(ASM_FLAGS)
$(DEBUG_LIB):   ASM_FLAGS := $(ASM_FLAGS)


#########################################################################
# High level rules for building Debug and Release versions of library.
#########################################################################
$(RELEASE_LIB): $(RELEASE_OBJECTS)
	@echo Linking release library $@
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(AR) -rc $@ $+

$(DEBUG_LIB): $(DEBUG_OBJECTS)
	@echo Linking debug library $@
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(AR) -rc $@ $+

-include $(DEBUG_DEPFILES)
-include $(RELEASE_DEPFILES)


#########################################################################
#  Default rules to compile c/c++/assembly language sources to objects.
#########################################################################
$(DEBUG_OBJ_DIR)/%.o : $(ROOT)/%.c
	@echo Compiling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(C_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(RELEASE_OBJ_DIR)/%.o : $(ROOT)/%.c
	@echo Compiling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(C_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(DEBUG_OBJ_DIR)/%.o : $(ROOT)/%.cpp
	@echo Compiling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GPP) $(CPP_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(RELEASE_OBJ_DIR)/%.o : $(ROOT)/%.cpp
	@echo Compiling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GPP) $(CPP_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(DEBUG_OBJ_DIR)/%.o : $(ROOT)/%.s
	@echo Assembling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(ASM_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(RELEASE_OBJ_DIR)/%.o : $(ROOT)/%.s
	@echo Assembling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(ASM_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(DEBUG_OBJ_DIR)/%.o : $(ROOT)/%.S
	@echo Assembling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(ASM_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(RELEASE_OBJ_DIR)/%.o : $(ROOT)/%.S
	@echo Assembling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(ASM_FLAGS) $(MBED_INCLUDES) -c $< -o $@


endif # ifeq "$(findstring $(LIBRARY),$(MBED_LIBS))"...
