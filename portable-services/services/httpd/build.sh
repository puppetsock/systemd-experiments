
docker rm -f portable-service-builder-httpd || true
docker run \
    --tty \
    --detach \
    --restart=no \
    --name "portable-service-builder-httpd" \
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

until [ "$(docker inspect -f '{{.State.Health.Status}}' "portable-service-builder-httpd")" == 'healthy' ]; do
    sleep 0.1;
done;

docker exec portable-service-builder-httpd docker buildx build --tag localhost/httpd:latest .

docker exec portable-service-builder-httpd docker buildx build --file Dockerfile.portabuilder --build-arg TARGET_IMAGE=localhost/httpd:latest --target final-squashfs --output type=local,dest=/opt/portable-services/ .

docker exec portable-service-builder-httpd portablectl attach --now --profile=trusted /opt/portable-services/httpd.raw
docker exec portable-service-builder-httpd curl http://localhost:80/
docker exec portable-service-builder-httpd portablectl detach --now httpd
#docker stop portable-service-builder-httpd