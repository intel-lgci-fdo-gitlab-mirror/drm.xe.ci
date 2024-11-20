#!/bin/bash
# Builds a kernel kconfig flavor (from kernel/flavors) and saves it in the "kernel" dir.
# Usage: KERNEL_REPO=path/to/any/kernel/checkout ./re-config.sh <profile-name>

set -ex

FLAVORS=("$@")
KCONFIGS_PATH="$(realpath "$(dirname "${BASH_SOURCE[0]}")")/kernel"

: ${KERNEL_REPO:="~/linux"}
: ${MERGE_CONFIG:="$KERNEL_REPO/scripts/kconfig/merge_config.sh"}

if [[ ! -f "$MERGE_CONFIG" ]]; then
	echo "$MERGE_CONFIG script does not exist."
	echo "Provide a path to a kernel checkout using the KERNEL_REPO env var."
	exit 1
fi

pushd $KCONFIGS_PATH
for f in "${FLAVORS[@]}"; do
	if [[ ! -f "flavors/$f.flavor" ]]; then
		echo "Flavor '$f' does not exist."
		exit 1
	fi

	export KCONFIG_CONFIG="$f.kconfig"
	xargs -a "flavors/$f.flavor" -- "$MERGE_CONFIG" -m

	if [[ "$f" == "debug" ]]; then
		echo "Saving output to 'kconfig' too for backwards compatibility"
		cp "$KCONFIGS_PATH/$f.kconfig" "$KCONFIGS_PATH/kconfig"
	fi
done
popd
