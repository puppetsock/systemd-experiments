# Arguments for each base image
ARG TARGET_IMAGE=mcr.microsoft.com/cbl-mariner/base/core:2.0

# Main target image
FROM ${TARGET_IMAGE} AS package-target
COPY ./assets/etc/yum.repos.d/mariner-cloud-native.repo /etc/yum.repos.d/mariner-cloud-native.repo
RUN tdnf distro-sync -y && \
    tdnf install -y kubelet kubeadm && \
    tdnf autoremove && \
    tdnf clean all

FROM ${TARGET_IMAGE} AS target
COPY --from=package-target /usr/bin/kubelet /usr/bin/kubelet
COPY --from=package-target /usr/bin/kubeadm /usr/bin/kubeadm
RUN tdnf distro-sync -y && \
    tdnf install -y util-linux && \
    tdnf autoremove && \
    tdnf clean all

# Copy assets
COPY ./assets /tmp/assets
RUN cp -rfv /tmp/assets/* / && \
    rm -rf /tmp/assets

RUN mkdir -p /var/lib/kubelet
# docker run -it --rm -v /run/containerd:/run/containerd:rw -v /dev:/dev -v /sys/fs/cgroup:/sys/fs/cgroup:rw --privileged --pid=host --ipc=host --net=host 1ce44aa8adc3 kubelet --fail-swap-on=false