cmake_minimum_required(VERSION 3.16)

set_target_properties(${PROJECT_NAME} PROPERTIES COMPILE_FLAGS "-O3 -s SIDE_MODULE=1 -s EXPORT_ALL=1 ")
set_target_properties(${PROJECT_NAME} PROPERTIES LINKER_FLAGS    "-O3 -s WASM=1 -s LINKABLE=1 -s EXPORT_ALL=1 -s PURE_WASI=1 -s SIDE_MODULE=1")

# add_subdirectory(runtime-wasi)

project(test)

file(GLOB ALL_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    "src/*.c"
    "src/*.h"
    "src/*.cpp"
    "src/*.hpp"
)

set(CMAKE_EXECUTABLE_SUFFIX ".wasm")

add_custom_target(fib.o ALL
    COMMAND codon build --release --march=wasm32 --obj -o ${CMAKE_CURRENT_BINARY_DIR}/fib.o ${CMAKE_CURRENT_SOURCE_DIR}/src/fib.codon
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/fib.codon
    COMMENT "Generating fib.o")

add_executable(${PROJECT_NAME} ${ALL_FILES})

add_dependencies(${PROJECT_NAME} fib.o)

add_library(codonrt runtime-wasi/exc.cpp runtime-wasi/lib.cpp runtime-wasi/fmt/src/format.cc)
target_include_directories(codonrt PRIVATE runtime-wasi/fmt/include)

target_link_libraries(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/fib.o codonrt)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++20")
