# TKT-prep

This is just a simple repository where I host the files I use to make my defconfig
updates to the main [TKT](https://github.com/ETJAKEOC/TKT) project.

Feel free to uitlize and adapt this to your needs.

## How to use:

This script is relatively straight forward. You go to the [Linux Kernel Website](https://kernel.org)
and ensure that the kernel versions of the script are up to date with the latest available kernels
inside the 'fetch-kernels.sh' script. You then simply run this script, and it should have copied
the appropriate patches script, and the default 'TKT.conf' file into the kernel source directory.
From here, you run a 'make menuconfig', make any changes you wish, save, and exit. This is a smart
choice anyways, as using the defconfig from the '6.13-rc' kernel series on older kernels will
have options that the older kernels will not, this will rebuild the config properly, without
any options that do not exist in the older kernels.