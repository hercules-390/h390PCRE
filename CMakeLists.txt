# CMakeLists.txt - Build PCRE as needed by Hercules

#[[   This is a modification of the CMakeLists.txt included in the PCRE
      package available at http://www.pcre.org/.

      Modifications Copyright 2017 by Stephen Orso.

      These modifications are licensed under the same BSD license used
      for the unmodified PCRE package; find the license for the
      unmodified package and these modifications in pkg-src/LICENCE.
]]

#[[
This CMakeLists.txt for PCRE is based on the original CMakeLists.txt
provided with the upstream PCRE distribution; the original is included
in the pkg_src directory for reference.

The contents of pkg_src are PCRE 8.41, retrieved October 2017 from
http://www.pcre.org/.

There are NO modifications to PCRE.

Functional changes made to the PCRE CMakeLists.txt provided in the
base PCRE distribution

- Removed lookups to packages that are not required for Hercules' use
  PCRE (Bzip2, Editline, Readline, and Zlib), and removed tests for
  C++ headers that are not required.
- Removed tests for headers and functions that were only required for
  pcregrep or the C++ wrapper.
- Because Hercules requires the POSIX wrapper and that wrapper only
  supports the 8-bit character version of PCRE, all references to
  the 16- and 32-bit character versions have been removed.
- Removed JIT compiler support.  JIT support is not available using
  the POSIX wrapper, and Hercules only uses the POSIX wrapper.
- Changed option defaults to build only an 8-bit PCRE shared library.
  The POSIX wrapper only supports 8-bit pcre.

Testing-related changes to CMakeLists.txt

- If PCRE_BUILD_TESTS is ON, the pcretest program compiled.  It is
  compiled without readline() support, as Windows does not have a
  native readline() function.
- Executable pcretest is linked with a 16MB stack.  Test 2 requires
  at least 8mb of stack according to test script comments.  This large
  stack affects only the pcretest executable and does not impact the
  shared library.
- Only tests 1, 2, 3, 8, 13, and 14 are run when running pcretest.
  The other tests involve functionality not included in this build
  (16, 32-bit characters, JIT, Unicode, or UTF-8).
- NOTE: in the Windows command files that run the tests, comments
  state tha pcregrep is needed to run the tests.  This does not seem
  to be true, at least for tests of just 8-bit character sets, and
  pcregrep is not built.

Other changes to CMakeLists.txt

- Removed support for building static libraries or linking with the
  static Microsoft C runtime library.
- Changed all references to source files to reflect their movement to
  the pkg-src directory.
- Exported both targets of the installation tree in a single target
  import script in the pcre-targets sub-directory.
- Exported the target of the build tree to allow for a build that
  references the build directory.
- Copied public Headers to the build tree include subdirectory so that
  the exported build tree target does not make any references to the
  source tree.
- Removed configuration options MinSizeRel and RelWithDebInfo if
  they are present in CMAKE_CONFIGURATION_TYPES.
- Replaced references to the LOCATiON property in get_target_properties
  with generator expressions to remove a requirement for policy
  CMP0026.
- Miscelaneous removals: MinGW/CyWin support, UNIX-like target systems.

]]

# ----------------------------------------------------------------------
# Preamble: basic CMake setup, set configuration type(s), minimum CMake
# version required, PCRE options, and whether tests should be enabled.
# ----------------------------------------------------------------------

# Minimum version based on that required for other Hercules modules.

cmake_minimum_required( VERSION 3.4.0 )

project( PCRE VERSION 8.41.0 LANGUAGES C )

include( herc_setWindowsTarget.cmake )

# In the Hercules repo for this package, source is one level down.

set( src_dir "pkg_src/"  )


# The following three options may be changed as needed to suit the
# builder.  DEBUG is passed from the Hercules configure step when using
# a single-configuration generator.

option( DEBUG               "Build for debugging (no optimization etc)" OFF )
option( PCRE_SHOW_REPORT    "Show the final configuration report"       OFF )
option( PCRE_BUILD_TESTS    "Build the tests"                           OFF )
option( PCRE_REBUILD_CHARTABLES   "Rebuild char tables"                 OFF )

