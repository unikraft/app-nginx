# Nginx on Unikraft

This application starts an NginX web server.

To configure, build and run the application you need to have [kraft](https://github.com/unikraft/kraft) installed.

To be able to interact with the web server, configure the application to run on the KVM platform:
```
$ kraft configure -p kvm -m x86_64
```

Build the application:
```
$ kraft build
```

We use a virtual bridge to create a connection between the VM and the host system.
We assign address `172.44.0.1/24` to the bridge interface (pointing to the host) and we assign address `172.44.0.2/24` to the virtual machine, by passing boot arguments.
The IP addresses are of our choosing, they can be changed to other values.

We run the commands below to create and assign the IP address to the bridge `virbr0` (once again, our choice of name; any name works):
```
$ sudo brctl addbr virbr0
$ sudo ip a a  172.44.0.1/24 dev virbr0
$ sudo ip l set dev virbr0 up
```

We can check the proper configuration:
```
$ ip a s virbr0
420: virbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 3a:3e:88:e6:a1:e4 brd ff:ff:ff:ff:ff:ff
    inet 172.44.0.1/24 scope global virbr0
       valid_lft forever preferred_lft forever
    inet6 fe80::383e:88ff:fee6:a1e4/64 scope link
       valid_lft forever preferred_lft forever
```

Now we start the virtual machine and pass it the proper arguments to assing the IP address `172.44.0.2/24`:
```
$ kraft run -b virbr0 "netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 --"
[...]
0: Set IPv4 address 172.44.0.2 mask 255.255.255.0 gw 172.44.0.1
en0: Added
en0: Interface is up
[...]
```

The boot message confirms the assigning of the `172.44.0.2/24` IP address to the virtual machine.
We use `wget` to validate it's working properly and we are able to get the `index.html` file:
```
$ wget 172.44.0.2
--2021-08-18 16:47:38--  http://172.44.0.2/
Connecting to 172.44.0.2:80... connected.
HTTP request sent, awaiting response... 200 OK
[...]
2021-08-18 16:47:38 (41.5 MB/s) - ‘index.html’ saved [160]
```

Cleaning up means closing the virtual machine (and the HTTP server) and disabling and deleting the bridge interface:
```
$ sudo ip l set dev virbr0 down
$ sudo brctl delbr virbr0
```

If you want to have more control you can also configure, build and run the application manually.

To configure it for the KVM platform:
```
$ make menuconfig
```

Build the application:
```
$ make
```

Run the application:
```
sudo qemu-system-x86_64 -fsdev local,id=myid,path=$(pwd)/fs0,security_model=none \
                        -device virtio-9p-pci,fsdev=myid,mount_tag=fs0,disable-modern=on,disable-legacy=off \
                        -netdev bridge,id=en0,br=virbr0 \
                        -device virtio-net-pci,netdev=en0 \
                        -kernel "build/app-nginx_kvm-x86_64" \
                        -append "netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 --" \
                        -cpu host \
                        -enable-kvm \
                        -nographic
```


For more information about `kraft` type ```kraft -h``` or read the
[documentation](http://docs.unikraft.org).
