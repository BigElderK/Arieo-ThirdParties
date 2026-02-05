cmake_minimum_required(VERSION 3.20)

message(STATUS "Installing third-party dependencies...")

# Install dependencies from Conan
message(STATUS "Installing Conan dependencies...")
execute_process(
    COMMAND ${CMAKE_COMMAND} -P install_from_conan.cmake
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    RESULT_VARIABLE CONAN_RESULT
)

if(NOT CONAN_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install Conan dependencies")
endif()

message(STATUS "Conan dependencies installed successfully")

# Install dependencies from Gradle
execute_process(
    COMMAND ${CMAKE_COMMAND} -P install_from_gradle.cmake
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    RESULT_VARIABLE GRADLE_RESULT
)
if(NOT GRADLE_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install Gradle dependencies")
endif()
message(STATUS "Gradle dependencies installed successfully")


message(STATUS "All third-party dependencies installed successfully")
