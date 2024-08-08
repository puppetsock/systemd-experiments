# Define the image name and container name
IMAGE_NAME=soulard.port.direct/systemd-container:latest
CONTAINER_NAME=systemd-container

# Default target
all: build

# Target to build the Docker image

clean-buildenv:
	@docker ps -q -a --filter "name=portable-service-builder-nginx" | grep -q . && \
        docker rm -f "portable-service-builder-nginx" || \
        echo "Container portable-service-builder-nginx is not present."

build-env: clean-buildenv
	@docker run \
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
	@echo "Waiting for container to become healthy..."
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' "portable-service-builder-nginx")" = "healthy" ]; do \
		sleep 1; \
	done;

build:
	docker exec portable-service-builder-nginx docker buildx build . --target final-squashfs --output type=local,dest=/opt/portable-services/

# Target to run the Docker container
run:
	@docker exec portable-service-builder-nginx mkdir -p /var/log/nginx /etc/nginx/client_body_temp /etc/nginx/proxy_temp /etc/nginx/fastcgi_temp /etc/nginx/uwsgi_temp /etc/nginx/scgi_temp
	@docker exec portable-service-builder-nginx portablectl attach --now --profile=trusted /opt/portable-services/nginx.raw
	@docker exec portable-service-builder-nginx curl http://localhost:80/
	@docker exec portable-service-builder-nginx portablectl detach --now nginx

# Target to stop and remove the container if it is running
clean:
	@docker ps -q -a --filter "name=$(CONTAINER_NAME)" | grep -q . && \
	docker rm -f $(CONTAINER_NAME) || \
	echo "Container $(CONTAINER_NAME) is not running."


# Target to remove the Docker image
clean-image:
	docker rmi $(IMAGE_NAME)

.PHONY: all clean-buildenv build-env build run clean clean-image
