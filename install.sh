#!/bin/bash

# Determine the directory where the script is running from
_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Function to detect the Linux distribution and prepare kernel source
_prepare_env_and_source() {
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

# Function to set the user optimization level in the optimization patch.
_optimization() {
    # Create a copy of the base patch for user-specific optimization
    cp $_SCRIPT_DIR/patches/optimize-harder.patch $_SCRIPT_DIR/patches/optimize-user.patch
    echo "Setting optimization level to $_OPT_LEVEL in the user-specific patch..."
    sed -i "s/-O3/-O${_OPT_LEVEL}/g" $_SCRIPT_DIR/patches/optimize-user.patch
    _MAKE_O="-O${_OPT_LEVEL}"
    echo "CFLAGS=$_MAKE_O"
}

# Function to apply patches
_apply_patches() {
    if [ ! -d "$_PATCHES_DIR" ]; then
        echo "Patches directory $_PATCHES_DIR not found. Please ensure you have a copy of the repository."
        exit 1
    fi

    echo "Applying patches from $_PATCHES_DIR..."
    for patch in $_PATCHES_DIR/*.patch; do
        patch -Np1 < $patch
        if [ $? -ne 0 ]; then
            echo "Failed to apply patch $patch"
            exit 1
        fi
    done

    if [[ "$_CPU_OPTIMIZE" =~ ^(yes|y)$ ]] && [ -f "$_SCRIPT_DIR/patches/more-uarches.patch" ]; then
        echo "Applying more-uarches.patch..."
        patch -Np1 < "$_SCRIPT_DIR/patches/more-uarches.patch"
        if [ $? -ne 0 ]; then
            echo "Failed to apply more-uarches.patch"
            exit 1
        fi
    fi

    if [[ "$_OPT_LEVEL" != "O2" ]] && [ -f "$_SCRIPT_DIR/patches/optimize-user.patch" ]; then
        echo "Applying user-specified optimization level..."
        patch -Np1 < "$_SCRIPT_DIR/patches/optimize-user.patch"
        if [ $? -ne 0 ]; then
            echo "Failed to apply user-specified optimization level."
            exit 1
        fi
    fi
}

# Function to configure the kernel
_configure_kernel() {
    case $_CONFIG_OPTION in
        "custom")
            [ -f "$_CONFIG_FILE" ] && cp $_CONFIG_FILE .config || { echo "Custom config file not found."; exit 1; }
            ;;
        "running-kernel")
            [ -f /proc/config.gz ] && zcat /proc/config.gz > .config || { echo "/proc/config.gz not found."; exit 1; }
            ;;
        "localmodconfig")
            make localmodconfig
            ;;
        "blank")
            _DEFAULT_DEFCONFIG="configs/$_KERNEL_VERSION/config.x86_64"
            [ -f "$_DEFAULT_DEFCONFIG" ] && cp $_DEFAULT_DEFCONFIG .config || { echo "Default defconfig not found."; exit 1; }
            ;;
        *)
            echo "Invalid configuration option."
            exit 1
            ;;
    esac

    [ "$_CONFIG_TOOL" != "skip" ] && make $_CONFIG_TOOL && echo "Kernel configuration completed." || echo "Skipping configuration step."
}

# Function to compile the kernel
_compile_kernel() {
    echo "Compiling the kernel..."
    time make -j$_MAKE_JOBS CC=$_COMPILER CFLAGS="$CFLAGS $_CFLAGS $_MAKE_O" bzImage modules headers
    [ $? -ne 0 ] && { echo "Kernel compilation failed."; exit 1; }
}

# Main script execution
_main() {
    # Load config
    echo "Loading configuration..."
    [ -f "$_SCRIPT_DIR/customization.cfg" ] && . "$_SCRIPT_DIR/customization.cfg" || echo "Configuration file not found."

    # Prompt for kernel version with 6.13 as the default
    echo "Available kernel versions to promote:"
    echo "1. 6.1 (LTS)"
    echo "2. 6.6 (LTS)"
    echo "3. 6.12 (Stable)"
    echo "4. 6.13 (Latest Stable, default)"
    read -p "Enter the number for the kernel version you want to compile (1-4): " _KERNEL_CHOICE
    case $_KERNEL_CHOICE in
        1)
            _KERNEL_VERSION="6.1"
            ;;
        2)
            _KERNEL_VERSION="6.6"
            ;;
        3)
            _KERNEL_VERSION="6.12"
            ;;
        4|"")
            _KERNEL_VERSION="6.13"
            ;;
        *)
            echo "Invalid choice. Defaulting to 6.13."
            _KERNEL_VERSION="6.13"
            ;;
    esac

    # Prompt for build directory
    read -p "Enter the directory to store the kernel source (default: linux-src): " _BUILD_DIR
    _BUILD_DIR=${_BUILD_DIR:-linux-src}

    # Set patches directory
    _PATCHES_DIR="$_SCRIPT_DIR/patches/$_KERNEL_VERSION"

    # Prompt for configuration option with running-kernel as the default
    echo "Choose your kernel configuration option:"
    echo "1. Provide your own config file"
    echo "2. Use running kernel config (default)"
    echo "3. Use localmodconfig"
    echo "4. Use blank defconfig"
    read -p "Enter choice (1-4): " _CONFIG_CHOICE
    case $_CONFIG_CHOICE in
        1)
            read -p "Enter the path to your config file: " _CONFIG_FILE
            _CONFIG_OPTION="custom"
            ;;
        2|"")
            _CONFIG_OPTION="running-kernel"
            ;;
        3)
            _CONFIG_OPTION="localmodconfig"
            ;;
        4)
            _CONFIG_OPTION="blank"
            ;;
        *)
            echo "Invalid choice. Defaulting to running kernel config."
            _CONFIG_OPTION="running-kernel"
            ;;
    esac

    # Prompt for compiler with clang as the default
    echo "Choose your compiler:"
    echo "1. Clang (default)"
    echo "2. GCC"
    read -p "Enter choice (1-2): " _COMPILER_CHOICE
    case $_COMPILER_CHOICE in
        1|"")
            _COMPILER="clang"
            ;;
        2)
            _COMPILER="gcc"
            ;;
        *)
            echo "Invalid choice. Defaulting to clang."
            _COMPILER="clang"
            ;;
    esac

    # Prompt for CPU optimization with yes as the default
    read -p "Do you want to optimize the kernel for your specific CPU architecture? (yes/default or no): " _CPU_OPTIMIZE
    _CPU_OPTIMIZE=${_CPU_OPTIMIZE:-yes}

    if [[ "$_CPU_OPTIMIZE" =~ ^(yes|y)$ ]]; then
        if [ -z "$_CPU_MARCH" ]; then
            if [[ "$_COMPILER" == "clang" ]]; then
                _CPU_MARCH=$(clang -march=native -### 2>&1 | grep -- '-target-cpu' | awk '{print $2}')
                CFLAGS="-pipe -march=$_CPU_MARCH -mtune=$_CPU_MARCH -flto"
            elif [[ "$_COMPILER" == "gcc" ]]; then
                _CPU_MARCH=$(gcc -march=native -Q --help=target | grep -- '-march=' | awk '{print $2}')
                CFLAGS="-pipe -march=$_CPU_MARCH -mtune=$_CPU_MARCH"
            else
                echo "Unsupported compiler."
                exit 1
            fi
        fi
    else
        _CPU_MARCH="x86-64-v1"
    fi

    # Prompt for optimization level with O3 as the default
    echo "Choose your optimization level:"
    echo "1. O1"
    echo "2. O2"
    echo "3. O3 (default)"
    echo "4. Ofast"
    echo "5. Osize"
    read -p "Enter choice (1-5): " _OPT_LEVEL_CHOICE
    case $_OPT_LEVEL_CHOICE in
        1)
            _OPT_LEVEL="1"
            ;;
        2)
            _OPT_LEVEL="2"
            ;;
        3|"")
            _OPT_LEVEL="3"
            ;;
        4)
            _OPT_LEVEL="fast"
            ;;
        5)
            _OPT_LEVEL="size"
            ;;
        *)
            echo "Invalid choice. Defaulting to O3."
            _OPT_LEVEL="3"
            ;;
    esac

    # Prompt for configuration tool with skip as the default
    echo "Choose your configuration tool:"
    echo "1. menuconfig"
    echo "2. nconfig"
    echo "3. skip (default)"
    read -p "Enter choice (1-3): " _CONFIG_TOOL_CHOICE
    case $_CONFIG_TOOL_CHOICE in
        1)
            _CONFIG_TOOL="menuconfig"
            ;;
        2)
            _CONFIG_TOOL="nconfig"
            ;;
        3|"")
            _CONFIG_TOOL="skip"
            ;;
        *)
            echo "Invalid choice. Defaulting to skip."
            _CONFIG_TOOL="skip"
            ;;
    esac

    # Prompt for the number of make jobs
    echo "Choose the number of make jobs:"
    echo "1. User-defined"
    echo "2. Arch/Gentoo makepkg.conf/make.conf"
    echo "3. nproc (number of available processors)"
    read -p "Enter choice (1-3): " _MAKE_JOBS_CHOICE
    case $_MAKE_JOBS_CHOICE in
        1)
            read -p "Enter the number of make jobs: " _MAKE_JOBS
            ;;
        2)
            if [[ -f /etc/makepkg.conf ]]; then
                _MAKE_JOBS=$(grep -E '^MAKEFLAGS=' /etc/makepkg.conf | sed 's/.*-j\([0-9]\+\).*/\1/')
            elif [[ -f /etc/portage/make.conf ]]; then
                _MAKE_JOBS=$(grep -E '^MAKEOPTS=' /etc/portage/make.conf | sed 's/.*-j\([0-9]\+\).*/\1/')
            else
                echo "Configuration file for make jobs not found. Defaulting to nproc."
                _MAKE_JOBS=$(nproc)
            fi
            ;;
        3|"")
            _MAKE_JOBS=$(nproc)
            ;;
        *)
            echo "Invalid choice. Defaulting to nproc."
            _MAKE_JOBS=$(nproc)
            ;;
    esac

    _prepare_env_and_source
    _optimization
    _apply_patches
    _configure_kernel
    _compile_kernel

    echo "Kernel Version: $_KERNEL_VERSION"
    echo "Patches Directory: $_PATCHES_DIR"
    echo "Configuration Option: $_CONFIG_OPTION"
    echo "Compiler: $_COMPILER"
    echo "CPU March: $_CPU_MARCH"
    echo "Optimization Level: $_OPT_LEVEL"
    echo "Configuration Tool: $_CONFIG_TOOL"
    echo "Build Directory: $_BUILD_DIR"
    echo "Number of Make Jobs: $_MAKE_JOBS"
    echo "Distribution: $_DISTRO"

    # Add additional steps here (package, install)

    echo "Script execution completed for distribution: $_DISTRO"
}

# Execute the main function
_main
