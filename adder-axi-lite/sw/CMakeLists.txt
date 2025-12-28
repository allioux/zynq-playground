cmake_minimum_required(VERSION 3.10)
project(AdderAxiLite LANGUAGES CXX)

# Require C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Add executable
add_executable(adder_axi_lite src/main.cpp)
