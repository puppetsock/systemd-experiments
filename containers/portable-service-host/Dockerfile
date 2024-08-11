FROM soulard.port.direct/systemd-container:latest

SHELL [ "/usr/bin/bash", "-cex" ]

RUN tdnf install -y \
        squashfs-tools \
        moby-cli \
        cri-tools

RUN export RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"; export ARCH="amd64" ;\
    curl -L --remote-name-all https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubectl} ;\
    chmod +x {kubeadm,kubectl} ;\
    mv {kubeadm,kubectl} /usr/local/bin/

COPY ./assets /tmp/assets

RUN cp -rfv /tmp/assets/* /; \
    rm -rf /tmp/assets; 

VOLUME ["/usr","/opt","/var","/mnt","/media","/home","/boot","/root","/etc"]