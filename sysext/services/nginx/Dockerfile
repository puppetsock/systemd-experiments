FROM mcr.microsoft.com/cbl-mariner/base/core:2.0 AS target
SHELL [ "/usr/bin/bash", "-cex" ]
RUN tdnf distro-sync -y; \
    tdnf install -y \
        nginx \
        util-linux \
        tar; \
    tdnf autoremove; \
    tdnf clean all

RUN tar -czvf /opt/nginx_config.tar.gz /etc/nginx

COPY ./assets /tmp/assets
RUN cp -rfv /tmp/assets/* /; \
    rm -rf /tmp/assets; 

RUN mkdir -p /var/log/nginx ;\
    touch /var/log/nginx/error.log
RUN mkdir -p /etc/nginx/client_body_temp /etc/nginx/proxy_temp /etc/nginx/fastcgi_temp /etc/nginx/uwsgi_temp /etc/nginx/scgi_temp