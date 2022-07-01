FROM rclone/rclone:1.58.1

MAINTAINER nfgCodex <nfg.codex@outlook.com>

COPY ./root/ /

ENV RCLONE_CRON_SCHEDULE */15 * * * *

RUN apk add --no-cache \
    figlet \
  && chmod +x /app/*.sh 

ENTRYPOINT ["/app/entrypoint.sh"]