# Save room for compiling on Windows using Clang.  If using MSVC,
# generate .pdb debugging files.  Notet that .pdb files are generated
# for all configurations, not just Debug.

if( MSVC )
    #  pdb files will be generated and installed for MSVC
    option( INSTALL_MSVC_PDB "ON=Install .pdb files built by MSVC, if generated" ON )
endif( MSVC )



# While Windows builders often use Visual Studio, a multi-configuration
# generator, NMake is also supported and is a single-configuration
# generator.

if( "${CMAKE_CONFIGURATION_TYPES}" STREQUAL "" )
    # Generator in use creates build scripts for exactly one configuration.
    # Determine whether this is a release or debug build.
    if( DEBUG )
    set( CMAKE_BUILD_TYPE "Debug" )
    else( )
    set( CMAKE_BUILD_TYPE "Release" )
    endif( )
    message( STATUS "Single configuration generator; configuring for ${CMAKE_BUILD_TYPE}" )

else( )
    # For generators that support multiple configurations with build-time
    # configuration selection (Visual Studio or mac OS Xcode), CMake
    # defaults to four configurations: Release, Debug, MinSizeRel, and
    # RelWithDebInfo.  For now, only the first two are needed.  Remove the
    # other two.
    list( REMOVE_ITEM CMAKE_CONFIGURATION_TYPES
                MinSizeRel
                RelWithDebInfo
                )
    message ( STATUS "Available configuration Types: ${CMAKE_CONFIGURATION_TYPES}"  )
endif( )


# User-configurable options, so called.  The defaults established below
# are correct for Hercules and should not be changed.

set( BUILD_SHARED_LIBS ON CACHE BOOL
            "Build shared libraries instead of static ones." )
set( PCRE_BUILD_PCRE8 ON CACHE BOOL
            "Build 8 bit PCRE library" )
set( PCRE_EBCDIC OFF CACHE BOOL
            "Use EBCDIC coding instead of ASCII. (This is rarely used outside of mainframe systems.)" )
set( PCRE_EBCDIC_NL25 OFF CACHE BOOL
            "Use 0x25 as EBCDIC NL character instead of 0x15; implies EBCDIC." )
set( PCRE_LINK_SIZE "2" CACHE STRING
            "Internal link size (2, 3 or 4 allowed). See LINK_SIZE in config.h.in for details." )
set( PCRE_PARENS_NEST_LIMIT "250" CACHE STRING
            "Default nested parentheses limit. See PARENS_NEST_LIMIT in config.h.in for details." )
set( PCRE_MATCH_LIMIT "10000000" CACHE STRING
    "Default limit on internal looping. See MATCH_LIMIT in config.h.in for details." )
set( PCRE_MATCH_LIMIT_RECURSION "MATCH_LIMIT" CACHE STRING
    "Default limit on internal recursion. See MATCH_LIMIT_RECURSION in config.h.in for details." )
set( PCREGREP_BUFSIZE "20480" CACHE STRING
    "Buffer size parameter for pcregrep. See PCREGREP_BUFSIZE in config.h.in for details." )
set( PCRE_NEWLINE "LF" CACHE STRING
    "What to recognize as a newline (one of CR, LF, CRLF, ANY, ANYCRLF)." )
set( PCRE_NO_RECURSE OFF CACHE BOOL
    "If ON, then don't use stack recursion when matching. See NO_RECURSE in config.h.in for details." )
set( PCRE_POSIX_MALLOC_THRESHOLD "10" CACHE STRING
    "Threshold for malloc() usage. See POSIX_MALLOC_THRESHOLD in config.h.in for details." )
set( PCRE_SUPPORT_UTF OFF CACHE BOOL
    "Enable support for Unicode Transformation Format (UTF-8/UTF-16/UTF-32) encoding." )
set( PCRE_SUPPORT_UNICODE_PROPERTIES OFF CACHE BOOL
    "Enable support for Unicode properties (if set, UTF support will be enabled as well)." )
set( PCRE_SUPPORT_BSR_ANYCRLF OFF CACHE BOOL
    "ON=Backslash-R matches only LF CR and CRLF, OFF=Backslash-R matches all Unicode Linebreaks" )

