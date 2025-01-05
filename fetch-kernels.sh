
#!/bin/bash

# Define kernel versions
KERNEL_VERSIONS=(
    "6.1.123"
    "6.6.69"
    "6.12.8"
    "6.13-rc5"
)

# Function to download a kernel version
download_kernel() {
    local version="$1"
    if [[ "$version" == *"-rc"* ]]; then
        aria2c "https://git.kernel.org/torvalds/t/linux-${version}.tar.gz"
    else
        aria2c "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${version}.tar.xz"
    fi
}

# Function to extract a kernel version
extract_kernel() {
    local version="$1"
    if [[ "$version" == *"-rc"* ]]; then
        tar -xf "linux-${version}.tar.gz"
    else
        tar -xf "linux-${version}.tar.xz"
    fi
}

# Function to set up a kernel directory
setup_kernel() {
    local version="$1"
    cp TKT.config "linux-${version}/.config"
    local major_minor_version="${version%%.*}.${version#*.}"  # Extract major.minor version
    major_minor_version="${major_minor_version%.*}"           # Remove patch level
    local patch_script="apply-patches-${major_minor_version}.sh"
    if [[ -f "$patch_script" ]]; then
        cp -a "$patch_script" "linux-${version}/"
    else
        echo "Warning: Patch script $patch_script not found for version $version"
    fi
}

# Main script logic
for version in "${KERNEL_VERSIONS[@]}"; do
    echo "Processing kernel version: $version"
    download_kernel "$version"
    extract_kernel "$version"
    setup_kernel "$version"
done

# Clean up archive files
rm -f ./*.tar.xz ./*.tar.gz

echo "All kernels processed!"
