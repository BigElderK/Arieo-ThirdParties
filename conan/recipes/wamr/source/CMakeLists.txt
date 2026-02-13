# Custom CMakeLists.txt for building WAMR as a Conan package
# Uses WAMR's build-scripts/runtime_lib.cmake directly for cross-platform support

cmake_minimum_required(VERSION 3.14)

include(CheckPIESupported)

project(iwasm VERSION 2.4.4 LANGUAGES C CXX ASM)

option(BUILD_SHARED_LIBS "Build using shared libraries" OFF)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_VERBOSE_MAKEFILE OFF)

# Reset default linker flags
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")

# WAMR_BUILD_PLATFORM and WAMR_BUILD_TARGET should be passed via cache variables
# from the Conan recipe (CMakeToolchain)

# Set WAMR root directory relative to the cloned source
set(WAMR_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/wamr)

# Include WAMR's core build script
include(${WAMR_ROOT_DIR}/build-scripts/runtime_lib.cmake)

check_pie_supported()

###############################
# vmlib (static/shared library)
###############################

add_library(vmlib ${WAMR_RUNTIME_LIB_SOURCE})

target_include_directories(vmlib INTERFACE
    $<INSTALL_INTERFACE:include>
)

set(WAMR_PUBLIC_HEADERS
    ${WAMR_ROOT_DIR}/core/iwasm/include/wasm_c_api.h
    ${WAMR_ROOT_DIR}/core/iwasm/include/wasm_export.h
    ${WAMR_ROOT_DIR}/core/iwasm/include/lib_export.h
)

set_target_properties(vmlib PROPERTIES
    OUTPUT_NAME iwasm
    PUBLIC_HEADER "${WAMR_PUBLIC_HEADERS}"
    POSITION_INDEPENDENT_CODE ON
)

# Platform-specific linker flags
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Android")
    target_link_libraries(vmlib ${LLVM_AVAILABLE_LIBS} ${UV_A_LIBS} -lm -ldl -lpthread)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    target_link_libraries(vmlib ${LLVM_AVAILABLE_LIBS} ${UV_A_LIBS})
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_link_libraries(vmlib ${LLVM_AVAILABLE_LIBS} ${UV_A_LIBS})
endif()

# Install targets
install(TARGETS vmlib
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    PUBLIC_HEADER DESTINATION include
)
