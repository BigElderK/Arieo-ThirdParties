cmake_minimum_required(VERSION 3.20)

# Export all conan recipes from conan/recipes/*/conanfile.py
# This script exports local recipes to the conan cache with user=arieo and channel=dev

message(STATUS "========================================")
message(STATUS "Arieo Conan Recipe Exporter")
message(STATUS "========================================")

# Glob all conanfile.py from subfolders in conan/recipes
file(GLOB_RECURSE CONAN_RECIPE_FILES
    ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/*/conanfile.py
)

message(STATUS "Found recipe files: ${CONAN_RECIPE_FILES}")
list(LENGTH CONAN_RECIPE_FILES RECIPE_COUNT)
message(STATUS "Number of recipes to export: ${RECIPE_COUNT}")

if(RECIPE_COUNT EQUAL 0)
    message(WARNING "No conan recipes found in ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/")
    return()
endif()

foreach(RECIPE_FILE IN LISTS CONAN_RECIPE_FILES)
    get_filename_component(RECIPE_DIR ${RECIPE_FILE} DIRECTORY)
    get_filename_component(RECIPE_NAME ${RECIPE_DIR} NAME)
    message(STATUS "Exporting recipe: ${RECIPE_NAME} from ${RECIPE_DIR}")
    
    execute_process(
        COMMAND conan
            export ${RECIPE_DIR}
            --user=arieo
            --channel=dev
        RESULT_VARIABLE CONAN_RESULT
        ECHO_OUTPUT_VARIABLE
        ECHO_ERROR_VARIABLE
        COMMAND_ECHO STDOUT
    )
    
    if(NOT CONAN_RESULT EQUAL 0)
        message(FATAL_ERROR "Conan export failed for ${RECIPE_NAME}")
    else()
        message(STATUS "Successfully exported: ${RECIPE_NAME}")
    endif()
endforeach()

message(STATUS "All recipes exported successfully")
message(STATUS "========================================")
