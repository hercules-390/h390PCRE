## PCRE for use with Hercules

This repository contains an unmodified copy of PCRE 8.41, retrieved
October 2017 from http://www.pcre.org/ and stored in the `pkg\_src`
subdirectory.  This should allow a complete replacement of the `pkg\_src`
directory contents when an uplevel upstream PCRE distribution becomes
available.

A substantially modified CMake build script has been added.  The CMake
script, while based on the original CMakeLists.txt script in the
upstream PCRE distribution, is specific to Hercules' requirements and
only builds the pcre and pcreposix shared libraries and only does so for
Windows target systems.  The build script exports targets for the build
directory, and for the installation directory if the pcre and pcreposix
shared libraries are installed.  The CMake build for Hercules can import
either target.  If PCRE is built by the CMake build for Hercules, the
build directory target is used.

The CMake build for Hercules will clone and build this repository if
PCRE is not installed on the target system.   This is the likely case,
as PCRE or its equivalent functionality is not part of Microsoft
Windows.

Build scripts and other programming in the top level is copyright by
Stephen Orso and is licensed under the same BSD license as is used for
the original PCRE distribution.   Documentation and other writing is
licensed using the Creative Commons By-SA 4.0 license.

Each file contains specific copyright and license information.

The PCRE package retains its original copyright and license, which can 
be found at `pkg_src/LICENCE`.

---
&nbsp;
### CMake -D Configuration Option Variables

Except for `BUILD_TESTING`, the configuration options used by the CMake
build for Hercules ensure that the PCRE library is built in a manner
consistent with the options and target for which Hercules is being
built.

- `PCRE_BUILD_TESTS  ON | OFF`, default is `OFF`
    When `ON`, include the `pcretest` executable in the build tree and
    generate test cases to verify the operation of PCRE
- `DEBUG ON | OFF`, default is `OFF`
    Applicable to single-configuration generators like Nmake.  When ON,
    generate a Debug configuration build script.
    When OFF, generate a Release script.  The configuration used for
    Microsoft Visual Studio, a multi-configuration generator, is
    determined at build time.)
- `WINTARGET`  blank | `HOST` | `DIST` | windows-version
    Applicable when building on Windows.  Option windows-version may be
    any of `WinXP364`, `WinVista`, `Win7`, `Win8`, `Win10` and is case
    insensitive.  When blank or `HOST`, build for the version of Windows
    on the host.  When `DIST`, build for the earliest version of Windows
    supported by Hercules, Windows XP SP3 64-bit.  Otherwise build for
    the Windows version specified.
    
---
&nbsp;
### CMakeLists.txt Functional Differences

Functional changes made to the PCRE CMakeLists.txt provided in the
base PCRE distribution:

- Removed lookups to packages that are not required for Hercules' use
  PCRE (BZip2, Editline, Readline, and Zlib), and removed tests for
  C++ headers that are not required.
- Removed tests for headers and functions that were only required for
  pcregrep or the C++ wrapper.
- Removed all references to the 16- and 32-bit versions of PCRE.  
  Hercules requires the POSIX wrapper and that wrapper only
  supports the 8-bit character version of PCRE.
- Removed JIT compiler support.  JIT support is not available using
  the POSIX wrapper, and Hercules only uses the POSIX wrapper.
- Changed option defaults to build only an 8-bit PCRE shared library.
  The POSIX wrapper only supports 8-bit PCRE.

---
&nbsp;
### Testing-related changes to CMakeLists.txt
- If PCRE\_BUILD\_TESTS is ON, the pcretest program compiled.  It is
  compiled without readline() support, as Windows does not have a
  native readline() function.
- Executable pcretest is linked with a 16mb stack.  Test 2 requires
  at least 8mb of stack according to test script comments.  This large
  stack affects only the pcretest executable and does not impact the
  resources required by the shared library.
- Only tests 1, 2, 3, 8, 13, and 14 are run when running pcretest.
  The other tests involve functionality not included in this build
  (16, 32-bit characters, JIT, Unicode, or UTF-8).
- NOTE: in the Windows command files that run the tests, comments
  state tha pcregrep is needed to run the tests.  This does not seem
  to be true, at least for tests of just 8-bit character sets, and
  pcregrep is not built.

---
&nbsp;
### Other changes to CMakeLists.txt
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
  they are present in CMAKE\_CONFIGURATION\_TYPES.
- Replaced references to the LOCATION property in get\_target\_properties
  with generator expressions to remove a requirement for policy
  CMP0026.
- Miscelaneous removals: MinGW/Cygwin support, UNIX-like target systems.

CMake 3.4 is the minimum version required to build PCRE from this repository 
because it is the same minimum version required for Hercules.

&nbsp;

---
This README.md file Copyright © 2017 by Stephen R. Orso.

This work is licensed under the Creative Commons Attribution-ShareAlike
4.0 International License.

To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/
or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