set( newline_symbols LF CR CRLF ANY ANYCRLF )
list( FIND newline_symbols ${PCRE_NEWLINE} NEWLINE )
if( ${NEWLINE} LESS 0 )
    message( FATAL_ERROR "The PCRE_NEWLINE variable must be set to one of the following values: \"LF\", \"CR\", \"CRLF\", \"ANY\", \"ANYCRLF\"." )
endif( )



# ----------------------------------------------------------------------
# Probe the target system.  Some of the original tests will always
# result in "not found" on a Windows system; they were removed.
# ----------------------------------------------------------------------

include( CheckIncludeFile )
include( CheckIncludeFileCXX )
include( CheckFunctionExists )
include( CheckTypeSize )

# dirent.h is only used by pcregrep, which we do not build.
# unistd.h is only on UNIX-like systems, so no test.
# sys/stat.h is only used by pcregrep, which we do not build.
# We do not need inttypes.h if stdint.h is available.

# check_include_file( dirent.h     HAVE_DIRENT_H )
check_include_file( stdint.h     HAVE_STDINT_H )
if( NOT "${HAVE_STDINT_H}" )
    check_include_file( inttypes.h   HAVE_INTTYPES_H )
endif( )
# check_include_file( sys/stat.h   HAVE_SYS_STAT_H )
check_include_file( sys/types.h  HAVE_SYS_TYPES_H )
# check_include_file( unistd.h     HAVE_UNISTD_H )
check_include_file( windows.h    HAVE_WINDOWS_H )

# bcopy does not exist in Windows.  It has also been removed from
# POSIX standards.  So we delete the test.
# strtoll, strtoq, _strtoi64 are used only by the cpp wrapper and are
# not needed by Hercules.  So we delet both tests.

# check_function_exists( bcopy     HAVE_BCOPY )
check_function_exists( memmove   HAVE_MEMMOVE )
check_function_exists( strerror  HAVE_STRERROR )
# check_function_exists( strtoll   HAVE_STRTOLL )
# check_function_exists( strtoq    HAVE_STRTOQ )
# check_function_exists( _strtoi64 HAVE__STRTOI64 )

# The following two long long tests are used only by the cpp wrapper
# and are not needed by Hercules.  So we delet both tests.

# check_type_size( "long long"             LONG_LONG )
# check_type_size( "unsigned long long"    UNSIGNED_LONG_LONG )


# ----------------------------------------------------------------------
# Set PCRE configuration options.
# ----------------------------------------------------------------------

unset( PCRE_STATIC )            # Just in case.  Hercules only uses shared
set( SUPPORT_PCRE8 1 )          # 8-bit PCRE always and only supported

if( PCRE_SUPPORT_BSR_ANYCRLF )
    set( BSR_ANYCRLF 1 )
endif( PCRE_SUPPORT_BSR_ANYCRLF )

if( PCRE_SUPPORT_UTF OR PCRE_SUPPORT_UNICODE_PROPERTIES )
    set( SUPPORT_UTF 1 )
    set( PCRE_SUPPORT_UTF ON )
endif( PCRE_SUPPORT_UTF OR PCRE_SUPPORT_UNICODE_PROPERTIES )

if( PCRE_SUPPORT_UNICODE_PROPERTIES )
    set( SUPPORT_UCP 1 )
endif( PCRE_SUPPORT_UNICODE_PROPERTIES )

# translate line end option into value used by PCRE coding.

if( PCRE_EBCDIC )
    set( EBCDIC 1 )
    set( newline_codes 21 13 3349 -1 -2 )

elseif( PCRE_EBCDIC_NL25 )
    set( EBCDIC 1 )
    set( EBCDIC_NL25 1 )
    set( newline_codes 37 13 3365 -1 -2 )

else( )
    set( newline_codes 10 13 3338 -1 -2 )

endif( )
list( GET newline_codes ${NEWLINE} NEWLINE )


if( PCRE_NO_RECURSE )
    set( NO_RECURSE 1 )
endif( PCRE_NO_RECURSE )


# ----------------------------------------------------------------------
# Create configuration files and rebuild character tables if requested
# ----------------------------------------------------------------------

