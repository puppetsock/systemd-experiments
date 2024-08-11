# Arguments for each base image
ARG TARGET_IMAGE=mcr.microsoft.com/cbl-mariner/base/core:2.0

# Main target image
FROM ${TARGET_IMAGE} AS package-target
COPY ./sources/etc/yum.repos.d/mariner-cloud-native.repo /etc/yum.repos.d/mariner-cloud-native.repo
RUN tdnf distro-sync -y && \
    tdnf install -y cri-tools moby-containerd && \
    tdnf autoremove && \
    tdnf clean all

FROM scratch AS target
COPY --from=package-target /usr/bin/crictl /usr/bin/crictl
COPY --from=package-target /usr/bin/ctr /usr/bin/ctr
COPY ./assets/usr/lib/extension-release.d/extension-release.containerd /usr/lib/extension-release.d/extension-release.containerd