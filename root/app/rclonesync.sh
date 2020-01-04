#!/usr/bin/with-contenv sh

(
    flock -n 200 || exit 1

    first_sync="--first-sync"
    first_sync_semaphore="/tmp/hasSyncd"

    # Semaphore found, meaning this has ran before!
    if [ -f "$first_sync_semaphore" ]; then
        first_sync=""
    fi

    if [ "$SYNC_EXTRA_FLAGS" ]; then
        extra_flags="--rclone-args $SYNC_EXTRA_FLAGS"
    fi
    
    clone_cmd="/app/rclonesync.py $first_sync -c /data $SYNC_DESTINATION: $extra_flags"

    if [ "$CLONE_COMMAND" ]; then
        clone_cmd="$CLONE_COMMAND"
    else
        if [ -z "$SYNC_DESTINATION" ]; then
        echo "Error: SYNC_DESTINATION environment variable was not passed to the container."
        exit 1
        fi
    fi

    echo "Executing => $clone_cmd"
    eval "$clone_cmd"

    echo "Enforcing First Sync Semaphore => $first_sync_semaphore"
    touch $first_sync_semaphore
) 200>/var/lock/rclonesync.lock