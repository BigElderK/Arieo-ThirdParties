# Patch WAMR source files for clang-cl compatibility on Windows
#
# Problem: clang-cl has issues with wide character literals like L'A' when
# a macro named 'L' is defined somewhere in the include chain (e.g., from winnt.h).
# This patch replaces L'x' wide char literals with explicit wchar_t constants.

# Pre-fetch Zydis for AOT support on Windows x86_64
# This ensures include directories are available before targets are defined
if(WIN32 AND (WAMR_BUILD_AOT OR WAMR_BUILD_TARGET STREQUAL "X86_64"))
    include(FetchContent)
    
    # Pre-populate Zycore
    FetchContent_Declare(
        zycore
        GIT_REPOSITORY https://github.com/zyantific/zycore-c.git
    )
    FetchContent_GetProperties(zycore)
    if(NOT zycore_POPULATED)
        message(STATUS "Pre-fetching zycore for AOT support...")
        FetchContent_Populate(zycore)
        include_directories(BEFORE SYSTEM "${zycore_SOURCE_DIR}/include")
        include_directories(BEFORE SYSTEM "${zycore_BINARY_DIR}")
    endif()
    
    # Pre-populate Zydis
    FetchContent_Declare(
        zydis
        GIT_REPOSITORY https://github.com/zyantific/zydis.git
        GIT_TAG e14a07895136182a5b53e181eec3b1c6e0b434de
    )
    FetchContent_GetProperties(zydis)
    if(NOT zydis_POPULATED)
        message(STATUS "Pre-fetching zydis for AOT support...")
        FetchContent_Populate(zydis)
        include_directories(BEFORE SYSTEM "${zydis_SOURCE_DIR}/include")
        include_directories(BEFORE SYSTEM "${zydis_BINARY_DIR}")
    endif()
endif()

