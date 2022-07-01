#!/bin/sh

(
    flock -n 200 || exit 1

    first_resync="--resync"
    first_resync_semaphore="/tmp/hasReSyncd"

    # Semaphore found, meaning this has ran before!
    if [ -f "$first_resync_semaphore" ]; then
        first_resync=""
    fi

    rclone_flags="-c $RCLONE_EXTRA_FLAGS"
    extra_flags="$first_resync --check-access $RCLONE_BISYNC_EXTRA_FLAGS"
    
    clone_cmd="rclone $rclone_flags bisync /data $RCLONE_SYNC_LABEL: $extra_flags"

    if [ "$RCLONE_COMMAND" ]; then
        clone_cmd="$RCLONE_COMMAND"
    else
        if [ -z "$RCLONE_SYNC_LABEL" ]; then
            echo "Error: RCLONE_SYNC_LABEL environment variable was not passed to the container."
            exit 1
        fi
    fi

    figlet -w 120 Sync: $RCLONE_SYNC_LABEL

    echo "Executing => $clone_cmd"
    eval "$clone_cmd"

    echo "Enforcing First ReSync Semaphore => $first_resync_semaphore"
    touch $first_resync_semaphore
) 200>/var/lock/rclonesync.lock