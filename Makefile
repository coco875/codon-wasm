BUILD_DIR := build

DEBUG = 1

ALL_DIR_CODE := lib lib/ src runtime-wasi/fmt/src runtime-wasi stdlib

DUMMY != mkdir -p $(foreach dir,$(ALL_DIR_CODE),$(BUILD_DIR)/$(dir))

# recursive wildcard
rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))
C_FILE := $(call rwildcard,src,*.c)
C_FILE += $(wildcard lib/*.c)

CPP_FILE := $(call rwildcard,src,*.cpp)
CPP_FILE += $(wildcard lib/*.cpp)
CPP_FILE += runtime-wasi/exc.cpp runtime-wasi/lib.cpp
CC_FILE := runtime-wasi/fmt/src/format.cc

PYTHON_FILE := $(call rwildcard,src,*.codon)

ALL_O := $(foreach file,$(C_FILE),$(file:%.c=$(BUILD_DIR)/%.o)) 
ALL_O += $(foreach file,$(CPP_FILE),$(file:%.cpp=$(BUILD_DIR)/%.o))
ALL_O += $(foreach file,$(CC_FILE),$(file:%.cc=$(BUILD_DIR)/%.o))
ALL_O += $(foreach file,$(PYTHON_FILE),$(file:%.codon=$(BUILD_DIR)/%.o))

MOD_NAME := test

INCLUDE_DIRS=lib include runtime-wasi/fmt/include runtime-wasi/fast_float/include

CC := emcc
CPP := em++
CC_FLAGS := $(foreach i,$(INCLUDE_DIRS),-I$(i))
ifeq ($(DEBUG), 1)
CC_FLAGS += -g
else
CC_FLAGS += -O3
endif
PYTHON_COMPILER := codon build
CODON_FLAGS := --march=wasm32 --obj
ifeq ($(DEBUG), 1)
CODON_FLAGS += --debug
else
CODON_FLAGS += --release
endif

$(MOD_NAME): $(MOD_NAME).wasm

$(BUILD_DIR)/%.o: %.c
	$(CC) -c $(CC_FLAGS) -o $@ $<

$(BUILD_DIR)/%.o: %.cpp
	$(CPP) -c $(CC_FLAGS) -o $@ $<

$(BUILD_DIR)/%.o: %.cc
	$(CPP) -c -std=c++20 $(CC_FLAGS) -o $@ $<

$(BUILD_DIR)/%.o: %.codon
	$(PYTHON_COMPILER) $(CODON_FLAGS) -o $@ $<

$(MOD_NAME).wasm: $(ALL_O)
	$(CC) $^ -o $(MOD_NAME).wasm $(CC_FLAGS) -s LINKABLE=1 -s EXPORT_ALL=1 -s PURE_WASI=1

clean:
	rm $(MOD_NAME).wasm build -r