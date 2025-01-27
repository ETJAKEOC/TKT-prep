#!/bin/bash
# install.sh

# Determine the directory where the script is running from
_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Source individual scripts
source $_SCRIPT_DIR/scripts/customization.sh
source $_SCRIPT_DIR/scripts/prepare.sh
source $_SCRIPT_DIR/scripts/optimization.sh
source $_SCRIPT_DIR/scripts/patches.sh
source $_SCRIPT_DIR/scripts/configure.sh
source $_SCRIPT_DIR/scripts/compile.sh
source $_SCRIPT_DIR/scripts/packaging-arch.sh
source $_SCRIPT_DIR/scripts/packaging-deb.sh
source $_SCRIPT_DIR/scripts/packaging-rpm.sh

# Main script execution
_main() {
    # Load config
    echo "Loading configuration..."
    [ -f "$_SCRIPT_DIR/customization.cfg" ] && . "$_SCRIPT_DIR/customization.cfg" || echo "Configuration file not found."

    # Load scripts
    customize_installation
    prepare_env_and_source
    set_optimization_level
    apply_patches
    configure_kernel
    compile_kernel

    # Determine packaging format
    case $_PACKAGING_FORMAT in
        arch)
            package_arch
            ;;
        deb)
            package_deb
            ;;
        rpm)
            package_rpm
            ;;
        none)
            echo "No packaging format recognized. Kernel compiled but not packaged."
            ;;
    esac

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
