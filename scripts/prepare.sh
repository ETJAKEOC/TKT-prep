#!/bin/bash
# prepare.sh

prepare_env_and_source() {
#Check the current distribution
	if [ -f /etc/os-release ]; then
		. /etc/os-release
		_DISTRO=$ID
	else
		echo "Unsupported Linux distribution."
		exit 1
	fi

# If building kernel 6.12/6.13, we pull from the FreeDesktop DRM repo, to take advantage of GPU patches.
	if [ "${_KERNEL_VERSION}" = "6.12" ] || [ "${_KERNEL_VERSION}" = "6.13" ]; then
		KERNEL_URL="https://gitlab.freedesktop.org/agd5f/linux/-/archive/drm-fixes-${_KERNEL_VERSION}/linux-drm-fixes-${_KERNEL_VERSION}.tar.gz"
		TAR_FILE="linux-${_KERNEL_VERSION}.tar.gz"
	else
		KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v${_KERNEL_VERSION:0:1}.x/linux-${_KERNEL_VERSION}.tar.xz"
		TAR_FILE="linux-${_KERNEL_VERSION}.tar.xz"
	fi

# Extract the sources, and if they were already extracted, cleanup
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

# Copy the user-specified config file to the build directory as .config
	if [ -n "$_CONFIG_FILE" ]; then
		if [ -f "$_CONFIG_FILE" ]; then
		cp "$_CONFIG_FILE" "$_BUILD_DIR/.config"
			echo "Copied custom config file to $_BUILD_DIR/.config"
		else
			echo "Specified config file $_CONFIG_FILE does not exist."
			exit 1
		fi
	else
		echo "No custom config file specified."
	fi
	cd $_BUILD_DIR
}
