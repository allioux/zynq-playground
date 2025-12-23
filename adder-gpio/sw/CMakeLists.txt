cmake_minimum_required(VERSION 3.10)
project(AdderGpio LANGUAGES CXX)

# Require C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Find libgpiod
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBGPIOD REQUIRED libgpiod)

# Include directories
include_directories(${LIBGPIOD_INCLUDE_DIRS})

# Add executable
add_executable(gpio_example src/main.cpp)

# Link libraries
target_link_libraries(gpio_example ${LIBGPIOD_LIBRARIES} gpiodcxx)