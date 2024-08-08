#FROM azurelinuxpreview.azurecr.io/public/azurelinux/base/core:3.0
FROM mcr.microsoft.com/cbl-mariner/base/core:2.0

SHELL [ "/usr/bin/bash", "-cex" ]

ENV container=docker

STOPSIGNAL SIGRTMIN+3

VOLUME [ "/tmp", "/run", "/run/lock" ]

RUN tdnf distro-sync -y; \
    tdnf install -y \
        ca-certificates \
        dbus \
        iproute \
        procps \
        systemd \
        util-linux \
        vim; \
    tdnf autoremove; \
    tdnf clean all

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