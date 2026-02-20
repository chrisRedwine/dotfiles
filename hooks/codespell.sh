#!/usr/bin/env bash

set -e

if ! command -v codespell &> /dev/null
then
  msg="The 'codespell' command is not available on this system. "
  msg+="Please ensure it is installed and available in your PATH."
  >&2 echo "$msg"
  exit 1
fi

codespell "$@"
