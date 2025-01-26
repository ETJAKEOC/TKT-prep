#!/bin/bash
# packaging-deb.sh

package_deb() {
    echo "Packaging kernel for Debian/Ubuntu..."
    cd $_BUILD_DIR

    # Create the package
    make deb-pkg
    if [ $? -ne 0 ]; then
        echo "Failed to create Debian package."
        exit 1
    fi

    echo "Debian package created successfully."
}
