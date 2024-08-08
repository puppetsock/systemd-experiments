# Define the image name and container name
IMAGE_NAME=soulard.port.direct/systemd-container:latest
CONTAINER_NAME=systemd-container

# Default target
all: build

# Target to build the Docker image
build:
	docker build -t $(IMAGE_NAME) .

# Target to run the Docker container
run: build clean
	docker run \
        --tty \
        --detach \
        --restart=no \
        --name "${CONTAINER_NAME}" \
        --privileged \
        --security-opt seccomp=unconfined \
        --cgroup-parent=docker.slice \
        --cgroupns private \
        --tmpfs /tmp \
        --tmpfs /run \
        --tmpfs /run/lock \
        --volume /lib/modules:/lib/modules:ro \
        "${IMAGE_NAME}"

# Target to stop and remove the container if it is running
clean:
	@docker ps -q -a --filter "name=$(CONTAINER_NAME)" | grep -q . && \
	docker rm -f $(CONTAINER_NAME) || \
	echo "Container $(CONTAINER_NAME) is not running."


# Target to remove the Docker image
clean-image:
	docker rmi $(IMAGE_NAME)

.PHONY: all build run clean clean-image
