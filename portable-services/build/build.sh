#!/bin/bash
set -euf -o pipefail -o errexit -o nounset
script_dir="$(dirname -- "${BASH_SOURCE[0]}")"
script_name="$(basename "${BASH_SOURCE[0]}")"
script_repo_dir="$(git rev-parse --show-toplevel)"
cd "${script_repo_dir}"
echo "Running: ${script_dir}/${script_name} from ${script_repo_dir} as $(whoami) user"
set -x

portabuilder_volume_out="portabuilder-out"

for service in containerd kubelet docker; do
    ./portable-services/build/build-portable-service.sh "portables" "${portabuilder_volume_out}" "${service}"
done

# docker volume inspect --format '{{ .Mountpoint }}' portabuilder-out

portabuilder_host_validation_container_image="soulard.port.direct/systemd-portable-service-host:latest"
portabuilder_host_validation_container_name_prefix="portabuilder-validation-host"
function ensure_portabuilder_validaton_host_container(){
    local portabuilder_host_validation_container_name="${1}"
    docker rm -f "${portabuilder_host_validation_container_name}" || true
    	docker run \
        --tty \
        --detach \
        --restart=no \
        --name "${portabuilder_host_validation_container_name}" \
        --privileged \
        --security-opt seccomp=unconfined \
        --cgroup-parent=docker.slice \
        --cgroupns private \
        --tmpfs /tmp \
        --tmpfs /run \
        --tmpfs /run/lock \
        --volume /lib/modules:/lib/modules:ro \
        --volume "${portabuilder_volume_out}:/opt/portable-services/:ro" \
        "${portabuilder_host_validation_container_image}"
    set +x
    until [ "$(docker inspect -f '{{.State.Health.Status}}' "${portabuilder_host_validation_container_name}")" == 'healthy' ]; do
        sleep 1s;
    done;
    set -x
}


portabuilder_host_validation_container_name="${portabuilder_host_validation_container_name_prefix}-foo"
ensure_portabuilder_validaton_host_container "${portabuilder_host_validation_container_name}"

for portable_service_name in containerd kubelet docker; do
    docker exec "${portabuilder_host_validation_container_name}" \
        mkdir -p /opt/extracted-portable-services/ /var/lib/docker /etc/kubernetes
    docker exec "${portabuilder_host_validation_container_name}" \
        unsquashfs -dest /opt/extracted-portable-services/${portable_service_name} /opt/portable-services/portables/${portable_service_name}.raw
    docker exec "${portabuilder_host_validation_container_name}" \
        portablectl attach --now --profile=trusted "/opt/extracted-portable-services/${portable_service_name}"
    # docker exec "${portabuilder_host_validation_container_name}" \
    #     curl http://localhost:80/
    # docker exec "${portabuilder_host_validation_container_name}" \
    #     portablectl detach --now "${portable_service_name}"
done