FROM soulard.port.direct/systemd-container:latest

RUN tdnf install -y \
        git \
        moby-containerd \
        moby-cli \
        moby-engine ;\
    mkdir -p /usr/local/libexec/docker/cli-plugins ;\
    curl -o /usr/local/libexec/docker/cli-plugins/docker-buildx -sSL https://github.com/docker/buildx/releases/download/v0.16.2/buildx-v0.16.2.linux-amd64 ;\
    chmod +x /usr/local/libexec/docker/cli-plugins/docker-buildx ;\
    docker buildx install ;\
    systemctl enable docker.service ;\
    systemctl disable auditd.service iptables.service

COPY ./assets /tmp/assets

RUN cp -rfv /tmp/assets/* /; \
    rm -rf /tmp/assets; 

VOLUME ["/var/lib/docker","/var/lib/containerd"]

# Health check to verify Docker daemon is running
HEALTHCHECK --interval=10s --timeout=30s --start-period=30s --retries=3 \
    CMD docker info || exit 1