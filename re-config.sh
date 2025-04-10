#!/bin/bash
# Builds a kernel kconfig flavor (from kernel/flavors) and saves it in the "kernel" dir.
# Usage:
#     KERNEL_REPO=path/to/any/kernel/checkout ./re-config.sh <flavor-name>
#
# flavor-name may be the file under kernel/flavors/ or just the name.
# This updates the kconfig for all flavors:
#     KERNEL_REPO=path/to/any/kernel/checkout ./re-config.sh kernel/flavors/*
set -ex

XE_CI_DIR_PATH="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
FLAVORS=("$@")

# If no flavors were specified, just regenerate all of them:
if [[ "$FLAVORS" == "" ]]; then
	FLAVORS=($(find "$XE_CI_DIR_PATH/kernel" -name "*.flavor"))
fi

# Extract and sanitize flavors
for ((i=0; i<${#FLAVORS[@]}; i++)); do
	f="$(basename ${FLAVORS[i]})"
	f="${f%.flavor}"
	FLAVORS[i]="$f"
done

pushd "$XE_CI_DIR_PATH/kernel"
for f in "${FLAVORS[@]}"; do
	if [[ ! -f "flavors/$f.flavor" ]]; then
		echo "Flavor '$f' does not exist."
		exit 1
	fi

	export KCONFIG_CONFIG="$f.kconfig"
	xargs -a "flavors/$f.flavor" -- "$XE_CI_DIR_PATH/vendor/merge_config.sh" -m

	if [[ "$f" == "debug" ]]; then
		echo "Saving output to 'kconfig' too for backwards compatibility"
		cp "$XE_CI_DIR_PATH/kernel/$f.kconfig" "$XE_CI_DIR_PATH/kernel/kconfig"
	fi
done
popd
