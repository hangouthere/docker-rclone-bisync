FROM tynor88/rclone:1.48.0

MAINTAINER nfgCodex <nfg.codex@outlook.com>

ARG URL_RCLONESYNC="https://raw.githubusercontent.com/cjnaz/rclonesync-V2/master/rclonesync.py"

COPY root/ /

# Add Python, grab rclonesync-v2, and general setup for rcs
RUN apk add --update \
    ca-certificates \
    python \
    wget \
  && mkdir -p /config/scripts /config/.rclonesyncwd \
  && wget ${URL_RCLONESYNC} -O /app/rclonesync.py \
  && chmod +x /app/rclonesync.py \
  && chmod +x /app/rclonesync.sh \
  && rm -rf /var/cache/apk/*

ENV SYNC_COMMAND /app/rclonesync.sh