# Parse version numbers and date out of configure.ac

file( STRINGS ${PROJECT_SOURCE_DIR}/${src_dir}configure.ac
            configure_lines
            REGEX "^m4_define\\(pcre_"
            LIMIT_COUNT 50 # Read only the first 50 lines of the file
 )

set( SEARCHED_VARIABLES "pcre_major" "pcre_minor" "pcre_prerelease" "pcre_date" )
foreach( configure_line ${configure_lines} )
    foreach( _substitution_variable ${SEARCHED_VARIABLES} )
        string( TOUPPER ${_substitution_variable} _substitution_variable_upper )
        if ( NOT ${_substitution_variable_upper} )
            string( REGEX MATCH "m4_define\\(${_substitution_variable}, \\[(.*)\\]" MACTHED_STRING ${configure_line} )
            if ( CMAKE_MATCH_1 )
                set( ${_substitution_variable_upper} ${CMAKE_MATCH_1} )
            endif( )
        endif( )
    endforeach( )
endforeach( )


# PCRE configuration file

configure_file( ${src_dir}config-cmake.h.in
               ${PROJECT_BINARY_DIR}/config.h
               @ONLY )

# (Modification for Hercules.) Changed destination of configure file so
# that all public headers required for PCRE/PCREPOSIX end up in the
# build tree include subdirectory.  This means the export of the build
# tree has no references to the source tree.

configure_file(  ${src_dir}pcre.h.in
               ${PROJECT_BINARY_DIR}/include/pcre.h
               @ONLY )


# Character table generation

if( PCRE_REBUILD_CHARTABLES )
    add_executable( dftables dftables.c )

    add_custom_command( COMMAND $<TARGET_FILE:dftables>
                ARGS        ${PROJECT_BINARY_DIR}/pcre_chartables.c
                OUTPUT      ${PROJECT_BINARY_DIR}/pcre_chartables.c
                DEPENDS dftables
                COMMENT "Generating character tables (pcre_chartables.c) for current locale"
                )

else( )
    configure_file( ${PROJECT_SOURCE_DIR}/${src_dir}pcre_chartables.c.dist
                    ${PROJECT_BINARY_DIR}/pcre_chartables.c
                    COPYONLY )
endif( )


# ----------------------------------------------------------------------
# Source code definitions.
# ----------------------------------------------------------------------

set( PCRE_HEADERS ${PROJECT_BINARY_DIR}/include/pcre.h )

if( PCRE_BUILD_PCRE8 )
    set( PCRE_SOURCES
            ${src_dir}pcre_byte_order.c
            pcre_chartables.c
            ${src_dir}pcre_compile.c
            ${src_dir}pcre_config.c
            ${src_dir}pcre_dfa_exec.c
            ${src_dir}pcre_exec.c
            ${src_dir}pcre_fullinfo.c
            ${src_dir}pcre_get.c
            ${src_dir}pcre_globals.c
            ${src_dir}pcre_jit_compile.c
            ${src_dir}pcre_maketables.c
            ${src_dir}pcre_newline.c
            ${src_dir}pcre_ord2utf8.c
            ${src_dir}pcre_refcount.c
            ${src_dir}pcre_string_utils.c
            ${src_dir}pcre_study.c
            ${src_dir}pcre_tables.c
            ${src_dir}pcre_ucd.c
            ${src_dir}pcre_valid_utf8.c
            ${src_dir}pcre_version.c
            ${src_dir}pcre_xclass.c
            )

    set( PCREPOSIX_HEADERS  ${src_dir}pcreposix.h )

    set( PCREPOSIX_SOURCES  ${src_dir}pcreposix.c )

endif( PCRE_BUILD_PCRE8 )

# If resource definition files exist, include them in sources.  CMake
# will ensure they are processed by the Resource Compiler.

if( MSVC )
    if( EXISTS ${PROJECT_SOURCE_DIR}/${src_dir}pcre.rc )
        set( PCRE_SOURCES${PCRE_SOURCES} ${src_dir}pcre.rc )
    endif( )

    if( EXISTS ${PROJECT_SOURCE_DIR}/${src_dir}pcreposix.rc )
        set( PCREPOSIX_SOURCES ${PCREPOSIX_SOURCES} ${src_dir}pcreposix.rc )
    endif( )
