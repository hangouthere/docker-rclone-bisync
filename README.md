# docker-rclonesync

On the hunt for the desirable "write and forget" flavor of synchronizing, you quickly find out it's not all that easy of a task to accomplish! Lucky for us, someone else already did the hard work!

## Introduction

This project is based on 3 projects, all worthy of fully researching:

* [rclone](https://rclone.org/) - An amazing open-source project responsible for the heavy lifting of transferring files to various cloud storage services. The list is astounding!
* [tynor88/rclone](https://github.com/tynor88/docker-rclone) - A pretty nice and clean (which makes it popular) Docker setup for `rclone`. I suggest spinning up the container, and exec'ing a shell in order to build your config config (and use `headless` when asked!)
* [cjnaz/rclonesync-V2](https://github.com/cjnaz/rclonesync-V2) - This project is responsible for supplying the "write and forget" sync we're after!

## So What is this About?

There wasn't a docker image for `rclonesync`, so I made one!

Mentioned previously, this image fully extends `tynor88/rclone`, which is also completely in-tact. This means you still get the env vars, the internal error checks, and crontab. I feel like users are familiar with this container, and didn't want to shy away from it too much.

The Dockerfile should be pretty straightforward, but essentially we:

* Add `python`, 
* download the `rclonesync` python script, 
* set permissions 
* and create paths as necessary. 

See? BASIC!

The trick to extending the base `dockerfile` was to override the `SYNC_COMMAND` env var to point to our own similar script.

## Features

Out of the box, it's pretty easy to get started!

Simply supply a `SYNC_DESTINATION` env var and mount to the `/data` volume path, and you're golden!

As part of the kickoff cron script, a "First Run" is kept track of by storing a semaphore file at `/tmp/hasSyncd`. The script merely manages the sanity check that's part of `rclonesync` to make sure you don't sync an empty folder to a fully populated remote storage, wiping everything out (yeah... I did that once). To re-run either completely kill the container, or remove the file inside the container.

Also enforced by default is the `check-access` feature. tldr - add an `RCLONE_TEST` file to one of the paths.

Last but not least, in similar fashion of the `tynor88/rclone` image, you can supply a `CLONE_COMMAND` env var to override the default found in `rclonesync.sh`. 

## Example (compose)

```yml
version: "3"

services:
  rclonesyncv2:
    container_name: cloud_sync
    image: nerdfoundry/rclonesync
    restart: always
    environment:
      - PUID=1000                   # UID/GID set to match 
      - PGID=1000                   #  host user for file permissions
      - CRON_SCHEDULE=*/15 * * * *  # Execute on the 15min marks (15/30/45/60)
      - SYNC_DESTINATION=<sync destination from .rclone.conf>
    volumes:
      - ./configs/rclone:/config    # needs to stay a directory since this is the user's home directory
      - /path/to/myGoogleDrive:/data
```