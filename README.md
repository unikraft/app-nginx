# Nginx on Unikraft

This application starts an Nginx web server with Unikraft.
Follow the instructions below to set up, configure, build and run Nginx.

To get started immediately, you can use Unikraft's companion command-line companion tool, [`kraft`](https://github.com/unikraft/kraftkit).
Start by running the interactive installer:

```console
curl --proto '=https' --tlsv1.2 -sSf https://get.kraftkit.sh | sudo sh
```

Once installed, clone [this repository](https://github.com/unikraft/app-nginx) and run `kraft build`:

```console
git clone https://github.com/unikraft/app-nginx nginx
cd nginx/
kraft build
```

This will guide you through an interactive build process where you can select one of the available targets (architecture/platform combinations).
Otherwise, we recommend building for `qemu/x86_64` like so:

```console
kraft build --target nginx-qemu-x86_64-initrd
```

Once built, you can instantiate the unikernel via:

```console
kraft run --target nginx-qemu-x86_64-initrd --initrd ./ -p 8080:80
```

If you don't have KVM support (such as when running inside a virtual machine), pass the `-W` option to `kraft run` to disable virtualization support:

```console
kraft run -W --target nginx-qemu-x86_64-initrd --initrd ./ -p 8080:80
```

When left without the `--target` argument, you'll be queried for the desired target from the list.

To use the Unikraft instance of Nginx, open another console and use the `wget` command below to query the server:

```console
wget localhost:8080
```

## Work with the Basic Build & Run Toolchain (Advanced)

You can set up, configure, build and run the application from grounds up, without using the companion tool `kraft`.

### Quick Setup (aka TLDR)

For a quick setup, run the commands below.
Note that you still need to install the [requirements](#requirements).

For building and running everything for `x86_64`, follow the steps below:

```console
git clone https://github.com/unikraft/app-nginx nginx
cd nginx/
./scripts/setup.sh
wget https://raw.githubusercontent.com/unikraft/app-testing/staging/scripts/generate.py -O scripts/generate.py
chmod a+x scripts/generate.py
./scripts/generate.py
./scripts/build/make-qemu-x86_64-9pfs.sh
./scripts/run/qemu-x86_64-9pfs.sh
```

This will configure, build and run the `nginx` server.
You can see how to test it in the [running section](#run).

The same can be done for `AArch64`, by running the commands below:

```console
git clone https://github.com/unikraft/app-nginx nginx
cd nginx/
./scripts/setup.sh
wget https://raw.githubusercontent.com/unikraft/app-testing/staging/scripts/generate.py -O scripts/generate.py
chmod a+x scripts/generate.py
./scripts/generate.py
./scripts/build/make-qemu-arm64-9pfs.sh
./scripts/run/qemu-arm64-9pfs.sh
```

Similar to the `x86_64` build, this will start the `nginx` server.
Information about every step is detailed below.

### Requirements

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

### Set Up

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

     ls -aF
     ```

     This will print the contents of the repository:

     ```text
     Makefile  Makefile.uk  README.md  defconfigs/  kraft.cloud.yaml  kraft.yaml  rootfs/  scripts/
     ```

  1. While inside the `nginx/` directory, clone all required repositories by using the `setup.sh` script:

     ```console
     ./scripts/setup.sh
     ```

  1. Use the `tree` command to inspect the contents of the `workdir/` directory:

     ```console
     tree -F -L 2 workdir/
     ```

     The layout of the `workdir/` directory should look something like this:

     ```text
     workdir/
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

## Scripted Building and Running

To make it easier to build, run and test different configurations, the repository provides a set of scripts that do everything required.
These are scripts used for building different configurations of the Nginx server and for running these with all the requirements behind the scenes: creating network configurations, setting up archives etc.

First of all, grab the [`generate.py` script](https://github.com/unikraft/app-testing/blob/staging/scripts/generate.py) and place it in the `scripts/` directory by running:

```console
wget https://raw.githubusercontent.com/unikraft/app-testing/staging/scripts/generate.py -O scripts/generate.py
chmod a+x scripts/generate.py
```

Now, run the `generate.py` script.
You must run it in the root directory of this repository:

```console
./scripts/generate.py
```

The scripts (as shell scripts) are now generated in `scripts/build/` and `scripts/run/`:

```text
scripts/
|-- build/
|   |-- kraft-fc-aarch64-initrd.sh*
|   |-- kraft-fc-arm64-initrd.sh*
|   |-- kraft-fc-x86_64-initrd.sh*
|   |-- kraft-qemu-aarch64-9pfs.sh*
|   |-- kraft-qemu-aarch64-initrd.sh*
|   |-- kraft-qemu-arm64-9pfs.sh*
|   |-- kraft-qemu-arm64-initrd.sh*
|   |-- kraft-qemu-x86_64-9pfs.sh*
|   |-- kraft-qemu-x86_64-initrd.sh*
|   |-- make-fc-x86_64-initrd.sh*
|   |-- make-qemu-arm64-9pfs.sh*
|   |-- make-qemu-arm64-initrd.sh*
|   |-- make-qemu-x86_64-9pfs.sh*
|   `-- make-qemu-x86_64-initrd.sh*
|-- generate.py*
|-- run/
|   |-- fc-x86_64-initrd.json
|   |-- fc-x86_64-initrd.sh*
|   |-- kraft-fc-aarch64-initrd.sh*
|   |-- kraft-fc-arm64-initrd.sh*
|   |-- kraft-fc-x86_64-initrd.sh*
|   |-- kraft-qemu-aarch64-9pfs.sh*
|   |-- kraft-qemu-aarch64-initrd.sh*
|   |-- kraft-qemu-arm64-9pfs.sh*
|   |-- kraft-qemu-arm64-initrd.sh*
|   |-- kraft-qemu-x86_64-9pfs.sh*
|   |-- kraft-qemu-x86_64-initrd.sh*
|   |-- qemu-arm64-9pfs.sh*
|   |-- qemu-arm64-initrd.sh*
|   |-- qemu-x86_64-9pfs.sh*
|   `-- qemu-x86_64-initrd.sh*
|-- run.yaml
`-- setup.sh*
```

They are shell scripts, so you can use an editor or a text viewer to check their contents:

```console
cat scripts/run/fc-x86_64-initrd.sh
```

Now, invoke each script to build and run the application.
A sample build and run set of commands is:

```console
./scripts/build/make-qemu-x86_64-9pfs.sh
./scripts/run/qemu-x86_64-9pfs.sh
```

Note that Firecracker only works with initrd (not 9pfs).
And Firecracker networking is not yet upstream.

## Detailed Steps

### Configure

Configuring, building and running a Unikraft application depends on our choice of platform and architecture.
Currently, supported platforms are QEMU (KVM), Xen and linuxu.
QEMU (KVM) is known to be working, so we focus on that.

Supported architectures are x86_64 and AArch64.

Use the corresponding the configuration files (`defconfigs/*`), according to your choice of platform and architecture.

#### QEMU x86_64

Use the `defconfigs/qemu-x86_64-9pfs` configuration file together with `make defconfig` to create the configuration file:

```console
UK_DEFCONFIG=$(pwd)/defconfigs/qemu-x86_64-9pfs make defconfig
```

This results in the creation of the `.config` file:

```console
ls .config
.config
```

The `.config` file will be used in the build step.

#### QEMU AArch64

Use the `defconfigs/qemu-arm64-9pfs` configuration file together with `make defconfig` to create the configuration file:

```console
UK_DEFCONFIG=$(pwd)/defconfigs/qemu-arm64-9pfs make defconfig
```

Similar to the x86_64 configuration, this results in the creation of the `.config` file that will be used in the build step.

### Build

Building uses as input the `.config` file from above, and results in a unikernel image as output.
The unikernel output image, together with intermediary build files, are stored in the `build/` directory.

#### Clean Up

Before starting a build on a different platform or architecture, you must clean up the build output.
This may also be required in case of a new configuration.

Cleaning up is done with 3 possible commands:

* `make clean`: cleans all actual build output files (binary files, including the unikernel image)
* `make properclean`: removes the entire `build/` directory
* `make distclean`: removes the entire `build/` directory **and** the `.config` file

Typically, you would use `make properclean` to remove all build artifacts, but keep the configuration file.

#### QEMU x86_64

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
make[1]: Leaving directory 'nginx/workdir/unikraft'
```

At the end of the build command, the `nginx_qemu-x86_64` unikernel image is generated.
This image is to be used in the run step.

#### QEMU AArch64

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
make[1]: Leaving directory 'nginx/workdir/unikraft
```

Similarly to x86_64, at the end of the build command, the `nginx_qemu-arm64` unikernel image is generated.
This image is to be used in the run step.

### Run

#### QEMU x86_64

To run the QEMU x86_64 build, use `run-qemu-x86_64-9pfs.sh`:

```console
./scripts/generate.py
./scripts/run/qemu-x86_64-9pfs-nginx.sh
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

This will download the [`index.html`](https://github.com/unikraft/app-nginx/blob/staging//nginx/html/index.html) file provided in the `rootfs/` directory.

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

#### QEMU AArch64

To run the AArch64 build, use `run-qemu-aarch64-9pfs.sh`:

```console
./scripts/generate.py
./scripts/run/qemu-arm64-9pfs-nginx.sh
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

This will download the [`index.html`](https://github.com/unikraft/app-nginx/blob/staging//nginx/html/index.html) file provided in the `rootfs/` directory.

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

### Building and Running with initrd

The examples above use 9pfs as the filesystem interface.
Clean up the previous configuration, use the initrd configuration and build the unikernel by using the commands:

```console
./scripts/generate.py
./scripts/build/make-qemu-x86_64-initrd.sh
```

To run the QEMU x86_64 initrd build, use `run-qemu-x86_64-initrd.sh`:

```console
./scripts/run/qemu-x86_64-initrd-nginx.sh
```

The commands for AArch64 are similar:

```console
./scripts/build/make-qemu-arm64-initrd.sh
```

### Building and Running with Firecracker

[Firecracker](https://firecracker-microvm.github.io/) is a lightweight VMM (*virtual machine manager*) that can be used as more efficient alternative to QEMU.

Configure and build commands are similar to a QEMU-based build with an initrd-based filesystem:

```console
./scripts/build/make-fc-x86_64-initrd.sh
```

To use Firecraker, you need to download a [Firecracker release](https://github.com/firecracker-microvm/firecracker/releases).
You can use the commands below to make the `firecracker-x86_64` executable from release v1.4.0 available globally in the command line:

```console
cd /tmp 
wget https://github.com/firecracker-microvm/firecracker/releases/download/v1.4.0/firecracker-v1.4.0-x86_64.tgz
tar xzf firecracker-v1.4.0-x86_64.tgz 
sudo cp release-v1.4.0-x86_64/firecracker-v1.4.0-x86_64 /usr/local/bin/firecracker-x86_64
```

To run a unikernel image, you need to configure a JSON file.
This is the `scripts/run/fc-x86_64-initrd-nginx.json` file.
This configuration file is uses as part of the run command:

```console
./scripts/run/fc-x86_64-initrd-nginx.sh
```

Same as running with QEMU, the application will start:

```text
Powered by
o.   .o       _ _               __ _
Oo   Oo  ___ (_) | __ __  __ _ ' _) :_
oO   oO ' _ `| | |/ /  _)' _` | |_|  _)
oOo oOO| | | | |   (| | | (_) |  _) :_
 OoOoO ._, ._:_:_,\_._,  .__,_:_, \___)
                  Atlas 0.13.1~f7511c8b
```

Note that, currently (release 0.14), there is not yet networking support in Unikraft for Firecracker, so Nginx cannot be properly used.
