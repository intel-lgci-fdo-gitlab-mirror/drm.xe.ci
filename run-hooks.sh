#!/usr/bin/bash
run-parts --exit-on-error --verbose "$(dirname $0)/hooks"
