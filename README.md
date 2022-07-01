[![Source](https://badgen.net/badge/icon/Source?icon=github&label)](https://github.com/nerdfoundry/docker-rclone-bisync)
[![Discord](https://badgen.net/badge/icon/Join%20our%20Discord?icon=discord&label)](https://url.nfgarmy.com/discord)
[![Twitch](https://badgen.net/badge/Built%20Live/on%20Twitch/9146FF)](https://twitch.tv/nfgCodex)

[![rclone](https://badgen.net/badge/Upstream/rclone/a51f17)](https://hub.docker.com/r/rclone/rclone)

[![docker](https://badgen.net/badge/icon/Runs%20in%20Docker/0db7ed?icon=docker&label)](https://www.docker.com)

# docker-rclone-bisync

> This project now replaces `docker-rclonesync` now that `rclone` supports `bisync` natively!

This Docker image and environment is tailored to operating under the `bisync` [user flow](https://rclone.org/bisync/) of `rclone`. That is to say, it's meant to get you up and running for `bisync` as fast as possible!

## Introduction

This project is based on the `rclone` upstream project, and worthy of fully [researching the docs](https://rclone.org/docs/).

### Features

If you have an existing config, it's pretty easy to get started out of the box!

Simply supply a `RCLONE_SYNC_LABEL` env var and mount to the `/data` volume path, and you're golden! (Don't worry, details are below!)

This project is basically a cronjob that also tracks a "First Run" semaphore as a file existing at `/tmp/hasReSyncd`. The script merely manages the initial `resync`/sanity check that's part of `rclone bisync` user flow, as well as some other defaults, including the [`check-access` feature](https://rclone.org/commands/rclone_bisync/) (add an `RCLONE_TEST` file to one of the paths), and verbose enabled by default. 

If an error instructs you to, re-run the initial resyncing by either completely remove the container or remove the file inside the container.

Here are all the environment variables to augment the defaults:
* `RCLONE_SYNC_LABEL` (Required) supplies the config label to target for the container
* `RCLONE_EXTRA_FLAGS` to add flags to `rclone` directly (ie: `rclone *flagsHere* bisync`). 
* `RCLONE_BISYNC_EXTRA_FLAGS` to add flags to `rclone bisync` (ie: `rclone bisync *flagsHere*`).
* `RCLONE_CRON_SCHEDULE` defaults to a 15 minute schedule, but can be override to your liking
* `RCLONE_COMMAND` can be supplied to override the entire default found in `rclone-bisync.sh`. 

### Example (docker-compose)

```yml
version: "3"

services:
  rclone-bisync:
    container_name: cloud_sync
    image: nerdfoundry/rclone-bisync
    restart: always
    environment:
      - RCLONE_SYNC_LABEL=<config entry label from .rclone.conf>
      - RCLONE_EXTRA_FLAGS=--drive-skip-gdocs #Add RClone flags to default command easily
      # - RCLONE_BISYNC_EXTRA_FLAGS=--remove-empty-dirs
    volumes:
      - ./volumes/rclone:/config    # needs to stay a directory since this is the user's home directory
      - /path/to/myGoogleDriveData:/data
```

### Example (more complex docker-compose)

> This uses the newer [Extension Fields](https://docs.docker.com/compose/compose-file/compose-file-v3/#extension-fields) to reduce boilerplate and repitition.

```yml
x-rclone-bisync: &rclone-bisync
  image: nerdfoundry/rclone-bisync
  restart: unless-stopped
  env_file:
    - .env/.env
    - .env/.env-cloud

services:
  sync_gdrive:
    <<: *rclone-bisync
    container_name: sync_gdrive
    environment:
      - RCLONE_SYNC_LABEL=GDrive_myAccountName
    volumes:
      - ../volumes/rclone:/config # Shared config volume - needs to stay a directory
      - ../../cloud-sync/GDrive_myAccountName:/data

  sync_dropbox:
    <<: *rclone-bisync
    container_name: sync_dropbox
    environment:
      - RCLONE_SYNC_LABEL=Dropbox_myAccountname
    volumes:
      - ../volumes/rclone:/config # Shared config volume - needs to stay a directory
      - ../../cloud-sync/Dropbox_myAccountname:/data
```

## Initial Setup

The intended way to run this image is that every cloud instance has it's own volume, and config (although the config can be shared if desired). That means if you have 3 configs you want to keep in `bisync`, then you will end up having 3 container definitions.

In this case, I suggest a `.env` config that defines the `RCLONE_EXTRA_FLAGS`/`RCLONE_BISYNC_EXTRA_FLAGS` that are common to all containers, and simply supply `RCLONE_SYNC_LABEL` per defintion.

### Setting up config(s)

> I'll be assuming a "from scratch" setup, as well as exampling Google Drive since that's what I use. The [official documentation](https://rclone.org/docs/) will have more explicit information on both how to configure, as well as [platform-specific options](https://rclone.org/drive/#standard-options), so be sure to also check them out.

First, we'll modify our `docker-compose.yml` file to do the following:
* Enter a "noop mode" by tailing null
* Supply a "Sync Label Name" via env var
* Port forward for headless configuration (this may vary based on your platform, so you may have to restart the process after you correct this)

```yml
services:
  rclone-bisync:
    container_name: cloud_sync_GDrive_accountName # Customize as needed
    -- ...
    entrypoint: tail -f /dev/null
    environment:
      - RCLONE_SYNC_LABEL=GDrive_accountName # Customize as needed
    ports:
      - 53682:53682
```

> Note: The entirety of `GDrive_accountName` is made up, I just prefix the account name with `GDrive_` to indicate the underlying cloud platform, and allow for same names across platforms with different files.

In one terminal, bring up the container to `noop`:

```sh
docker-compose up
```

Now in another terminal, we can exec into the container and create our Config:

```sh
docker exec -it cloud_sync_GDrive_accountName rclone config
```

* You'll be presented with a message indicating a new config is being defaulted, and you can create a `New` config using the same text as `RCLONE_SYNC_LABEL`.
* I'll use `drive` as my platform, choose accordingly!
* Following the [Official Documentation](https://rclone.org/drive/#making-your-own-client-id), we can set up our own "dev account" for a client id/secret to avoid [HTTP 429](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/429) errors and actually sync our files.
  * Note that the first few times you sync, you may hit your own limits even still across all your accounts, so give it time and it should work itself out as quotas are reset and sync'ing resumes.
* I want `rclone` to have full access so I'll use #1, or `drive` to give full drive access.
* `root_folder_id` is the name of the top level path you want to sync: I leave it empty to grab everything!
* `service_account_file` I leave empty because I use the OAuth2 flow
* **THIS STEP IS IMPORTANT** - Contrary to belief, you want to *NOT* go into the Advanced Configuration for now
* **THIS STEP IS IMPORTANT** - Because we're working in Docker, we want to choose the `Headless` option to provide a link we can put into our browser to authenticate as.
  * This should authenticate as the owner of the Cloud Platform account, not the "dev account" used earlier.
* Once Authenticated, you can simply paste the generated token back into `rclone` and finish the configuration and save it.

> At the time of this writing, I had to actually target the Official `1.57.0` Docker Image due to broken changes in `1.58.0` within a Docker Container. Once authenticated with my Google dev app, I'm able to go back to the image created in this repo.
>
>```sh
>docker run --rm -it -v $(pwd)/../volumes/rclone:/config -v $(pwd)/../../cloud-sync/GDrive_myAccountName rclone/rclone:1.57.0 config
>```
>
> Alternatively, you can use the `service_account_file` to avoid OAuth2 flow. You can find more information [here](https://rclone.org/drive/#service-account-support).

At this point, it should operate as expected on the crontab schedule, but let's kick things off to make sure everything's ok:

```sh
docker exec -it cloud_sync_GDrive_accountName ash

# once in the container...

/app/rclone-bisync.sh

# It might take a while, but the first run will force a resync your Cloud -> Local
```

> To avoid any accidental deletion, you can supply `--dry-run`

```sh
RCLONE_BISYNC_EXTRA_FLAGS="$RCLONE_BISYNC_EXTRA_FLAGS --dry-run" /app/rclone-bisync.sh
```

And further executions will no longer resync until forced, or if the container is fully removed and recreated.