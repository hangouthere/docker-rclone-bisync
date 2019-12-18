#!/usr/bin/with-contenv sh

(
    flock -n 200 || exit 1

    first_sync="--first-sync"
    first_sync_semaphore="/tmp/hasSyncd"

    # Semaphore found, meaning this has ran before!
    if [ -f "$first_sync_semaphore" ]; then
        first_sync=""
    fi

    touch $first_sync_semaphore
    
    clone_cmd="/app/rclonesync.py /data $SYNC_DESTINATION: -c $first_sync"

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
) 200>/var/lock/rclonesync.lock