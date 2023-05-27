#!/usr/bin/bash

set -e

cleanup() {
    retcode=$?
    workdir="$1"

    # Because Docker, we need to chown external things back at exit
    if [[ -d "$workdir" && "$(pwd)" == "$workdir" ]]; then
        current_ugid="$(id -u):$(id -g)"
        target_ugid="$(stat -c "%u:%g" "$workdir")"

        if [[ "$current_ugid" != "$target_ugid" ]]; then
            chown -R "$target_ugid" "$workdir"
        fi
    fi

    exit $retcode
}

if [[ "$CI" == "true" ]]; then
    git config --global safe.directory '*'
    trap "cleanup $CI_WORKSPACE_DIR" EXIT
fi

run-parts --exit-on-error --verbose "$(dirname $0)/hooks"

echo "All hooks done"
