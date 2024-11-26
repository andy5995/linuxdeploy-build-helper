#!/bin/bash

set -e

echo ""
echo "linuxdeploy Build Helper Container v2.0.1"
echo "https://github.com/andy5995/linuxdeploy-build-helper-container"
echo ""

OLDPWD=$PWD

if [ -z "$HOSTUID" ]; then
  echo "HOSTUID is not set."
  exit 1
fi

if [ -z "$HOSTGID" ]; then
  echo "HOSTGID is not set."
  exit 1
fi

if [ -z "$1" ]; then
  echo "One argument required -- the name of a script to run."
  exit 1
fi

usermod -u "$HOSTUID" builder
chown -R "$HOSTUID:$HOSTGID" /home/builder

# The docs state to use '-w /workdir when running the container, but switching
# to builder here will change the directory. Using cd to change back...
su builder -c "cd $OLDPWD && . ~/.profile && $1"
