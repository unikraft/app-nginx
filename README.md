# Nginx on Unikraft

This application starts an Nginx web server with Unikraft.
Follow the instructions below to set up, configure, build and run Nginx.

## Quick Setup (aka TLDR)

For a quick setup, run the commands below.
Note that you still need to install the [requirements](#requirements).

For building and running everything for `x86_64`, follow the steps below:

```console
git clone https://github.com/unikraft/app-nginx nginx
cd nginx/
mkdir .unikraft
git clone https://github.com/unikraft/unikraft .unikraft/unikraft
git clone https://github.com/unikraft/lib-nginx .unikraft/libs/nginx
git clone https://github.com/unikraft/lib-musl .unikraft/libs/musl
git clone https://github.com/unikraft/lib-lwip .unikraft/libs/lwip
UK_DEFCONFIG=$(pwd)/.config.nginx_qemu-x86_64 make defconfig
make -j $(nproc)
./run-qemu-x86_64.sh
```

This will configure, build and run the `nginx` server.
You can see how to test it in the [running section](#run).

The same can be done for `AArch64`, by running the commands below:

```console
make properclean
UK_DEFCONFIG=$(pwd)/.config.nginx_qemu-arm64 make defconfig
make -j $(nproc)
./run-qemu-aarch64.sh
```

Similar to the `x86_64` build, this will start the `nginx` server.
Information about every step is detailed below.

## Requirements

In order to set up, configure, build and run Nginx on Unikraft, the following packages are required:

* `build-essential` / `base-devel` / `@development-tools` (the meta-package that includes `make`, `gcc` and other development-related packages)
* `sudo`
* `flex`
* `bison`
* `git`
* `wget`
* `uuid-runtime`
* `qemu-system-x86`
* `qemu-system-arm`
* `qemu-kvm`
* `sgabios`
* `gcc-aarch64-linux-gnu`

GCC >= 8 is required to build Nginx on Unikraft.

On Ubuntu/Debian or other `apt`-based distributions, run the following command to install the requirements:

```console
sudo apt install -y --no-install-recommends \
  build-essential \
  sudo \
  gcc-aarch64-linux-gnu \
  libncurses-dev \
  libyaml-dev \
  flex \
  bison \
  git \
  wget \
  uuid-runtime \
  qemu-kvm \
  qemu-system-x86 \
  qemu-system-arm \
  sgabios
```

Running Nginx Unikraft with QEMU requires networking support.
For this to work properly a specific configuration must be enabled for QEMU.
Run the commands below to enable that configuration (for the network bridge to work):

```console
sudo mkdir /etc/qemu/
echo "allow all" | sudo tee /etc/qemu/bridge.conf
```

## Set Up

The following repositories are required for Nginx:

* The application repository (this repository): [`app-nginx`](https://github.com/unikraft/app-nginx)
* The Unikraft core repository: [`unikraft`](https://github.com/unikraft/unikraft)
* Library repositories:
  * The Nginx "library" repository: [`lib-nginx`](https://github.com/unikraft/lib-nginx)
  * The standard C library: [`lib-musl`](https://github.com/unikraft/lib-musl)
  * The networking stack library: [`lib-lwip`](https://github.com/unikraft/lib-lwip)

Follow the steps below for the setup:

  1. First clone the [`app-nginx` repository](https://github.com/unikraft/app-nginx) in the `nginx/` directory:

     ```console
     git clone https://github.com/unikraft/app-nginx nginx
     ```

     Enter the `nginx/` directory:

     ```console
     cd nginx/

     ls -F
     ```

     This will print the contents of the repository:

     ```text
     config-qemu-aarch64  config-qemu-x86_64  fs0/  kraft.yaml  Makefile  Makefile.uk  README.md  run-qemu-aarch64.sh*  run-qemu-x86_64.sh*
     ```

  1. While inside the `nginx/` directory, create the `.unikraft/` directory:

     ```console
     mkdir .unikraft
     ```

     Enter the `.unikraft/` directory:

     ```console
     cd .unikraft/
     ```

  1. While inside the `.unikraft` directory, clone the [`unikraft` repository](https://github.com/unikraft/unikraft):

     ```console
     git clone https://github.com/unikraft/unikraft unikraft
     ```

  1. While inside the `.unikraft/` directory, create the `libs/` directory:

     ```console
     mkdir libs
     ```

  1. While inside the `.unikraft/` directory, clone the library repositories in the `libs/` directory:

     ```console
     git clone https://github.com/unikraft/lib-nginx libs/nginx

     git clone https://github.com/unikraft/lib-musl libs/musl

     git clone https://github.com/unikraft/lib-lwip libs/lwip
     ```

  1. Get back to the application directory:

     ```console
     cd ../
     ```

     Use the `tree` command to inspect the contents of the `.unikraft/` directory.
     It should print something like this:

     ```console
     tree -F -L 2 .unikraft/
     ```

     The layout of the `.unikraft/` directory should look something like this:

     ```text
     .unikraft/
     |-- libs/
     |   |-- lwip/
     |   |-- musl/
     |   `-- nginx/
     `-- unikraft/
         |-- arch/
         |-- Config.uk
         |-- CONTRIBUTING.md
         |-- COPYING.md
         |-- include/
         |-- lib/
         |-- Makefile
         |-- Makefile.uk
         |-- plat/
         |-- README.md
         |-- support/
         `-- version.mk

     10 directories, 7 files
     ```

## Configure

Configuring, building and running a Unikraft application depends on our choice of platform and architecture.
Currently, supported platforms are QEMU (KVM), Xen and linuxu.
QEMU (KVM) is known to be working, so we focus on that.

Supported architectures are x86_64 and AArch64.

Use the corresponding the configuration files (`config-...`), according to your choice of platform and architecture.

### QEMU x86_64

Use the `config-qemu-x86_64` configuration file together with `make defconfig` to create the configuration file:

```console
UK_DEFCONFIG=$(pwd)/config-qemu-x86_64 make defconfig
```

This results in the creation of the `.config` file:

```console
ls .config
.config
```

The `.config` file will be used in the build step.

### QEMU AArch64

Use the `config-qemu-aarch64` configuration file together with `make defconfig` to create the configuration file:

```console
UK_DEFCONFIG=$(pwd)/config-qemu-aarch64 make defconfig
```

Similar to the x86_64 configuration, this results in the creation of the `.config` file that will be used in the build step.

## Build

Building uses as input the `.config` file from above, and results in a unikernel image as output.
The unikernel output image, together with intermediary build files, are stored in the `build/` directory.

### Clean Up

Before starting a build on a different platform or architecture, you must clean up the build output.
This may also be required in case of a new configuration.

Cleaning up is done with 3 possible commands:

* `make clean`: cleans all actual build output files (binary files, including the unikernel image)
* `make properclean`: removes the entire `build/` directory
* `make distclean`: removes the entire `build/` directory **and** the `.config` file

Typically, you would use `make properclean` to remove all build artifacts, but keep the configuration file.

### QEMU x86_64

Building for QEMU x86_64 assumes you did the QEMU x86_64 configuration step above.
Build the Unikraft Nginx image for QEMU x86_64 by using the command below:

```console
make -j $(nproc)
```

You will see a list of all the files generated by the build system:

```text
[...]
  LD      nginx_qemu-x86_64.dbg
  UKBI    nginx_qemu-x86_64.dbg.bootinfo
  SCSTRIP nginx_qemu-x86_64
  GZ      nginx_qemu-x86_64.gz
make[1]: Leaving directory '/media/razvan/c4f6765a-efa5-4ebd-9cf0-7da9908a0189/razvan/unikraft/solo/nginx/.unikraft/unikraft'
```

At the end of the build command, the `nginx_qemu-x86_64` unikernel image is generated.
This image is to be used in the run step.

### QEMU AArch64

If you had configured and build a unikernel image for another platform or architecture (such as x86_64) before, then:

1. Do a cleanup step with `make properclean`.

1. Configure for QEMU AAarch64, as shown above.

1. Follow the instructions below to build for QEMU AArch64.

Building for QEMU AArch64 assumes you did the QEMU AArch64 configuration step above.
Build the Unikraft Nginx image for QEMU AArch64 by using the same command as for x86_64:

```console
make -j $(nproc)
```

Similar to building for x86_64, you will see a list of the files generated by the build system.

```text
[...]
  LD      nginx_qemu-arm64.dbg
  UKBI    nginx_qemu-arm64.dbg.bootinfo
  SCSTRIP nginx_qemu-arm64
  GZ      nginx_qemu-arm64.gz
make[1]: Leaving directory '/media/razvan/c4f6765a-efa5-4ebd-9cf0-7da9908a0189/razvan/unikraft/solo/nginx/.unikraft/unikraft
```

Similarly to x86_64, at the end of the build command, the `nginx_qemu-arm64` unikernel image is generated.
This image is to be used in the run step.

## Run

### QEMU x86_64

To run the QEMU x86_64 build, use `run-qemu-x86_64.sh`:

```console
./run-qemu-x86_64.sh
```

This will start the Nginx server:

```text
qemu-system-x86_64: warning: TCG doesn't support requested feature: CPUID.01H:ECX.vmx [bit 5]
1: Set IPv4 address 172.44.0.2 mask 255.255.255.0 gw 172.44.0.1
en1: Added
en1: Interface is up
Powered by
o.   .o       _ _               __ _
Oo   Oo  ___ (_) | __ __  __ _ ' _) :_
oO   oO ' _ `| | |/ /  _)' _` | |_|  _)
oOo oOO| | | | |   (| | | (_) |  _) :_
 OoOoO ._, ._:_:_,\_._,  .__,_:_, \___)
                  Atlas 0.13.1~5eb820bd
```

The server listens for connections on the `172.44.0.2` address advertised.
A web client (such as `wget`) is required to query the server.

To test if the Unikraft instance of Nginx works, open another console and use the `wget` command below to query the server:

```console
wget 172.44.0.2
```

This will download the [`index.html`](https://github.com/unikraft/app-nginx/blob/staging/fs0/nginx/html/index.html) file provided in the `fs0/` directory.

```text
--2023-07-01 13:53:24--  http://172.44.0.2/
Connecting to 172.44.0.2:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 180 [text/html]
Saving to: ‘index.html’

index.html                                    100%[================================================================================================>]     180  --.-KB/s    in 0s

2023-07-01 13:53:25 (12.6 MB/s) - ‘index.html’ saved [180/180]
```

To close the QEMU Nginx server, use the `Ctrl+a x` keyboard shortcut;
that is press the `Ctrl` and `a` keys at the same time and then, separately, press the `x` key.

### QEMU AArch64

To run the AArch64 build, use `run-qemu-aarch64.sh`:

```console
./run-qemu-aarch64.sh
```

This will start the Nginx server:

```text
1: Set IPv4 address 172.44.0.2 mask 255.255.255.0 gw 172.44.0.1
en1: Added
en1: Interface is up
Powered by
o.   .o       _ _               __ _
Oo   Oo  ___ (_) | __ __  __ _ ' _) :_
oO   oO ' _ `| | |/ /  _)' _` | |_|  _)
oOo oOO| | | | |   (| | | (_) |  _) :_
 OoOoO ._, ._:_:_,\_._,  .__,_:_, \___)
                  Atlas 0.13.1~5eb820bd
```

To test if the Unikraft instance of the Nginx server works, open another console and use the `wget` command, similar to the QEMU x86_64 run above:

```console
wget 172.44.0.2
```

This will download the [`index.html`](https://github.com/unikraft/app-nginx/blob/staging/fs0/nginx/html/index.html) file provided in the `fs0/` directory.

```text
--2023-07-01 14:32:26--  http://172.44.0.2/
Connecting to 172.44.0.2:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 180 [text/html]
Saving to: ‘index.html’

index.html                                    100%[================================================================================================>]     180  --.-KB/s    in 0s

2023-07-01 14:32:26 (9.87 MB/s) - ‘index.html’ saved [180/180]
```

Similarly, to close the QEMU Nginx server, use the `Ctrl+a x` keyboard shortcut.
