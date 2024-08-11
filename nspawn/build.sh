#!/bin/bash
set -ex
nspawn_container_name="mini-mariner"
nspawn_container_dir="/var/lib/puppet-sock/nspawn"

sudo systemctl stop "${nspawn_container_name}" || true
sudo machinectl stop mini-mariner || true
sudo rm -rf "${nspawn_container_dir}" || true
sudo mkdir -p "${nspawn_container_dir}"

sudo docker build -t builder -f Dockerfile.mariner --target final --output type=local,dest=${nspawn_container_dir}/ .
sudo chmod 755 ${nspawn_container_dir}


for interface in $(ip -j route show default | jq -r '.[].dev'); do
    sudo iptables -A FORWARD -i ve-+ -o "${interface}" -j ACCEPT
    sudo iptables -A FORWARD -i "${interface}" -o ve-+ -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -t nat -A POSTROUTING -o "${interface}" -j MASQUERADE
done

portable_services_location="$(docker volume inspect --format '{{ .Mountpoint }}' portabuilder-out)"
#sudo systemd-run --unit="${nspawn_container_name}" \
    sudo systemd-nspawn \
        --machine="${nspawn_container_name}" \
        --bind-ro="${portable_services_location}:/opt/portable-services/" \
        --bind="/dev/kmsg:/dev/kmsg" \
        --system-call-filter='add_key bpf keyctl @mount @privileged' \
        --network-veth \
        -b \
        -D "${nspawn_container_dir}"


exit 0

# sudo rm -rf $(pwd)/chroot-arch
# sudo docker build -t builder -f Dockerfile.arch .
# sudo docker run --rm --privileged -v $(pwd)/chroot-arch:/chroot builder pacstrap -K -c /chroot base

# set +x
# sudo find ./chroot-arch -type d | while read -r arch_dir; do
#     # Construct the equivalent mariner directory path
#     mariner_dir="./chroot-mariner${arch_dir#./chroot-arch}"

#     # Check if the directory exists in ./chroot-mariner
#     if [ -d "$mariner_dir" ]; then
#         # Get the permissions of the arch directory
#         arch_perms=$(sudo stat --format='%a' "$arch_dir")

#         # Get the permissions of the mariner directory
#         mariner_perms=$(sudo stat --format='%a' "$mariner_dir")

#         # Update the permissions only if they are different
#         if [ "$arch_perms" != "$mariner_perms" ]; then
#             sudo chmod "$arch_perms" "$mariner_dir"
#             echo "Updated permissions of $mariner_dir to $arch_perms"
#         fi
#     fi
# done

for interface in $(ip -j route show default | jq -r '.[].dev'); do
    sudo iptables -A FORWARD -i ve-+ -o "${interface}" -j ACCEPT
    sudo iptables -A FORWARD -i "${interface}" -o ve-+ -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -t nat -A POSTROUTING -o "${interface}" -j MASQUERADE
done

portable_services_location="$(docker volume inspect --format '{{ .Mountpoint }}' portabuilder-out)"
sudo systemd-run --unit=mini-mariner systemd-nspawn --machine=mini-mariner --system-call-filter='add_key bpf keyctl' --bind-ro=${portable_services_location}:/opt/portable --no-pager --network-veth  -b -D $(pwd)/mini-mariner

sudo machinectl shell mini-mariner /usr/bin/bash -c "ls /"
sudo machinectl stop mini-mariner


for portable_service_name in containerd kubelet docker; do
    sudo machinectl shell mini-mariner /usr/bin/bash -c "mkdir -p /opt/extracted-portable-services /var/lib/docker /etc/kubernetes /var/lib/kube-proxy"
    sudo machinectl shell mini-mariner /usr/bin/bash -c "unsquashfs -dest /opt/extracted-portable-services/${portable_service_name} /opt/portable-services/${portable_service_name}.raw"
    sudo machinectl shell mini-mariner /usr/bin/bash -c "portablectl attach --now --profile=trusted \"/opt/extracted-portable-services/${portable_service_name}\""
done

 export RELEASE="$(wget https://dl.k8s.io/release/stable.txt -O - | cat)"; export ARCH="amd64" ;\
    wget https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubectl} ;\
    chmod +x {kubeadm,kubectl} ;\
    mv {kubeadm,kubectl} /usr/local/bin/
kubeadm init --ignore-preflight-errors=Service-Kubelet,FileExisting-crictl,FileExisting-conntrack,FileExisting-iptables,SystemVerification,KubeletVersion,FileContent--proc-sys-net-ipv4-ip_forward,Port-10250
