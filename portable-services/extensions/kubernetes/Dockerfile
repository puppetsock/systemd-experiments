# Arguments for each base image
ARG TARGET_IMAGE=mcr.microsoft.com/cbl-mariner/base/core:2.0

# Main target image
FROM ${TARGET_IMAGE} AS package-target
COPY ./sources/etc/yum.repos.d/mariner-cloud-native.repo /etc/yum.repos.d/mariner-cloud-native.repo
RUN tdnf distro-sync -y && \
    tdnf install -y kubectl kubeadm kubelet && \
    tdnf autoremove && \
    tdnf clean all

FROM scratch AS target
COPY --from=package-target /usr/bin/kubectl /usr/bin/kubectl
COPY --from=package-target /usr/bin/kubeadm /usr/bin/kubeadm
COPY --from=package-target /usr/bin/kubelet /usr/bin/kubelet
COPY ./assets/usr/lib/extension-release.d/extension-release.kubernetes /usr/lib/extension-release.d/extension-release.kubernetes
COPY ./assets/usr/lib/systemd/system/kubelet.service /usr/lib/systemd/system/kubelet.service