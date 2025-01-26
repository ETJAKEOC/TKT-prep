#!/bin/bash
# compile.sh

compile_kernel() {
    echo "Compiling the kernel..."
    if [[ "$_COMPILER" == "clang" ]]; then
	    time make -j$_MAKE_JOBS $_LLVM_ENV CFLAGS="$CFLAGS $_CFLAGS $_MAKE_O" bzImage modules headers
        elif [[ "$_COMPILER" == "gcc" ]]; then
	    time make -j$_MAKE_JOBS $_GCC_ENV CFLAGS="$CFLAGS $_CFLAGS $_MAKE_O" bzImage modules headers
	else
	    [ $? -ne 0 ] && { echo "Kernel compilation failed."; exit 1; }
    fi
}
