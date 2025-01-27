#!/bin/bash
# optimization.sh

set_optimization_level() {
	cp $_SCRIPT_DIR/patches/optimize-base.patch $_SCRIPT_DIR/patches/optimize-user.patch
	echo "Setting optimization level to $_OPT_LEVEL in the user-specific patch..."
	sed -i "s/-O3/-O${_OPT_LEVEL}/g" $_SCRIPT_DIR/patches/optimize-user.patch
	_MAKE_O="-O${_OPT_LEVEL}"
	echo "_MAKE_O=$_MAKE_O"
}
