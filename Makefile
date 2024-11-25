BUILD_DIR := build

ALL_DIR_CODE := lib lib/bdwgc lib/ src lib/fmt/src lib/libatomic_ops/src

DUMMY != mkdir -p $(foreach dir,$(ALL_DIR_CODE),$(BUILD_DIR)/$(dir))

# recursive wildcard
rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))
C_FILE := $(call rwildcard,src,*.c)
C_FILE += $(wildcard lib/*.c)
# BDWGC_FILE := $(wildcard lib/bdwgc/*.c)
# C_FILE += $(filter-out %darwin%, $(BDWGC_FILE))
C_FILE += $(wildcard lib/libatomic_ops/src/*.c)

CPP_FILE := $(call rwildcard,src,*.cpp)
CPP_FILE += $(wildcard lib/*.cpp)
CC_FILE := $(wildcard lib/fmt/src/*.cc)

PYTHON_FILE := $(call rwildcard,src,*.codon)

ALL_O := $(foreach file,$(C_FILE),$(file:%.c=$(BUILD_DIR)/%.o)) 
ALL_O += $(foreach file,$(CPP_FILE),$(file:%.cpp=$(BUILD_DIR)/%.o))
ALL_O += $(foreach file,$(CC_FILE),$(file:%.cc=$(BUILD_DIR)/%.o))
ALL_O += $(foreach file,$(PYTHON_FILE),$(file:%.codon=$(BUILD_DIR)/%.o))

MOD_NAME := test

INCLUDE_DIRS=lib include lib/fmt/include lib/fast_float/include lib/bdwgc/include lib/libatomic_ops/src

CC := emcc
CPP := em++
CC_FLAGS := $(foreach i,$(INCLUDE_DIRS),-I$(i)) -DGC_PTHREADS -DTHREADS -DUSE_PTHREAD_LOCKS
PYTHON_COMPILER := codon build

$(MOD_NAME): $(MOD_NAME).wasm

$(BUILD_DIR)/%.o: %.c
	$(CC) -c $(CC_FLAGS) -o $@ $<

$(BUILD_DIR)/%.o: %.cpp
	$(CPP) -c $(CC_FLAGS) -o $@ $<

$(BUILD_DIR)/%.o: %.cc
	$(CPP) -c -std=c++20 $(CC_FLAGS) -o $@ $<

$(BUILD_DIR)/%.o: %.codon
	$(PYTHON_COMPILER) --release --march=wasm32 --obj -o $@ $<

$(MOD_NAME).wasm: $(ALL_O)
	$(CC) $^ -o $(MOD_NAME).wasm -O3 -s LINKABLE=1 -s EXPORT_ALL=1 -s PURE_WASI=1

clean:
	rm $(MOD_NAME).wasm build -r