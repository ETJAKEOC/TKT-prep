#!/bin/bash
# prepare.sh

prepare_env_and_source() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        _DISTRO=$ID
    else
        echo "Unsupported Linux distribution."
        exit 1
    fi

    KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v${_KERNEL_VERSION:0:1}.x/linux-${_KERNEL_VERSION}.tar.xz"
    TAR_FILE="linux-${_KERNEL_VERSION}.tar.xz"

    if [ -f "$TAR_FILE" ]; then
        echo "Kernel tarball already downloaded. Not redownloading."
    else
        echo "Downloading kernel version ${_KERNEL_VERSION} from ${KERNEL_URL}..."
        wget $KERNEL_URL -O $TAR_FILE
    fi

    if [ -d "$_BUILD_DIR" ]; then
        echo "Build directory $_BUILD_DIR already exists. Cleaning..."
        rm -rf $_BUILD_DIR
    fi

    echo "Extracting kernel source to $_BUILD_DIR..."
    mkdir -p $_BUILD_DIR
    tar -xf $TAR_FILE -C $_BUILD_DIR --strip-components=1
    cd $_BUILD_DIR
}
