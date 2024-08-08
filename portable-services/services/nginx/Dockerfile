FROM mcr.microsoft.com/cbl-mariner/base/core:2.0 AS squashfs-tools
SHELL [ "/usr/bin/bash", "-cex" ]
RUN tdnf distro-sync -y; \
    tdnf install -y \
        squashfs-tools; \
    tdnf autoremove; \
    tdnf clean all

FROM mcr.microsoft.com/cbl-mariner/base/core:2.0 AS target
SHELL [ "/usr/bin/bash", "-cex" ]
RUN tdnf distro-sync -y; \
    tdnf install -y \
        nginx; \
    tdnf autoremove; \
    tdnf clean all


RUN tdnf distro-sync -y; \
    tdnf install -y \
        tar; \
    tdnf autoremove; \
    tdnf clean all

RUN tar -czvf /opt/nginx_config.tar.gz /etc/nginx

RUN tdnf distro-sync -y; \
    tdnf install -y \
        iproute \
        procps \
        util-linux \
        vim; \
    tdnf autoremove; \
    tdnf clean all


COPY ./assets /tmp/assets

RUN cp -rfv /tmp/assets/* /; \
    rm -rf /tmp/assets; 

RUN mkdir -p /var/log/nginx ;\
    touch /var/log/nginx/error.log
RUN mkdir -p /etc/nginx/client_body_temp /etc/nginx/proxy_temp /etc/nginx/fastcgi_temp /etc/nginx/uwsgi_temp /etc/nginx/scgi_temp

FROM squashfs-tools AS squashfs-builder
COPY --from=target / /rootfs
RUN pushd /rootfs ;\
    mkdir -p ./proc/ ./sys/ ./dev/ ./run/ ./tmp/ ./var/tmp/ ./etc/ ;\
    touch ./etc/resolv.conf ./etc/machine-id
WORKDIR /out
RUN mksquashfs /rootfs nginx.raw

FROM scratch AS final-squashfs
COPY --from=squashfs-builder /out /