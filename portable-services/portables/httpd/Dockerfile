# Arguments for each base image
ARG TARGET_IMAGE=mcr.microsoft.com/cbl-mariner/base/core:2.0

# Main target image
FROM ${TARGET_IMAGE} AS target
RUN tdnf distro-sync -y && \
    tdnf install -y httpd tar util-linux && \
    tdnf autoremove && \
    tdnf clean all

# Update configuration paths
RUN find /etc/httpd -type f -exec sed -i '/\/httpd\//!s/\/var\/log\//\/var\/log\/httpd\//' {} +
RUN mkdir -p /var/log/httpd

# Backup httpd configuration
RUN tar -czvf /opt/httpd_config.tar.gz /etc/httpd

# Copy assets
COPY ./assets /tmp/assets
RUN cp -rfv /tmp/assets/* / && \
    rm -rf /tmp/assets