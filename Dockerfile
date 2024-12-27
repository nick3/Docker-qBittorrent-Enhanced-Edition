FROM lsiobase/alpine:3.20 AS builder
LABEL maintainer="SuperNG6"

WORKDIR /qbittorrent

COPY install.sh /qbittorrent/
COPY ReleaseTag /qbittorrent/

RUN apk add --no-cache ca-certificates curl jq

RUN cd /qbittorrent \
	&& chmod a+x install.sh \
	&& bash install.sh

FROM golang:1.23-alpine AS gobuilder

RUN apk add --no-cache ca-certificates make git && \
    apk add --no-cache tzdata

WORKDIR /build

ENV GO111MODULE=on
ENV GOPROXY=https://goproxy.cn,direct

RUN git clone https://github.com/nick3/update_ipv6_addresses_to_ros.git

# Build the binary
RUN cd update_ipv6_addresses_to_ros && go build -o update_ipv6_addresses_to_ros

# docker qBittorrent-Enhanced-Edition

FROM lsiobase/alpine:3.20

# environment settings
ENV TZ=Asia/Shanghai
ENV WEBUIPORT=8080

# add local files and install qbitorrent
COPY root /
COPY --from=builder /qbittorrent/qbittorrent-nox /usr/local/bin/qbittorrent-nox
COPY --from=gobuilder /build/update_ipv6_addresses_to_ros/update_ipv6_addresses_to_ros /usr/local/bin/update-ipv6-ros

RUN chmod a+x /usr/local/bin/update-ipv6-ros \
    && chmod a+x /etc/s6-overlay/s6-rc.d/crond/run \
    && chmod a+x /etc/s6-overlay/scripts/startuir.sh \
    && chmod a+x /etc/s6-overlay/scripts/setup_ipv6_route.sh

# install python3 and cron
RUN apk add --no-cache python3 \
    && rm -rf /var/cache/apk/* \
    && chmod a+x /usr/local/bin/qbittorrent-nox

RUN /etc/s6-overlay/scripts/setup_ipv6_route.sh

RUN echo "*/5 * * * * /etc/s6-overlay/scripts/startuir.sh" >> /etc/crontabs/root

# ports and volumes
VOLUME /downloads /config
EXPOSE 8080 6881 6881/udp
