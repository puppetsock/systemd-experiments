# Arguments for each base image
ARG TARGET_IMAGE=mcr.microsoft.com/cbl-mariner/base/core:2.0

FROM ${TARGET_IMAGE} AS builder
SHELL [ "/usr/bin/bash", "-cex" ]
RUN tdnf distro-sync -y; \
    tdnf install -y \
        dnf \
        dnf-plugins-core; \
    tdnf autoremove; \
    tdnf clean all

# Main target image
FROM builder AS package-target
COPY ./sources/etc/yum.repos.d/mariner-cloud-native.repo /etc/yum.repos.d/mariner-cloud-native.repo
RUN dnf distro-sync -y && \
    dnf --installroot=/chroot --releasever=2.0 --setopt=install_weak_deps=False install -y iptables && \
    dnf autoremove && \
    dnf clean all

RUN dnf distro-sync -y && \
    dnf --installroot=/chroot --releasever=2.0 --setopt=install_weak_deps=False install -y ebtables ethtool socat conntrack-tools && \
    dnf autoremove && \
    dnf clean all

# Copy assets
COPY ./assets /tmp/assets
RUN cp -rfv /tmp/assets/* /chroot/ && \
    rm -rf /tmp/assets

FROM scratch AS target
COPY --from=package-target /chroot /
