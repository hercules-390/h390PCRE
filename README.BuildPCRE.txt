File README.BuildPCRE.txt - PCRE build instructions for use with Hercules

This document Copyright © 2017 by Stephen R. Orso.  License at the bottom.

BUILDING the PCRE library for use by Hercules

    NOTE: This package is not required for UNIX-like environments.
    Those systems include regular expression support in the base system.

    This repository builds the PCRE libraries for use by Hercules in a
    Windows system (or, potentially, non-Windows systems that lack
    regular expression support).  Hercules does not require anything but
    the libraries, and a CMake build script is included to generate the
    scripts needed to compile the libraries.  Shared libraries (.dll)
    are created, as are DLL import libraries.

    PCRE builds two libraries, pcre.dll with PERL-compatible regular
    expression support, and pcreposix.dll which exposes a POSIX
    interface.

    The original PCRE distribution, available from http://www.pcre.org/,
    includes a number of configure and build scripts, including CMake,
    NMake, GNU Makefiles, and Visual Studio projects.  The configure and
    build process here is based on the CMakeLists.txt script.


BUILDING the PCRE library using CMake

    Because Windows systems do not include POSIX regular expression
    support and PCRE does not offer a standardized Windows installable
    package, the Hercules build always will automatically build the PCRE
    libraries in the Hercules build directory; no additional steps are
    needed.

    The following procedure is needed only if one wishes to develop and
    test changes to PCRE, for example an uplevel PCRE version, in
    Hercules.  There is no need to "install" the library; Hercules can
    be pointed to the uplevel PCRE build directory.

    1.  If you are building on Windows, open a Visual Studio command
        prompt for the bit-ness of your system.  For example, on
        a 64-bit Windows 10 system with Visual Studio 2017 Community
        Edition installed, this would be "x64 Native Tools Command
        Prompt for VS 2017"

    2.  Clone this repository: git clone https://hercules-390/PCRE

    3.  Create the directory that will be the build directory you wish
        to populate with PCRE if needed.

    4.  Change to that build directory

    5.  Create the build scripts for the PCRE library by using the
        following CMake command:

            cmake <source-dir>

    6.  Build the PCRE library using the following CMake command:

            cmake --build .  --config release

    7.  When building Hercules using CMake, use the command line option

            -DPCRE_DIR=<build-dir>

        to point the Hercules build at your PCRE build directory.




This work is licensed under the Creative Commons Attribution-
ShareAlike 4.0 International License.

To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/
or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

