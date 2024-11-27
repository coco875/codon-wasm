BUILD_DIR := build

DEBUG = 1

ALL_DIR_CODE := src runtime-wasi/fmt/src runtime-wasi

DUMMY != mkdir -p $(foreach dir,$(ALL_DIR_CODE),$(BUILD_DIR)/$(dir))

# recursive wildcard
rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))
C_FILE := $(call rwildcard,src,*.c)

CPP_FILE := $(call rwildcard,src,*.cpp)
CPP_FILE += $(wildcard lib/*.cpp)
CPP_FILE += runtime-wasi/exc.cpp runtime-wasi/lib.cpp
CC_FILE := runtime-wasi/fmt/src/format.cc

PYTHON_FILE := src/mainpy.codon

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
CODON_FLAGS := --llvm -numerics=py
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

$(BUILD_DIR)/src/mainpy.o: $(call rwildcard,src,*.codon)
	$(PYTHON_COMPILER) $(CODON_FLAGS) -o $(BUILD_DIR)/src/mainpy.ll src/mainpy.codon
	cat $(BUILD_DIR)/src/mainpy.ll | sed -e "s/{} @fflush(ptr/i32 @fflush(ptr/g" > $(BUILD_DIR)/src/mainpy_fflush.ll
	cat $(BUILD_DIR)/src/mainpy_fflush.ll | \
		sed -e "s/i64 @strlen(ptr/i32 @strlen(ptr/g" | \
		sed -e "s/insertvalue { i64, ptr } undef, i64 %8, 0/insertvalue { i32, ptr } undef, i32 %8, 0/g" | \
		sed -e "s/insertvalue { i64, ptr } %9, ptr %7, 1/insertvalue { i32, ptr } %9, ptr %7, 1/g" | \
		sed -e "s/store { i64, ptr } %10, ptr %11, align 8/store { i32, ptr } %10, ptr %11, align 8/g" \
		> $(BUILD_DIR)/src/mainpy_strlen.ll
	cat $(BUILD_DIR)/src/mainpy_strlen.ll | sed -e "s/define i32 @main(i32 %argc/define i32 @__main_argc_argv(i32 %argc/g" > $(BUILD_DIR)/src/mainpy_mod.ll
	llc -march=wasm32 -filetype=obj $(BUILD_DIR)/src/mainpy_mod.ll -o $(BUILD_DIR)/src/mainpy.o

$(MOD_NAME).wasm: $(ALL_O)
	$(CC) $^ -o $(MOD_NAME).wasm $(CC_FLAGS) -s EXPORT_ALL=1 -s STANDALONE_WASM=1 -s PURE_WASI=1

clean:
	rm $(MOD_NAME).wasm build -r