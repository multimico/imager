# MultiMICO Imager

Build customised install images with MultiMICO Hooks in Grub. 

We use Ubuntu's live server iso image is the baseline for the image.

In order to automate the image building we created small docker image. 

The image builder has two options that are passed as environment variables. 

- `RELEASE` - The official release number (default `21.10`)
- `EXTENSION` - the extension to add to the iso image filename (default `multimico`)

The result will be stored in `/data`. In order to keep the iso image, one needs to mount a volume to the container at `/data`.

**Important:** This script will use ONLY official releases and ignores beta releases!

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
