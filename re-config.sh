#!/bin/bash
# Builds a kernel kconfig flavor (from kernel/flavors) and saves it in the "kernel" dir.
# Usage: KERNEL_REPO=path/to/any/kernel/checkout ./re-config.sh <profile-name>

set -ex

if [[ "$#" < 1 ]]; then
	echo "Provide the kconfig flavor to create."
	exit 1
fi

FLAVOR="$1"
KCONFIGS_PATH="$(realpath "$(dirname "${BASH_SOURCE[0]}")")/kernel"

: ${KERNEL_REPO:="~/linux"}
: ${MERGE_CONFIG:="$KERNEL_REPO/scripts/kconfig/merge_config.sh"}

if [[ ! -f "$MERGE_CONFIG" ]]; then
	echo "$MERGE_CONFIG script does not exist."
	echo "Provide a path to a kernel checkout using the KERNEL_REPO env var."
	exit 1
fi

if [[ ! -f "$KCONFIGS_PATH/flavors/$FLAVOR.flavor" ]]; then
	echo "Flavor '$FLAVOR' does not exist."
	exit 1
fi

pushd $KCONFIGS_PATH
export KCONFIG_CONFIG="$FLAVOR.kconfig"
xargs -a "flavors/$FLAVOR.flavor" -- "$MERGE_CONFIG" -m
popd

if [[ "$FLAVOR" == "debug" ]]; then
	echo "Saving output to 'kconfig' too for backwards compatibility"
	cp "$KCONFIGS_PATH/$FLAVOR.kconfig" "$KCONFIGS_PATH/kconfig"
fi
