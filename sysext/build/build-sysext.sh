#!/bin/bash
set -euf -o pipefail -o errexit -o nounset
script_dir="$(dirname -- "${BASH_SOURCE[0]}")"
script_name="$(basename "${BASH_SOURCE[0]}")"
script_repo_dir="$(git rev-parse --show-toplevel)"
cd "${script_repo_dir}"
echo "Running: ${script_dir}/${script_name} from ${script_repo_dir} as $(whoami) user"
set -x


docker volume create --driver=local "${portabuilder_volume_out}"


portabuilder_host_container_image="soulard.port.direct/systemd-docker:latest"
portabuilder_host_container_name="portabuilder-host"

function destroy_portabuilder_host_container(){
    local portabuilder_host_container_name="${1}"
    if docker container inspect "${portabuilder_host_container_name}" > /dev/null 2>&1; then
        docker rm -f "${portabuilder_host_container_name}"
    fi
    local associated_volumes=$(docker volume ls --filter "label=portabuilder_owner=${portabuilder_host_container_name}" -q)
    if [[ ! -z "${associated_volumes}" ]]; then
        docker volume rm ${associated_volumes}
    fi
}

function ensure_portabuilder_host_container(){
    local portabuilder_host_container_name="${1}"

    local portabuilder_docker_storage="${portabuilder_host_container_name}-var-docker"
    local portabuilder_containerd_storage="${portabuilder_host_container_name}-var-containerd"
    
    docker volume create --driver=local --label="portabuilder_owner=${portabuilder_host_container_name}" "${portabuilder_docker_storage}"
    docker volume create --driver=local --label="portabuilder_owner=${portabuilder_host_container_name}" "${portabuilder_containerd_storage}"

    if docker container inspect "${portabuilder_host_container_name}" > /dev/null 2>&1; then
        if ! [ "$(docker inspect --format '{{.State.Running}}' "${portabuilder_host_container_name}")" == "true" ]; then
            docker start "${portabuilder_host_container_name}"
        fi
    else
        docker run \
            --tty \
            --detach \
            --restart=no \
            --name "${portabuilder_host_container_name}" \
            --privileged \
            --security-opt seccomp=unconfined \
            --cgroup-parent=docker.slice \
            --cgroupns private \
            --tmpfs /tmp \
            --tmpfs /run \
            --tmpfs /run/lock \
            --volume /lib/modules:/lib/modules:ro \
            --volume "${script_repo_dir}:/opt/src:ro" \
            --volume "${portabuilder_volume_out}:/opt/portable-services/:rw" \
            --volume "${portabuilder_docker_storage}:/var/lib/docker/:rw" \
            --volume "${portabuilder_containerd_storage}:/var/lib/containerd/:rw" \
            --workdir /opt/src \
            "${portabuilder_host_container_image}"
    fi
    set +x
    until [ "$(docker inspect -f '{{.State.Health.Status}}' "${portabuilder_host_container_name}")" == 'healthy' ]; do
        sleep 0.1;
    done;
    set -x
}

ensure_portabuilder_host_container "${portabuilder_host_container_name}"

registry="localhost"
portabuilder_image_prefix="portabuilder"
portabuilder_squashfs_tools_image="${portabuilder_image_prefix}-squashfs-tools"
docker exec "${portabuilder_host_container_name}" \
    bash -cex "pushd ./portable-services/build/portabuilder; \
        docker buildx build \
            --file ./Dockerfile.squashfs-tools \
            --tag "${registry}/${portabuilder_squashfs_tools_image}:latest" .; \
        popd"

portable_service_name="$1"
portable_service_image_prefix="portable-service"
portable_service_image="${portable_service_image_prefix}-${portable_service_name}"
docker exec "${portabuilder_host_container_name}" \
    bash -cex "pushd ./portable-services/services/${portable_service_name}; \
        docker buildx build \
            --file ./Dockerfile \
            --tag "${registry}/${portable_service_image}:latest" .; \
        popd"


portabuilder_build_image="${portabuilder_image_prefix}-builder"
docker exec "${portabuilder_host_container_name}" \
    bash -cex "pushd ./portable-services/build/portabuilder; \
        docker buildx build \
            --file ./Dockerfile.portabuilder \
            --build-arg SQUASHFS_TOOLS_IMAGE="${registry}/${portabuilder_squashfs_tools_image}:latest" \
            --build-arg TARGET_IMAGE="${registry}/${portable_service_image}:latest" \
            --build-arg TARGET_SERVICE="${portable_service_name}" \
            --target final-squashfs \
            --output type=local,dest=/opt/portable-services/ .; \
        popd"
