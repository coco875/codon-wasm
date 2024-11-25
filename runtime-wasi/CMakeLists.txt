cmake_minimum_required(VERSION 3.16)

add_library(codonrt exc.cpp lib.cpp ${CMAKE_CURRENT_SOURCE_DIR}/fmt/src/format.cc)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-exceptions -std=c++17")

# target_link_libraries(codonrt PRIVATE gc)
target_include_directories(codonrt PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/fmt/include)