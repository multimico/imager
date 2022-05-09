# MultiMICO Imager

Build customised install images with MultiMICO Hooks in Grub. 

We use Ubuntu's live server iso image is the baseline for the image.

In order to automate the image building we created small docker image. 

The image builder has two options that are passed as environment variables. 

- `RELEASE` - The official release number (default `21.10`)
- `EXTENSION` - the extension to add to the iso image filename (default `multimico`)

The result will be stored in `/data`. In order to keep the iso image, one needs to mount a volume to the container at `/data`.

**Important:** This script will use ONLY official releases and ignores beta releases!

**This repo has no releases.** The docker image is intended to be built and run if needed.

## Build the image builder container

```
docker build -t multimico/isobuilder:latest .
```

## Run the image builder

```
docker run -it --rm -v ~/Documents/data/isobuilder/:/data -e RELEASE=21.10 multimico/isobuilder:latest
```

## Run a fresh build with the latest stable release of ubuntu

```
docker build -t multimico/isobuilder:latest . && docker run -it --rm -v ~/Documents/data/isobuilder/:/data -e RELEASE=21.10 multimico/isobuilder:latest
```

## Burn the image to a USB Stick

On Macs burn the new ISO image to a USB stick using `dd`:  https://thornelabs.net/posts/create-a-bootable-ubuntu-usb-drive-in-os-x.html

The home directory where /data is stored in depends on the PC the image building process takes place.  

```
~/Documents/data/isobuilder/ubuntu-21.10-live-server-amd64-multimico.iso of=/dev/rdisk4 bs=1048576
```
Similar approaches work on Linux. 

Otherwise other USB-imaging software (like Etcher) should work, too.

## History 

The initial idea and logic is taken from https://gist.github.com/s3rj1k/55b10cd20f31542046018fcce32f103e

For more recent Ubuntu-releases a few improvements were used from https://askubuntu.com/questions/1289400/remaster-installation-image-for-ubuntu-20-10

As the only changes that we needed were the extras in the boot command, the changes to the image are minimal and no extra software is added or removed. 

All more substantial configurations are done by the [initialization hooks](//github.com/multimico/init) or ansible as soon the system is available via ssh. 
