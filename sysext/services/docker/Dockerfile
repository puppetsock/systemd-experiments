# Arguments for each base image
ARG TARGET_IMAGE=mcr.microsoft.com/cbl-mariner/base/core:2.0

# Main target image
FROM ${TARGET_IMAGE} AS target
COPY ./assets/etc/yum.repos.d/mariner-cloud-native.repo /etc/yum.repos.d/mariner-cloud-native.repo
RUN tdnf distro-sync -y ;\
    tdnf install -y \
        ca-certificates moby-engine ;\
    tdnf autoremove ;\
    tdnf clean all


# Copy assets
COPY ./assets /tmp/assets
RUN cp -rfv /tmp/assets/* / ;\
    rm -rf /tmp/assets
