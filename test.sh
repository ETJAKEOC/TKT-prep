#!/bin/bash

# Function to detect the Linux distribution
_detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        _DISTRO=$ID
    else
        echo "Unsupported Linux distribution."
        exit 1
    fi
}

# Function to load configuration from customization.cfg
_load_config() {
    if [ -f "customization.cfg" ]; then
        . customization.cfg
    else
        echo "Configuration file not found."
    fi
}

# Function to prompt for user input if not specified in customization.cfg
_prompt_user() {
    if [ -z "$_KERNEL_VERSION" ]; then
        echo "Available kernel versions to promote:"
        echo "1. 6.1 (LTS)"
        echo "2. 6.6 (LTS)"
        echo "3. 6.12 (Stable)"
        echo "4. 6.13 (Latest Stable)"
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
            4)
                _KERNEL_VERSION="6.13"
                ;;
            *)
                echo "Invalid choice."
                exit 1
                ;;
        esac
    fi

    if [ -z "$_PATCHES_DIR" ]; then
        _PATCHES_DIR="patches/$_KERNEL_VERSION"
    fi

    if [ -z "$_CONFIG_OPTION" ]; then
        echo "Choose your kernel configuration option:"
        echo "1. Provide your own config file"
        echo "2. Use running kernel config"
        echo "3. Use localmodconfig"
        echo "4. Use blank defconfig"
        read -p "Enter choice (1-4): " _CONFIG_CHOICE
        case $_CONFIG_CHOICE in
            1)
                read -p "Enter the path to your config file: " _CONFIG_FILE
                _CONFIG_OPTION="custom"
                ;;
            2)
                _CONFIG_OPTION="running-kernel"
                ;;
            3)
                _CONFIG_OPTION="localmodconfig"
                ;;
            4)
                _CONFIG_OPTION="blank"
                ;;
            *)
                echo "Invalid choice."
                exit 1
                ;;
        esac
    fi

    if [ -z "$_COMPILER" ]; then
        echo "Choose your compiler:"
        echo "1. Clang (default)"
        echo "2. GCC"
        read -p "Enter choice (1-2): " _COMPILER_CHOICE
        case $_COMPILER_CHOICE in
            1|*)
                _COMPILER="clang"
                ;;
            2)
                _COMPILER="gcc"
                ;;
        esac
    fi

    if [ -z "$_CPU_MARCH" ]; then
        echo "Do you want to optimize the kernel for your specific CPU architecture? (yes/no)"
        read -p "Enter choice: " _CPU_OPTIMIZE
        if [[ "$_CPU_OPTIMIZE" =~ ^(yes|y)$ ]]; then
            if [[ "$_COMPILER" == "clang" ]]; then
                _CPU_MARCH=$(clang -march=native -### 2>&1 | grep -- '-target-cpu' | awk '{print $2}')
                _MAKE='make LLVM=1 LLVM_IAS=1'
            elif [[ "$_COMPILER" == "gcc" ]]; then
                _CPU_MARCH=$(gcc -march=native -Q --help=target | grep -- '-march=' | awk '{print $2}')
                _MAKE='make'
            else
                echo "Unsupported compiler."
                exit 1
            fi
        else
            _CPU_MARCH="x86-64-v1"
        fi
    fi

    if [ -z "$_OPT_LEVEL" ]; then
        read -p "Enter the optimization level (e.g., O2, O3): " _OPT_LEVEL
    fi

    if [ -z "$_CONFIG_TOOL" ]; then
        echo "Choose your configuration tool:"
        echo "1. menuconfig"
        echo "2. nconfig"
        echo "3. Skip configuration"
        read -p "Enter choice (1-3): " _CONFIG_TOOL_CHOICE
        case $_CONFIG_TOOL_CHOICE in
            1)
                _CONFIG_TOOL="menuconfig"
                ;;
            2)
                _CONFIG_TOOL="nconfig"
                ;;
            3)
                _CONFIG_TOOL="skip"
                ;;
            *)
                echo "Invalid choice."
                exit 1
                ;;
        esac
    fi
}

# Function to download and extract kernel source
_prepare_kernel_source() {
    KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v${_KERNEL_VERSION:0:1}.x/linux-${_KERNEL_VERSION}.tar.xz"
    echo "Downloading kernel version ${_KERNEL_VERSION} from ${KERNEL_URL}..."
    wget $KERNEL_URL -O linux-${_KERNEL_VERSION}.tar.xz
    echo "Extracting kernel source..."
    tar -xf linux-${_KERNEL_VERSION}.tar.xz
    cd linux-${_KERNEL_VERSION}
}

# Function to apply patches
_apply_patches() {
    if [ -d "$_PATCHES_DIR" ]; then
        echo "Applying patches from $_PATCHES_DIR..."
        for patch in $_PATCHES_DIR/*.patch; do
            patch -Np1 < $patch
        done
    else
        echo "No patches directory found."
    fi
}

# Function to configure the kernel
_configure_kernel() {
    case $_CONFIG_OPTION in
        "custom")
            if [ -f "$_CONFIG_FILE" ]; then
                echo "Copying custom config from $_CONFIG_FILE..."
                cp $_CONFIG_FILE .config
            else
                echo "Custom config file not found."
                exit 1
            fi
            ;;
        "running-kernel")
            if [ -f /proc/config.gz ]; then
                echo "Using config from running kernel..."
                zcat /proc/config.gz > .config
            else
                echo "/proc/config.gz not found."
                exit 1
            fi
            ;;
        "localmodconfig")
            echo "Using localmodconfig..."
            make localmodconfig
            ;;
        "blank")
            _DEFAULT_DEFCONFIG="configs/$_KERNEL_VERSION/config.x86_64"
            if [ -f "$_DEFAULT_DEFCONFIG" ]; then
                echo "Using default defconfig from $_DEFAULT_DEFCONFIG..."
                cp $_DEFAULT_DEFCONFIG .config
            else
                echo "Default defconfig not found."
                exit 1
            fi
            ;;
        *)
            echo "Invalid configuration option."
            exit 1
            ;;
    esac

    if [ "$_CONFIG_TOOL" != "skip" ]; then
        echo "Running $_CONFIG_TOOL..."
        make $_CONFIG_TOOL
    else
        echo "Skipping configuration step."
    fi
}

# Function to compile the kernel
_compile_kernel() {
    echo "Compiling the kernel..."
    sed -i "s/-O2/-${_OPT_LEVEL}/" Makefile
    time $_MAKE -j$(nproc) CC=$_COMPILER CFLAGS="$CFLAGS -pipe -march=$_CPU_MARCH -mtune=$_CPU_MARCH" bzImage modules headers
}

# Main script execution
_main() {
    _detect_distro
    _load_config
    _prompt_user
    _prepare_kernel_source
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
    echo "Distribution: $_DISTRO"

    # Add additional steps here (package, install)

    echo "Script execution completed for distribution: $_DISTRO"
}

# Execute the main function
_main
