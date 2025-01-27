#!/bin/bash
# patches.sh

apply_patches() {
    if [ ! -d "$_PATCHES_DIR" ]; then
        echo "Patches directory $_PATCHES_DIR not found. Please ensure you have a copy of the repository."
        exit 1
    fi

    echo "Applying patches from $_PATCHES_DIR/$_KERNEL_VERSION..."
    for patch in $_PATCHES_DIR/$_KERNEL_VERSION/*.patch; do
        patch -Np1 < $patch
        if [ $? -ne 0 ]; then
            echo "Failed to apply patch $patch"
            exit 1
        fi
    done

    if [[ "$_CPU_OPTIMIZE" =~ ^(yes|y)$ ]] && [ -f "$_PATCHES_DIR/common/more-uarches.patch" ]; then
        echo "Applying more-uarches.patch..."
        patch -Np1 < "$_PATCHES_DIR/common/more-uarches.patch"
        if [ $? -ne 0 ]; then
            echo "Failed to apply more-uarches.patch"
            exit 1
        fi
    fi

    if [[ "$_OPT_LEVEL" != "O2" ]] && [ -f "$_PATCHES_DIR/common/optimize-user.patch" ]; then
        echo "Applying user-specified optimization level..."
        patch -Np1 < "$_PATCHES_DIR/common/optimize-user.patch"
        if [ $? -ne 0 ]; then
            echo "Failed to apply user-specified optimization level."
            exit 1
        fi
    fi
}
