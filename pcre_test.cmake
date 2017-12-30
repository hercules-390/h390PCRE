
file( TO_NATIVE_PATH ${srcdir}  srcdir )
file( TO_NATIVE_PATH ${exepath} exepath )
file( TO_NATIVE_PATH ${batpath} batpath )

execute_process( COMMAND ${batpath} ${srcdir} ${exepath}
            RESULT_VARIABLE rc
            OUTPUT_VARIABLE stdout
            ERROR_VARIABLE stdout
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
            )

message( "${stdout}" )

