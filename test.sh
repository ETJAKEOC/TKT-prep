#!/bin/bash

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo "Unsupported Linux distribution."
        exit 1
    fi
}

# Function to load configuration from customization.cfg
load_config() {
    if [ -f "customization.cfg" ]; then
        . customization.cfg
    else
        echo "Configuration file not found."
    fi
}

# Function to prompt for user input if not specified in customization.cfg
prompt_user() {
    if [ -z "$KERNEL_VERSION" ]; then
        read -p "Enter the kernel version you want to compile (e.g., 5.10): " KERNEL_VERSION
    fi

    if [ -z "$PATCHES_DIR" ]; then
        PATCHES_DIR="versions/$KERNEL_VERSION/patches"
    fi

    if [ -z "$CONFIG_OPTION" ]; then
        echo "Choose your kernel configuration option:"
        echo "1. Provide your own config file"
        echo "2. Use running kernel config"
        echo "3. Use localmodconfig"
        echo "4. Use blank defconfig"
        read -p "Enter choice (1-4): " CONFIG_CHOICE
        case $CONFIG_CHOICE in
            1)
                read -p "Enter the path to your config file: " CONFIG_FILE
                CONFIG_OPTION="custom"
                ;;
            2)
                CONFIG_OPTION="running-kernel"
                ;;
            3)
                CONFIG_OPTION="localmodconfig"
                ;;
            4)
                CONFIG_OPTION="blank"
                ;;
            *)
                echo "Invalid choice."
                exit 1
                ;;
        esac
    fi

    if [ -z "$COMPILER" ]; then
        read -p "Enter the compiler to use (e.g., gcc, clang): " COMPILER
    fi

    if [ -z "$CPU_MARCH" ]; then
        echo "Do you want to optimize the kernel for your specific CPU architecture? (yes/no)"
        read -p "Enter choice: " CPU_OPTIMIZE
        if [[ "$CPU_OPTIMIZE" =~ ^(yes|y)$ ]]; then
            if [[ "$COMPILER" == "gcc" ]]; then
                CPU_MARCH=$(gcc -march=native -Q --help=target | grep -- '-march=' | awk '{print $2}')
            elif [[ "$COMPILER" == "clang" ]]; then
                CPU_MARCH=$(clang -march=native -### 2>&1 | grep -- '-target-cpu' | awk '{print $2}')
            else
                echo "Unsupported compiler."
                exit 1
            fi
        else
            CPU_MARCH="x86-64-v1"
        fi
    fi

    if [ -z "$OPT_LEVEL" ]; then
        read -p "Enter the optimization level (e.g., O2, O3): " OPT_LEVEL
    fi
}

# Function to download and extract kernel source
prepare_kernel_source() {
    KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_VERSION:0:1}.x/linux-${KERNEL_VERSION}.tar.xz"
    echo "Downloading kernel version ${KERNEL_VERSION} from ${KERNEL_URL}..."
    wget $KERNEL_URL -O linux-${KERNEL_VERSION}.tar.xz
    echo "Extracting kernel source..."
    tar -xf linux-${KERNEL_VERSION}.tar.xz
    cd linux-${KERNEL_VERSION}
}

# Function to apply patches
apply_patches() {
    if [ -d "$PATCHES_DIR" ]; then
        echo "Applying patches from $PATCHES_DIR..."
        for patch in $PATCHES_DIR/*.patch; do
            patch -Np1 < $patch
        done
    else
        echo "No patches directory found."
    fi
}

# Function to configure the kernel
configure_kernel() {
    case $CONFIG_OPTION in
        "custom")
            if [ -f "$CONFIG_FILE" ]; then
                echo "Copying custom config from $CONFIG_FILE..."
                cp $CONFIG_FILE .config
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
            DEFAULT_DEFCONFIG="versions/$KERNEL_VERSION/defconfig"
            if [ -f "$DEFAULT_DEFCONFIG" ]; then
                echo "Using default defconfig from $DEFAULT_DEFCONFIG..."
                cp $DEFAULT_DEFCONFIG .config
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
    make menuconfig
}

# Function to modify compilation flags
modify_flags() {
    echo "Modifying compilation flags..."
    sed -i "s/-O2/-${OPT_LEVEL}/" Makefile
    export CFLAGS="-pipe"
}

# Function to compile the kernel
compile_kernel() {
    echo "Compiling the kernel..."
    time make -j$(nproc) CC=$COMPILER CFLAGS="$CFLAGS -march=$CPU_MARCH -mtune=$CPU_MARCH" bzImage modules headers
}

# Main script execution
main() {
    detect_distro
    load_config
    prompt_user
    prepare_kernel_source
    apply_patches
    configure_kernel
    modify_flags
    compile_kernel

    echo "Kernel Version: $KERNEL_VERSION"
    echo "Patches Directory: $PATCHES_DIR"
    echo "Configuration Option: $CONFIG_OPTION"
    echo "Compiler: $COMPILER"
    echo "CPU March: $CPU_MARCH"
    echo "Optimization Level: $OPT_LEVEL"
    echo "Distribution: $DISTRO"

    # Add additional steps here (package, install)

    echo "Script execution completed for distribution: $DISTRO"
}

# Execute the main function
main
