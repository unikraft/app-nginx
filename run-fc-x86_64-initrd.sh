#!/bin/bash

cd fs0
find -depth -print | tac | bsdcpio -o --format newc > ../fs0.cpio
cd ..

sudo ip link set dev tap0 down 2> /dev/null
sudo ip link del dev tap0 2> /dev/null
sudo ip tuntap add dev tap0 mode tap
sudo ip address add 172.44.0.1/24 dev tap0
sudo ip link set dev tap0 up

> /tmp/firecracker.log
rm /tmp/firecracker.socket
firecracker-x86_64 \
    --api-sock /tmp/firecracker.socket \
    --config-file nginx-fc-x86_64-initrd.json
