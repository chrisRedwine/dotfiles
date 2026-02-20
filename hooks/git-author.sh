#!/usr/bin/env bash

set -e

CI=${CI:-false}

if $CI; then
  exit 0
fi

if ! command -v git &> /dev/null
then
  msg="The 'git' command is not available on this system. "
  msg+="Please ensure it is installed and available in your PATH."
  >&2 echo "$msg"
  exit 1
fi

set +e

git_username=$(git config --local user.name || git config --global user.name)
git_email=$(git config --local user.email || git config --global user.email)

set -e

ret_code=0

if [ -z "$git_username" ]; then
  >&2 echo "User name is empty - please set it using: 'git config --global user.name <GITHUB_USERNAME>'"
  ret_code=1
fi

if [ -z "$git_email" ]; then
  >&2 echo "User email is empty - please set it using: 'git config --global user.email <GITHUB_EMAIL>'"
  ret_code=1
fi

exit $ret_code
