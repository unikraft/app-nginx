#!/bin/sh

kernel_image="build/nginx_qemu-x86_64"

if test $# -eq 1; then
    kernel_image="$1"
fi

cd fs0
find -depth -print | tac | bsdcpio -o --format newc > ../fs0.cpio
cd ..

sudo ip link set dev virbr0 down 2> /dev/null
sudo ip link del dev virbr0 2> /dev/null
sudo ip link add dev virbr0 type bridge
sudo ip address add 172.44.0.1/24 dev virbr0
sudo ip link set dev virbr0 up

sudo qemu-system-x86_64 \
    -kernel "$kernel_image" -nographic \
    -netdev bridge,id=en0,br=virbr0 -device virtio-net-pci,netdev=en0 \
    -append "netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 --" \
    -initrd fs0.cpio