endif( )


# ----------------------------------------------------------------------
# Set compiler and linker flags and definitions.
# ----------------------------------------------------------------------

add_definitions( -DHAVE_CONFIG_H )

if( MSVC )
    add_definitions(
            -D_CRT_SECURE_NO_DEPRECATE
            -D_CRT_SECURE_NO_WARNINGS
            -D_CRT_NONSTDC_NO_DEPRECATE
            )
    set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /MP" )
    set(  CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /Zi /GL" )
    set( CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /DEBUG /LTCG" )
    set( CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /DEBUG /LTCG" )
endif( MSVC )

# When building for Windows, ensure that the correct Windows API version
# is used.  The default is the API version of the host system.  While we
# are here, ensure the debug library gets a different name and a exports
# file is created for later creation of the import library.

if( WIN32 )
    add_definitions( -DWIN32 )
    herc_setWindowsTarget( "${WINTARGET}" Windows_version )
    if( WINVER )
        add_definitions( -DWINVER=${WINVER}
                         -D_WIN32_WINNT=${_WIN32_WINNT}
                         -DNTDDI_VERSION=${NTDDI_VERSION}  )
    endif( )
    set( CMAKE_DEBUG_POSTFIX "d" )      # provide unique names for debug libs

    # While MS is quite clear that the ANSI predefined macros are _not_
    # defined for the resource compiler, apparently at least one important
    # MS-specific one is not either:  _WIN64.  So we shall use SIZEOF_SIZE_P
    # to set it.  See: https://msdn.microsoft.com/en-us/library/windows/desktop/aa381032(v=vs.85).aspx
    # for Microsoft's limited discussion of this.

    if( CMAKE_SIZEOF_VOID_P GREATER 4 )
        set( CMAKE_RC_FLAGS "${CMAKE_RC_FLAGS} -D_WIN64" )
    endif( )

endif( )   # if( WIN32 )




# ----------------------------------------------------------------------
# Create library targets.  If building the test program, create that
# target as well.
# ----------------------------------------------------------------------

# Header pcre.h was configured into the include/ directory.  Copy
# the pcreposix.h header there too.

file( COPY ${PCREPOSIX_HEADERS} DESTINATION ${PROJECT_BINARY_DIR}/include )

include_directories( BEFORE
            ${PROJECT_BINARY_DIR}/include
            ${PROJECT_BINARY_DIR}
            ${PROJECT_SOURCE_DIR}/${src_dir}
            )

# Library targets

add_library( pcre ${PCRE_HEADERS} ${PCRE_SOURCES} )

add_library( pcreposix ${PCREPOSIX_HEADERS} ${PCREPOSIX_SOURCES} )
target_link_libraries( pcreposix pcre )

# Test program target.

if( PCRE_BUILD_TESTS )

    add_executable( pcretest ${src_dir}pcretest.c ${src_dir}pcre_printint.c )
    target_link_libraries( pcretest pcreposix pcre )

    if( MSVC )
        # Suppress C4267 'var' : conversion from 'size_t' to 'type',
        # possible loss of data, which appears on 64-bit targets
        target_compile_options( pcretest PRIVATE "/wd4267" )
        # pcretest needs at least an 8mb stack to run test 2.
        # provide a 16mb stack
        set_target_properties( pcretest PROPERTIES LINK_FLAGS "/STACK:16777216" )
    endif( )

endif( )


# ----------------------------------------------------------------------
# Define the single test case.  The single test case runs all tests
# defined for an 8-bit non-UTF-8 non-Unicode PCRE.
# ----------------------------------------------------------------------

# The original code, shown in the comments below, creates a batch file
# that connects the RunTest.Bat file to the executable and the source
# directory (which is used to locate the test materials).

### GET_TARGET_PROPERTY(PCRETEST_EXE pcretest DEBUG_LOCATION)
# [...]
###   IF(WIN32)
###     # Provide environment for executing the bat file version of RunTest
###     FILE(TO_NATIVE_PATH ${PROJECT_SOURCE_DIR} winsrc)
###     FILE(TO_NATIVE_PATH ${PROJECT_BINARY_DIR} winbin)
###     FILE(TO_NATIVE_PATH ${PCRETEST_EXE} winexe)
# [...]
###     FILE(WRITE ${PROJECT_BINARY_DIR}/pcre_test.bat
###     "\@REM This is a generated file.
### \@echo off
### setlocal
### SET srcdir=\"${winsrc}\"
### SET pcretest=\"${winexe}\"
### if not [%CMAKE_CONFIG_TYPE%]==[] SET pcretest=\"${winbin}\\%CMAKE_CONFIG_TYPE%\\pcretest.exe\"
### call %srcdir%\\RunTest.Bat
### if errorlevel 1 exit /b 1
### echo RunTest.bat tests successfully completed
### ")

# Here's the problem: this runs at configure time, and on multi-
# configuration generators, we will not know where the executable will
# be until build time.  I suspect this is the reason Kitware deprecated
# get_target_properties( LOCATION ).  While not known for certain, it
# makes sense based on the documentation for policy CMP0026; see
# https://cmake.org/cmake/help/v3.4/policy/CMP0026.html for details.

# I suspect the original CMake script was developed for a CMake version
# that did not support generator expressions, so the technique below was
# not available to the original developers.

# So...we shall create a test that runs a CMake script that translates
# the directory and path names into Windows native (backslash) form and
# then calls a .bat file that expects the source directory and
# executable path as args.  This lets us use generator expressions for
# the executable path.  (We cannot transform the path names here because
# we need to use a generator expression and those are not valid at
# configure time.

if( PCRE_BUILD_TESTS )
    enable_testing( )

    if( WIN32 )
        add_test( NAME pcre_test_bat
                COMMAND ${CMAKE_COMMAND}
                    -Dsrcdir=${PROJECT_SOURCE_DIR}/${src_dir}
                    -Dexepath=$<TARGET_FILE:pcretest>
                    -Dbatpath=${PROJECT_SOURCE_DIR}/pcre_test.bat
                    -P ${PROJECT_SOURCE_DIR}/pcre_test.cmake
                )
        # Specify the text of the stdout message from pcre_test.bat that
        # everything ran OK.  Test passes if message appears.
        set_tests_properties( pcre_test_bat
            PROPERTIES
                PASS_REGULAR_EXPRESSION "RunTest\\.bat tests successfully completed" )
                # cf. FAIL_REGULAR_EXPRESSION in CMake documentation at
                # https://cmake.org/cmake/help/v3.4/prop_test/FAIL_REGULAR_EXPRESSION.html
    endif( WIN32 )

endif( PCRE_BUILD_TESTS )


# ----------------------------------------------------------------------
# Install library targets.  The test case executable pcretest is not
# installed.
# ----------------------------------------------------------------------

# (Modification for Hercules.) Define the location of the public headers
# that need to be part of the exported targets (build tree and install )
# for this target.  The generator expression $<BUILD_INTERFACE:...> has
# the expected value at build time and is the null string at install
# time, and vice versa for $<INSTALL_INTERFACE:..>.  Without
# target_include_directories(), the public header directory will never
# appear in the exported targets.

target_include_directories( pcre PUBLIC
                        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
                        $<INSTALL_INTERFACE:include> )

target_include_directories( pcreposix PUBLIC
                        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
                        $<INSTALL_INTERFACE:include> )

# (Modification for Hercules.)  Install the targets.  Include the
# targets in the export of the install targets.

install( TARGETS pcre pcreposix
        EXPORT  pcre                  # Added for Hercules
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib )

install( FILES ${PCRE_HEADERS} ${PCREPOSIX_HEADERS} DESTINATION include )

# Ensure the LICENCE and COPYING  files end up in the binary directory.

install( FILES ${pkg_src}COPYING;${pkg_src}LICENCE DESTINATION . )

# (Modification for Hercules.)  Create the export of the target.  This
# export can be imported by the CMake build for Hercules.  The imported
# targets will be used when building Hercules.

install( EXPORT pcre DESTINATION pcre-targets )

# (Modification for Hercules.)  Create an export target of the build
# tree.  This allows the build tree to be used as an import target
# without requiring an install.

export( EXPORT pcre FILE pcre-targets/pcre.cmake  )

if( MSVC AND INSTALL_MSVC_PDB )
    install( FILES ${PROJECT_BINARY_DIR}/pcre.pdb
                  ${PROJECT_BINARY_DIR}/pcreposix.pdb
            DESTINATION bin
            CONFIGURATIONS RelWithDebInfo )
    install( FILES ${PROJECT_BINARY_DIR}/pcred.pdb
                  ${PROJECT_BINARY_DIR}/pcreposixd.pdb
            DESTINATION bin
            CONFIGURATIONS Debug )
endif( )


if( PCRE_SHOW_REPORT )
    if( CMAKE_C_FLAGS )
        set( cfsp " " )
    endif( )
    if( CMAKE_SHARED_LINKER_FLAGS )
        set( lfsp " " )
    endif( )
    message( STATUS "" )
    message( STATUS "" )
    message( STATUS "PCRE configuration summary:" )
    message( STATUS "" )
    message( STATUS "  Install prefix .................. : ${CMAKE_INSTALL_PREFIX}" )
    message( STATUS "  C compiler ...................... : ${CMAKE_C_COMPILER}" )
    message( STATUS "  C compiler flags (Release) ...... : ${CMAKE_C_FLAGS}${cfsp}${CMAKE_C_FLAGS_RELEASE}" )
    message( STATUS "  C compiler flags (Debug) ........ : ${CMAKE_C_FLAGS}${cfsp}${CMAKE_C_FLAGS_DEBUG}" )
    message( STATUS "  C linker flags (Release) ........ : ${CMAKE_SHARED_LINKER_FLAGS}${lfsp}${CMAKE_SHARED_LINKER_FLAGS_RELEASE}" )
    message( STATUS "  C linker flags (Debug) .......... : ${CMAKE_SHARED_LINKER_FLAGS}${lfsp}${CMAKE_SHARED_LINKER_FLAGS_DEBUG}" )
    message( STATUS "" )
    message( STATUS "  Build 8 bit PCRE library ........ : ${PCRE_BUILD_PCRE8}" )
    message( STATUS "  Enable UTF support .............. : ${PCRE_SUPPORT_UTF}" )
    message( STATUS "  Unicode properties .............. : ${PCRE_SUPPORT_UNICODE_PROPERTIES}" )
    message( STATUS "  Newline char/sequence ........... : ${PCRE_NEWLINE} = ${NEWLINE}" )
    message( STATUS "  \\R matches only ANYCRLF ......... : ${PCRE_SUPPORT_BSR_ANYCRLF}" )
    message( STATUS "  EBCDIC coding ................... : ${PCRE_EBCDIC}" )
    message( STATUS "  EBCDIC coding with NL=0x25 ...... : ${PCRE_EBCDIC_NL25}" )
    message( STATUS "  Rebuild char tables ............. : ${PCRE_REBUILD_CHARTABLES}" )
    message( STATUS "  No stack recursion .............. : ${PCRE_NO_RECURSE}" )
    message( STATUS "  POSIX mem threshold ............. : ${PCRE_POSIX_MALLOC_THRESHOLD}" )
    message( STATUS "  Internal link size .............. : ${PCRE_LINK_SIZE}" )
    message( STATUS "  Parentheses nest limit .......... : ${PCRE_PARENS_NEST_LIMIT}" )
    message( STATUS "  Match limit ..................... : ${PCRE_MATCH_LIMIT}" )
    message( STATUS "  Match limit recursion ........... : ${PCRE_MATCH_LIMIT_RECURSION}" )
    message( STATUS "  Build shared libs ............... : ${BUILD_SHARED_LIBS}" )
    message( STATUS "  Build tests (implies pcretest) .. : ${PCRE_BUILD_TESTS}" )
    if( MSVC )
        message( STATUS "  Install MSVC .pdb files ..........: ${INSTALL_MSVC_PDB}" )
    endif( MSVC )
    message( STATUS "" )
endif( PCRE_SHOW_REPORT )

# end CMakeLists.txt
