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

for service in kubelet; do
    ./portable-services/build/build-portable-service.sh "portables" "${portabuilder_volume_out}" "${service}"
done
for service in userland containerd kubernetes; do
    ./portable-services/build/build-portable-service.sh "extensions" "${portabuilder_volume_out}" "${service}"
done

./nspawn/build.sh

exit 0
mkdir -p /etc/extensions
for extension in userland containerd kubernetes; do
    unsquashfs -dest /etc/extensions/${extension} /opt/portable-services/extensions/${extension}.raw
done
systemd-sysext refresh


for cmd in $(busybox --list); do [ -z "$(command -v "${cmd}")" ] && ln -s "$(command -v busybox)" "/usr/bin/${cmd}"; done
echo 1 > /proc/sys/net/ipv4/ip_forward

CILIUM_CLI_VERSION=$(wget https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt -O - | cat)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
wget https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

mkdir -p /etc/kubernetes /var/lib/containerd /var/lib/kubelet /opt/cni /etc/cni /usr/libexec/kubernetes/kubelet-plugins/volume/exec/


portable_service_name=userland
unsquashfs -dest /etc/extensions/${portable_service_name} /opt/portable-services/extensions/${portable_service_name}.raw


mkdir -p /etc/extensions
portable_service_name=containerd
unsquashfs -dest /etc/extensions/${portable_service_name} /opt/portable-services/extensions/${portable_service_name}.raw
systemd-sysext refresh

# mkdir -p /opt/portables
# portable_service_name=containerd
# unsquashfs -dest /opt/portables/${portable_service_name} /opt/portable-services/portables/${portable_service_name}.raw
# portablectl attach --profile=trusted /opt/portables/${portable_service_name}
# systemctl start ${portable_service_name}
# systemctl status ${portable_service_name}


mkdir -p /etc/extensions
portable_service_name=kubernetes
unsquashfs -dest /etc/extensions/${portable_service_name} /opt/portable-services/extensions/${portable_service_name}.raw
systemd-sysext refresh

# mkdir -p /opt/portables
# portable_service_name=kubelet
# unsquashfs -dest /opt/portables/${portable_service_name} /opt/portable-services/portables/${portable_service_name}.raw
# portablectl attach --profile=trusted /opt/portables/${portable_service_name}
# systemctl start ${portable_service_name}
systemctl enable --now containerd kubelet
kubeadm init --ignore-preflight-errors=SystemVerification

export KUBECONFIG=/etc/kubernetes/admin.conf
cilium install


containerd_pid="$(nsenter -t 1 --all systemctl show kubelet-containerd --property=MainPID | cut -d'=' -f2)"

/usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.9

nsenter -t 1 --all systemd-run --unit=kubelet-hack nsenter -t "$(nsenter -t 1 --all systemctl show kubelet-containerd --property=MainPID | cut -d'=' -f2)" --no-fork --all /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.9
Running as unit: kubelet-hack.service


