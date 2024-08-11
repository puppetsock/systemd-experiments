#FROM azurelinuxpreview.azurecr.io/public/azurelinux/base/core:3.0
FROM docker.io/library/ubuntu:24.04

SHELL [ "/usr/bin/bash", "-cex" ]

ENV container=docker

STOPSIGNAL SIGRTMIN+3

VOLUME [ "/tmp", "/run", "/run/lock" ]

RUN apt-get update -y; \
    apt-get install -y \
        ca-certificates \
        dbus \
        iproute2 \
        procps \
        systemd \
        util-linux \
        vim \
        kmod

RUN find /lib/systemd/system/sysinit.target.wants/ -name "systemd-tmpfiles-setup.service" -delete; \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;

COPY ./assets /tmp/assets

RUN cp -rfv /tmp/assets/* /; \
    rm -rf /tmp/assets; 

# Entrypoint: Use systemd as the entry point for the container.
ENTRYPOINT [ "/usr/local/bin/systemd-container-init" ]

HEALTHCHECK --interval=10s --timeout=30s --start-period=30s --retries=3 \
    CMD systemctl is-system-running --quiet && (systemctl --failed --quiet || exit 1)