#!/bin/sh

VERSION=1.0.3

MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized

docker build -t nerdfoundry/rclonesync:$VERSION $MY_PATH
docker build -t nerdfoundry/rclonesync:latest $MY_PATH