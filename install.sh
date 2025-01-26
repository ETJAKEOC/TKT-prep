#!/bin/bash
# install.sh

# Determine the directory where the script is running from
_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Source individual scripts
source $_SCRIPT_DIR/scripts/prepare.sh
source $_SCRIPT_DIR/scripts/optimization.sh
source $_SCRIPT_DIR/scripts/patches.sh
source $_SCRIPT_DIR/scripts/configure.sh
source $_SCRIPT_DIR/scripts/compile.sh

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
        # Always use gcc to detect the CPU architecture
        _CPU_MARCH=$(/bin/gcc -march=native -Q --help=target | grep -- '-march=' | awk '{print $2}' | head -n 1)
        if [[ "$_COMPILER" == "clang" ]]; then
            CFLAGS="-pipe -march=$_CPU_MARCH -mtune=$_CPU_MARCH -flto"
        elif [[ "$_COMPILER" == "gcc" ]]; then
            CFLAGS="-pipe -march=$_CPU_MARCH -mtune=$_CPU_MARCH"
        else
            echo "Unsupported compiler."
            exit 1
        fi
        echo "Detected CPU architecture: $_CPU_MARCH"
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

    prepare_env_and_source
    set_optimization_level
    apply_patches
    configure_kernel
    compile_kernel

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
