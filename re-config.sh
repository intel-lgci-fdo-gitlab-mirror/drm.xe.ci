#!/bin/bash
#
# To be executed on a clean kernel checkout
# The xe/ci repo is needed and derived from the location
# of this script
#
# Final result is going to overwrite the final kconfig
# in the xe/ci repo

set -ex

CI_REPO=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

# Use the "config.orig" as base, merging the bare minimum CI requirements:
# it should be a distro-like config with most options enabled as modules,
# so that the end result can be booted on multiple machines to collect
# the lsmod output
fullkernel() {
	mkdir -p build64
	cp "$CI_REPO/kernel/config.orig" build64/.config
	make "-j$(nproc)" O=build64 olddefconfig

	pushd build64
	../scripts/kconfig/merge_config.sh .config "$CI_REPO/kernel/00-ci.fragment"
	popd
}

# After the lsmod output for several machines is collected and saved
# in the CI_REPO, trim down our configuration and apply the rest of
# the fragments
localkernel() {
	pushd build64
	cat "$CI_REPO"/kernel/lsmod/lsmod*.txt > lsmod.txt
	yes "" | make LSMOD=lsmod.txt localmodconfig

	for f in "$CI_REPO"/kernel/[0-9][0-9]*fragment; do
		../scripts/kconfig/merge_config.sh .config "$f"
	done

	make savedefconfig

	echo Overwriting "$CI_REPO/kernel/kconfig"
	cat defconfig > "$CI_REPO/kernel/kconfig"
	popd
}

if [ $# -eq 0 ]; then
	set -- full local
fi

if [[ "$1" == "full"* ]]; then
	fullkernel
	shift
fi

if [[ "$1" == "local"* ]]; then
	localkernel
	shift
fi
