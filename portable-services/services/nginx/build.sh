
docker rm -f portable-service-builder-nginx || true
docker run \
    --tty \
    --detach \
    --restart=no \
    --name "portable-service-builder-nginx" \
    --privileged \
    --security-opt seccomp=unconfined \
    --cgroup-parent=docker.slice \
    --cgroupns private \
    --tmpfs /tmp \
    --tmpfs /run \
    --tmpfs /run/lock \
    --volume /lib/modules:/lib/modules:ro \
    --volume ${PWD}:/opt/src:ro \
    --volume /tmp/portable-services/:/opt/portable-services/:rw \
    --workdir /opt/src \
    "soulard.port.direct/systemd-docker:latest"

until [ "$(docker inspect -f '{{.State.Health.Status}}' "portable-service-builder-nginx")" == 'healthy' ]; do
    sleep 0.1;
done;

docker exec portable-service-builder-nginx docker buildx build . --target final-squashfs --output type=local,dest=/opt/portable-services/

exit 0

#docker exec portable-service-builder-nginx mkdir -p /var/log/nginx /etc/nginx/client_body_temp /etc/nginx/proxy_temp /etc/nginx/fastcgi_temp /etc/nginx/uwsgi_temp /etc/nginx/scgi_temp
docker exec portable-service-builder-nginx portablectl attach --now --profile=trusted /opt/portable-services/nginx.raw
docker exec portable-service-builder-nginx curl http://localhost:80/
docker exec portable-service-builder-nginx portablectl detach --now nginx
#docker stop portable-service-builder-nginx