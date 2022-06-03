# MultiMICO Imager

Build customised Ubuntu ISO-images for Simplified [Infrastructure as Code](https://en.wikipedia.org/wiki/Infrastructure_as_code) Setups using GitHub.

## Usage

```
docker run -it --rm -v ~/isoimages/:/data -e RELEASE=21.10 ghcr.io/multimico/imager:latest
```

The new ISO-image will be stored into the directory mounted on the containers `/data` repository. If no data directory is mounted using docker's `-v` option, then the rebuild image will be lost.

The imager will only use official releases and ignores beta releases!

## Accepted Environment Variables

- EXTENSION - extension for the updated image (default: `multimico`)
- GIT_BRANCH - git branch to use for the cloud-init files (default: `cloud-init`)
- GIT_REPO - location of the git repository on GIT_SERVER (default: `multimico/init`)
- GIT_SERVER - location of the raw content server (default: `https://raw.githubusercontent.com`)
- RELEASE - release number of the Ubuntu version (default: `22.04`)

## Purpose 

When setting up barebone hardware infrastructure, we cannot rely on the fancy tools of cloud providers and shiny MAAS tools often require additional infrastructure, which makes it impractical in smaller or in distributed settings. Yet, we want to build on the principles of Infrastructure as Code even for bootstrapping infrastructures in less sophisticated settings such as home labs, edge clusters, or fog computing systems.

The image builder runs a minimal customisation of the default Ubuntu Server Image for implementing the Infrastructure as Code principle on top of GitHub's infrastructure. This is useful for creating reproducible infrastructure without facy tools such as MAAS.

The objective of this project is to create a minimal Ubuntu live image that triggers a controlled installation sequence to run all installation steps *without* manual intervention (or with minimal human intervention). This is part of the so called *bootstrapping* phase of new hardware *before* it is available to tools such as Ansible. This phase includes the following steps: 

- Formatting of the initial hard drive
- Network configuration
- Installation of core packages
- Creation of a system user
- Preparation of the system for remote management

## How does the new ISO-image work?

**Important** The new ISO-image requires a publicly available cloud-init repository on github. The public cloud-init will include the (hashed) password of the systemuser and the initial list of authorised users. Take precautions for updating this information after bootstrapping. 

The generated ISO-image is a vanilla Ubuntu live server image with a minor adaptation to the `grub`-bootloader to trigger Ubuntu's `cloud-init` process using the `nocloud-net` boot option. This option points at cloud-init files in a defined locationon github. In our case these files are part of the `cloud-init` branch of the [multimico/init](https://github.com/multimico/image) repository. The user-data is unspectacular and initialises the core system by formatting the main hard drive, sets up the main user and configures the network. The actual installation is then driggered by the `init.sh` script from [multimico/init](https://github.com/multimico/image) `main` branch. This allows us to have one installation medium for different system types. 

Different to other approaches of customising Ubuntu installs, no files are added to the boot image. All configuration files are hosted on public github repositories. Therefore, the pre-ansible installation can get adjusted simply by changing the data in the repositories.

***Security remark:*** It is not necessary that the configuration files are stored on github.com. It is sufficient that the configuration files are stored on "public" https-enabled git server on the local network.

## How does this container work?

The multimico/imager runs the following steps: 

- Pull the official Ubuntu Server ISO-image for the given release from the offical sources.
- Unpack the filesystem of the ISO-image.
- Change the `grub` boot loader configuration to pull the cloud-init files from a predefined location. 
- Updates the MD5 codes for ensuring that the automated health checks can pass without errors. 
- Rebuilds the ISO-image. 

The builder is designed to work with different (upcoming) Ubuntu Releases.

## Known Limitations 

The current docker images is build on Intel x86 architectures. On Apple Silicon Macs local docker image needs to be built (see below).

## Build the image builder container for internal use

```
docker build -t multimico/imager:latest .
```

## Run a fresh build with the latest stable release of ubuntu

```
docker build -t multimico/imager:latest . && docker run -it --rm -v ~/isoimages/:/data -e RELEASE=21.10 multimico/imager:latest
```

## Burn the image to a USB Stick

On Macs burn the new ISO image to a USB stick using `dd`:  https://thornelabs.net/posts/create-a-bootable-ubuntu-usb-drive-in-os-x.html

The home directory where /data is stored in depends on the PC the image building process takes place.  

```
~/isoimages/ubuntu-21.10-live-server-amd64-multimico.iso of=/dev/rdisk4 bs=1048576
```
Similar approaches work on Linux. 

Otherwise other USB-imaging software (like Etcher) should work, too.

## Historical notes 

The initial idea and logic is taken from https://gist.github.com/s3rj1k/55b10cd20f31542046018fcce32f103e

For more recent Ubuntu-releases a few improvements were used from https://askubuntu.com/questions/1289400/remaster-installation-image-for-ubuntu-20-10

As the only changes that we needed were the extras in the boot command, the changes to the image are minimal and no extra software is added or removed. 

All more substantial configurations are done by the [initialization hooks](//github.com/multimico/init) or ansible as soon the system is available via ssh. 