if(WIN32 AND CMAKE_C_COMPILER_ID MATCHES "Clang")
    message(STATUS "Applying clang-cl compatibility patches for WAMR...")
    
    set(WIN_FILE_PATH "${WAMR_ROOT_DIR}/core/shared/platform/windows/win_file.c")
    
    if(EXISTS "${WIN_FILE_PATH}")
        file(READ "${WIN_FILE_PATH}" WIN_FILE_CONTENT)
        
        # Check if patch is already applied (check for both old and new markers)
        string(FIND "${WIN_FILE_CONTENT}" "/* PATCHED: clang-cl wchar fix */" PATCH_FOUND)
        string(FIND "${WIN_FILE_CONTENT}" "WAMR_WCHAR" OLD_PATCH_FOUND)
        
        # If old patch (WAMR_WCHAR) exists, remove the entire old block
        if(NOT OLD_PATCH_FOUND EQUAL -1)
            # Remove old patch block completely
            string(REPLACE "/* PATCHED: clang-cl L macro fix */\n#if defined(__clang__) && defined(_MSC_VER)\n#ifdef L\n#undef L\n#endif\n/* Restore L as wide char prefix - define as identity for preprocessor */\n#define WAMR_WCHAR(x) L##x\n#endif\n\n" "" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            set(PATCH_FOUND -1)  # Force re-patching
        endif()
        
        if(PATCH_FOUND EQUAL -1)
            # Add wchar_t constant definitions after the pragma comment line
            set(PATCH_HEADER [=[
/* PATCHED: clang-cl wchar fix - explicit wchar_t constants */
#if defined(__clang__) && defined(_MSC_VER)
#define WCHAR_BACKSLASH ((wchar_t)0x005C)
#define WCHAR_QUESTION  ((wchar_t)0x003F)
#define WCHAR_COLON     ((wchar_t)0x003A)
#define WCHAR_A         ((wchar_t)0x0041)
#define WCHAR_C         ((wchar_t)0x0043)
#define WCHAR_N         ((wchar_t)0x004E)
#define WCHAR_U         ((wchar_t)0x0055)
#define WCHAR_Z         ((wchar_t)0x005A)
#define WCHAR_a         ((wchar_t)0x0061)
#define WCHAR_c         ((wchar_t)0x0063)
#define WCHAR_n         ((wchar_t)0x006E)
#define WCHAR_u         ((wchar_t)0x0075)
#define WCHAR_z         ((wchar_t)0x007A)
#else
#define WCHAR_BACKSLASH L'\\'
#define WCHAR_QUESTION  L'?'
#define WCHAR_COLON     L':'
#define WCHAR_A         L'A'
#define WCHAR_C         L'C'
#define WCHAR_N         L'N'
#define WCHAR_U         L'U'
#define WCHAR_Z         L'Z'
#define WCHAR_a         L'a'
#define WCHAR_c         L'c'
#define WCHAR_n         L'n'
#define WCHAR_u         L'u'
#define WCHAR_z         L'z'
#endif
]=])
            
            string(REPLACE 
                "#pragma comment(lib, \"Pathcch.lib\")"
                "#pragma comment(lib, \"Pathcch.lib\")\n${PATCH_HEADER}"
                WIN_FILE_CONTENT "${WIN_FILE_CONTENT}"
            )
            
            # Replace wide character literals with the defined constants
            string(REPLACE "L'\\\\'" "WCHAR_BACKSLASH" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "L'?'" "WCHAR_QUESTION" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "L':'" "WCHAR_COLON" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "L'A'" "WCHAR_A" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "L'Z'" "WCHAR_Z" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "L'a'" "WCHAR_a" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "L'z'" "WCHAR_z" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "L'U'" "WCHAR_U" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "L'u'" "WCHAR_u" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "L'N'" "WCHAR_N" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "L'n'" "WCHAR_n" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "L'C'" "WCHAR_C" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "L'c'" "WCHAR_c" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            
            # Also replace any leftover WAMR_WCHAR() from old patch
            string(REPLACE "WAMR_WCHAR('\\\\')" "WCHAR_BACKSLASH" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "WAMR_WCHAR('?')" "WCHAR_QUESTION" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "WAMR_WCHAR(':')" "WCHAR_COLON" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "WAMR_WCHAR('A')" "WCHAR_A" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "WAMR_WCHAR('Z')" "WCHAR_Z" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "WAMR_WCHAR('a')" "WCHAR_a" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "WAMR_WCHAR('z')" "WCHAR_z" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "WAMR_WCHAR('U')" "WCHAR_U" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "WAMR_WCHAR('u')" "WCHAR_u" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "WAMR_WCHAR('N')" "WCHAR_N" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "WAMR_WCHAR('n')" "WCHAR_n" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "WAMR_WCHAR('C')" "WCHAR_C" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REPLACE "WAMR_WCHAR('c')" "WCHAR_c" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            
            # Fix comments that end with backslash (clang interprets as line continuation)
            # These cause syntax errors because the next line becomes part of the comment
            # Replace trailing backslash in comments with forward slash
            string(REGEX REPLACE "// Starts with [\\]\\?\\?[\\][ ]*\n" "// Starts with \\\\?\\\\/ (path prefix)\n" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REGEX REPLACE "// [\\]\\?\\?[\\]<drive>:[\\][ ]*\n" "// \\\\?\\\\<drive>:\\\\/ (drive letter path)\n" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            string(REGEX REPLACE "looks like [\\][\\]<server>[\\][\\]<share>[\\][ ]*\n" "looks like \\\\<server>\\\\<share>\\\\/ (UNC)\n" WIN_FILE_CONTENT "${WIN_FILE_CONTENT}")
            
            file(WRITE "${WIN_FILE_PATH}" "${WIN_FILE_CONTENT}")
            message(STATUS "  Patched: win_file.c (wchar constants for clang-cl)")
        else()
            message(STATUS "  win_file.c already patched, skipping")
        endif()
    else()
        message(WARNING "  win_file.c not found at ${WIN_FILE_PATH}")
    endif()
    
    # Patch handler.c: getcwd is not available on Windows, use _getcwd instead
    set(HANDLER_FILE_PATH "${WAMR_ROOT_DIR}/core/iwasm/libraries/debug-engine/handler.c")
    if(EXISTS "${HANDLER_FILE_PATH}")
        file(READ "${HANDLER_FILE_PATH}" HANDLER_FILE_CONTENT)
        
        string(FIND "${HANDLER_FILE_CONTENT}" "/* PATCHED: Windows getcwd fix */" HANDLER_PATCH_FOUND)
        if(HANDLER_PATCH_FOUND EQUAL -1)
            # Add include for direct.h and define getcwd as _getcwd for Windows
            string(REPLACE 
                "#include \"handler.h\""
                "#include \"handler.h\"\n/* PATCHED: Windows getcwd fix */\n#ifdef _WIN32\n#include <direct.h>\n#define getcwd _getcwd\n#endif"
                HANDLER_FILE_CONTENT "${HANDLER_FILE_CONTENT}"
            )
            file(WRITE "${HANDLER_FILE_PATH}" "${HANDLER_FILE_CONTENT}")
            message(STATUS "  Patched: handler.c (getcwd for Windows)")
        else()
            message(STATUS "  handler.c already patched, skipping")
        endif()
    else()
        message(STATUS "  handler.c not found, skipping patch")
    endif()
endif()
