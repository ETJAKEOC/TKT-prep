#!/bin/bash
# compile.sh

compile_kernel() {
    echo "Compiling the kernel..."
    time make -j$_MAKE_JOBS CC=$_COMPILER CFLAGS="$CFLAGS $_CFLAGS $_MAKE_O" bzImage modules headers
    [ $? -ne 0 ] && { echo "Kernel compilation failed."; exit 1; }
}
