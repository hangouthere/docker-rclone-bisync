#!/bin/sh

VERSION=2.0.0

MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized

docker build -t nerdfoundry/rclone-bisync:$VERSION $MY_PATH
docker build -t nerdfoundry/rclone-bisync:latest $MY_PATH