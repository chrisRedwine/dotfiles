#!/usr/bin/env bash

set -e

if ! command -v shellcheck &> /dev/null
then
  msg="The 'shellcheck' command is not available on this system. "
  msg+="Please install it using 'brew install shellcheck' for macOS (OS X) "
  msg+="or 'sudo apt install shellcheck' for Debian based distros."
  >&2 echo "$msg"
  exit 1
fi

# TODO: parse YAML files using 'yq' for any shell scripts and validate them as well

shellcheck "$@"
