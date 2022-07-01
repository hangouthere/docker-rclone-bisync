#!/bin/sh

echo "$RCLONE_CRON_SCHEDULE /app/rclone-bisync.sh" >> /etc/crontabs/root

figlet rclone-bisync

echo "Setting up cronjob: $RCLONE_CRON_SCHEDULE"

crond -f
