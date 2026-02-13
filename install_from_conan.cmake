cmake_minimum_required(VERSION 3.20)

function(install_conan_file)
    set(oneValueArgs
        CONAN_FILE
        CONAN_HOST_PROFILE_FILE
        INSTALL_FOLDER
    )
    
    cmake_parse_arguments(
        ARGUMENT
        ""
        "${oneValueArgs}"
        ""
        ${ARGN}
    )

    # print arguments and exit for now
    message(STATUS "========================================")
    message(STATUS "Installing Conan Dependencies")
    message(STATUS "========================================")
    message(STATUS "CONAN_FILE: ${ARGUMENT_CONAN_FILE}")
    message(STATUS "CONAN_HOST_PROFILE_FILE: ${ARGUMENT_CONAN_HOST_PROFILE_FILE}")
    message(STATUS "INSTALL_FOLDER: ${ARGUMENT_INSTALL_FOLDER}")
    # Clean install folder before any operations
    if(EXISTS "${ARGUMENT_INSTALL_FOLDER}")
        message(STATUS "Cleaning install folder: ${ARGUMENT_INSTALL_FOLDER}")
        file(REMOVE_RECURSE "${ARGUMENT_INSTALL_FOLDER}")
    endif()
    file(MAKE_DIRECTORY "${ARGUMENT_INSTALL_FOLDER}")
    
    # change to --build=* to force rebuild of all packages
    execute_process(
        COMMAND conan
            install
            ${ARGUMENT_CONAN_FILE}
            --update
            --output-folder ${ARGUMENT_INSTALL_FOLDER}
            -pr:h=${ARGUMENT_CONAN_HOST_PROFILE_FILE}
            --build=missing 
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        RESULT_VARIABLE CONAN_RESULT
        ECHO_OUTPUT_VARIABLE
        ECHO_ERROR_VARIABLE
        COMMAND_ECHO STDOUT
    )
    
    if(NOT CONAN_RESULT EQUAL 0)
        message(FATAL_ERROR "Conan install failed for ${ARGUMENT_CONAN_FILE}")
        exit(1)
    else()
        message(STATUS "Successfully installed dependencies from ${ARGUMENT_CONAN_FILE}")
    endif()
endfunction()

if($ENV{ARIEO_PACKAGE_BUILD_HOST_PRESET} STREQUAL "android.armv8")
    install_conan_file(
        CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.android.txt
        CONAN_HOST_PROFILE_FILE $ENV{ARIEO_BUILDENV_PACKAGE_INSTALL_FOLDER}/conan/host/android.armv8/conan_host_profile.android.armv8.txt
        INSTALL_FOLDER $ENV{CUR_ARIEO_PACKAGE_INSTALL_FOLDER}/conan/$ENV{ARIEO_PACKAGE_BUILD_HOST_PRESET}
    )
endif()

if($ENV{ARIEO_PACKAGE_BUILD_HOST_PRESET} STREQUAL "raspberry.armv8")
    install_conan_file(
        CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.raspberry.txt
        CONAN_HOST_PROFILE_FILE $ENV{ARIEO_BUILDENV_PACKAGE_INSTALL_FOLDER}/conan/host/raspberry.armv8/conan_host_profile.raspberry.armv8.txt
        INSTALL_FOLDER $ENV{CUR_ARIEO_PACKAGE_INSTALL_FOLDER}/conan/$ENV{ARIEO_PACKAGE_BUILD_HOST_PRESET}
    )
endif()

if($ENV{ARIEO_PACKAGE_BUILD_HOST_PRESET} STREQUAL "ubuntu.x86_64")
    install_conan_file(
        CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.ubuntu.txt
        CONAN_HOST_PROFILE_FILE $ENV{ARIEO_BUILDENV_PACKAGE_INSTALL_FOLDER}/conan/host/ubuntu.x86_64/conan_host_profile.ubuntu.x86_64.txt
        INSTALL_FOLDER $ENV{CUR_ARIEO_PACKAGE_INSTALL_FOLDER}/conan/$ENV{ARIEO_PACKAGE_BUILD_HOST_PRESET}
    )
endif()

if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    if($ENV{ARIEO_PACKAGE_BUILD_HOST_PRESET} STREQUAL "windows.x86_64")
        install_conan_file(
            CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.windows.txt
            CONAN_HOST_PROFILE_FILE $ENV{ARIEO_BUILDENV_PACKAGE_INSTALL_FOLDER}/conan/host/windows.x86_64/conan_host_profile.windows.x86_64.txt
            INSTALL_FOLDER $ENV{CUR_ARIEO_PACKAGE_INSTALL_FOLDER}/conan/$ENV{ARIEO_PACKAGE_BUILD_HOST_PRESET}
        )
    endif()
endif()

if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    if($ENV{ARIEO_PACKAGE_BUILD_HOST_PRESET} STREQUAL "macos.arm64")
        install_conan_file(
            CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.macos.txt
            CONAN_HOST_PROFILE_FILE $ENV{ARIEO_BUILDENV_PACKAGE_INSTALL_FOLDER}/conan/host/macos.arm64/conan_host_profile.macos.arm64.txt
            INSTALL_FOLDER $ENV{CUR_ARIEO_PACKAGE_INSTALL_FOLDER}/conan/$ENV{ARIEO_PACKAGE_BUILD_HOST_PRESET}
        )
    endif()
endif()