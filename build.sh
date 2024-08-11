#!/bin/bash
set -euf -o pipefail -o errexit -o nounset
script_dir="$(dirname -- "${BASH_SOURCE[0]}")"
script_name="$(basename "${BASH_SOURCE[0]}")"
script_repo_dir="$(git rev-parse --show-toplevel)"
cd "${script_repo_dir}"
echo "Running: ${script_dir}/${script_name} from ${script_repo_dir} as $(whoami) user"
set -x

sudo machinectl stop mini-mariner || true

portabuilder_volume_out="portabuilder-out"

for service in kubelet containerd; do
    ./portable-services/build/build-portable-service.sh "portables" "${portabuilder_volume_out}" "${service}"
done
for service in containerd kubernetes; do
    ./portable-services/build/build-portable-service.sh "extensions" "${portabuilder_volume_out}" "${service}"
done

./nspawn/build.sh

exit 0


for cmd in $(busybox --list); do [ -z "$(command -v "${cmd}")" ] && ln -s "$(command -v busybox)" "/usr/bin/${cmd}"; done
echo 1 > /proc/sys/net/ipv4/ip_forward

mkdir -p /etc/kubernetes /var/lib/containerd /var/lib/kubelet /run/secrets
mkdir -p /etc/extensions
portable_service_name=containerd
unsquashfs -dest /etc/extensions/${portable_service_name} /opt/portable-services/extensions/${portable_service_name}.raw
systemd-sysext refresh

mkdir -p /opt/portables
portable_service_name=containerd
unsquashfs -dest /opt/portables/${portable_service_name} /opt/portable-services/portables/${portable_service_name}.raw
portablectl attach --profile=trusted /opt/portables/${portable_service_name}
systemctl start ${portable_service_name}
systemctl status ${portable_service_name}


mkdir -p /etc/extensions
portable_service_name=kubernetes
unsquashfs -dest /etc/extensions/${portable_service_name} /opt/portable-services/extensions/${portable_service_name}.raw
systemd-sysext refresh

mkdir -p /opt/portables
portable_service_name=kubelet
unsquashfs -dest /opt/portables/${portable_service_name} /opt/portable-services/portables/${portable_service_name}.raw
portablectl attach --profile=trusted /opt/portables/${portable_service_name}
systemctl start ${portable_service_name}

kubeadm init --ignore-preflight-errors=Service-Kubelet,SystemVerification,FileExisting-conntrack,FileExisting-iptables,KubeletVersion