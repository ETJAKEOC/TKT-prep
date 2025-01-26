#!/bin/bash
# configure.sh

configure_kernel() {
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

    # Set the CPU architecture in the kernel configuration
    if [[ "$_CPU_OPTIMIZE" =~ ^(yes|y)$ ]]; then
        case $_CPU_MARCH in
            "znver1")
                CONFIG_CPU="CONFIG_MZEN"
                ;;
            "znver2")
                CONFIG_CPU="CONFIG_MZEN2"
                ;;
            "znver3")
                CONFIG_CPU="CONFIG_MZEN3"
                ;;
            "znver4")
                CONFIG_CPU="CONFIG_MZEN4"
                ;;
            "znver5")
                CONFIG_CPU="CONFIG_MZEN5"
                ;;
            "nehalem")
                CONFIG_CPU="CONFIG_MNEHALEM"
                ;;
            "westmere")
                CONFIG_CPU="CONFIG_MWESTMERE"
                ;;
            "silvermont")
                CONFIG_CPU="CONFIG_MSILVERMONT"
                ;;
            "goldmont")
                CONFIG_CPU="CONFIG_MGOLDMONT"
                ;;
            "goldmont-plus")
                CONFIG_CPU="CONFIG_MGOLDMONTPLUS"
                ;;
            "sandybridge")
                CONFIG_CPU="CONFIG_MSANDYBRIDGE"
                ;;
            "ivybridge")
                CONFIG_CPU="CONFIG_MIVYBRIDGE"
                ;;
            "haswell")
                CONFIG_CPU="CONFIG_MHASWELL"
                ;;
            "broadwell")
                CONFIG_CPU="CONFIG_MBROADWELL"
                ;;
            "skylake")
                CONFIG_CPU="CONFIG_MSKYLAKE"
                ;;
            "skylake-avx512")
                CONFIG_CPU="CONFIG_MSKYLAKEX"
                ;;
            "cannonlake")
                CONFIG_CPU="CONFIG_MCANNONLAKE"
                ;;
            "icelake-client")
                CONFIG_CPU="CONFIG_MICELAKE"
                ;;
            "cascadelake")
                CONFIG_CPU="CONFIG_MCASCADELAKE"
                ;;
            "cooperlake")
                CONFIG_CPU="CONFIG_MCOOPERLAKE"
                ;;
            "tigerlake")
                CONFIG_CPU="CONFIG_MTIGERLAKE"
                ;;
            "sapphirerapids")
                CONFIG_CPU="CONFIG_MSAPPHIRERAPIDS"
                ;;
            "rocketlake")
                CONFIG_CPU="CONFIG_MROCKETLAKE"
                ;;
            "alderlake")
                CONFIG_CPU="CONFIG_MALDERLAKE"
                ;;
            "raptorlake")
                CONFIG_CPU="CONFIG_MRAPTORLAKE"
                ;;
            "meteorlake")
                CONFIG_CPU="CONFIG_MMETEORLAKE"
                ;;
            "emeraldrapids")
                CONFIG_CPU="CONFIG_MEMERALDRAPIDS"
                ;;
            *)
                CONFIG_CPU=""
                ;;
        esac

        if [ -n "$CONFIG_CPU" ]; then
            echo "Setting kernel CPU architecture to $_CPU_MARCH ($CONFIG_CPU)"
            sed -i "s/^CONFIG_GENERIC_CPU=.*/# CONFIG_GENERIC_CPU is not set/" .config
            echo "$CONFIG_CPU=y" >> .config
        else
            echo "CPU architecture $_CPU_MARCH not recognized, defaulting to generic-x86-64"
        fi
    fi

    [ "$_CONFIG_TOOL" != "skip" ] && make $_CONFIG_TOOL && echo "Kernel configuration completed." || echo "Skipping configuration step."
}
