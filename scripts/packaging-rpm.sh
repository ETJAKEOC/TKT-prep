#!/bin/bash
# packaging-rpm.sh

package_rpm() {
    echo "Packaging kernel for RPM-based distributions (Fedora, CentOS, etc.)..."
    cd $_BUILD_DIR

    # Create the package
    make rpm-pkg
    if [ $? -ne 0 ]; then
        echo "Failed to create RPM package."
        exit 1
    fi

    echo "RPM package created successfully."
}
