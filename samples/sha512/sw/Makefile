# Makefile -- Basic Makefile

# creating an application
TARGET = sha512

TARGET_HOST = host_$(TARGET)
TARGET_HARPSIM = harpsim_$(TARGET)
TARGET_HARP = harp_$(TARGET)

# where is the Clang/LLVM with support to Intel HARP offloading?
ifeq ($(wildcard $(LLVM)),)
$(error Set LLVM to the root directory of the Clang/LLVM with support to Intel HARP offloading)
endif
ifeq ($(wildcard $(LLVM)/lib/libomptarget.so),)
$(error Set LLVM to the root directory of the Clang/LLVM with support to Intel HARP offloading)
endif
ifeq ($(wildcard $(LLVM)/lib/libomptarget.rtl.harpsim.so),)
$(error Set LLVM to the root directory of the Clang/LLVM with support to Intel HARP offloading)
endif

# libraries to use, objects to compile
SRCS = sha512.cpp main.cpp
SRCS_FILES = $(foreach F, $(SRCS), src/$(F))
COMMON_FILES =

INCLUDES = -Iinclude -L$(LLVM)/lib

LIBS = -lomptarget

COMPILE = $(LLVM)/bin/clang++

ARGS_HOST = -O3
ARGS_HARPSIM = -fopenmp -fopenmp-targets=harpsim -DTARGET=HARPSIM
ARGS_HARP = -fopenmp -fopenmp-targets=harp -DTARGET=HARP

# Make it all!
all: folder host harpsim harp

host:
	$(COMPILE) $(ARGS_HOST) $(INCLUDES) $(LIBS) $(SRCS_FILES) -o build/$(TARGET_HOST)

harpsim:
	$(COMPILE) $(ARGS_HARPSIM) $(INCLUDES) $(LIBS) $(SRCS_FILES) -o build/$(TARGET_HARPSIM)

harp:
	$(COMPILE) $(ARGS_HARP) $(INCLUDES) $(LIBS) $(SRCS_FILES) -o build/$(TARGET_HARP)

ir:
	$(COMPILE) $(ARGS_HOST) $(INCLUDES) src/sha512.cpp -S -mllvm --x86-asm-syntax=intel -o build/$(TARGET).asm

folder:
	mkdir -p build/

clean:
	rm -rf build/

# taf!
