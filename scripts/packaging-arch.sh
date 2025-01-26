#!/bin/bash
# packaging-arch.sh

package_arch() {
    echo "Packaging kernel for Arch Linux..."
    cd $_BUILD_DIR

    # Create the package
    make tar-pkg
    if [ $? -ne 0 ]; then
        echo "Failed to create Arch Linux package."
        exit 1
    fi

    echo "Arch Linux package created successfully."
}
