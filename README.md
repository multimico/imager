# ubuntu
Customised Install Image with MultiMICO Hooks in Grub

## Build the image builder container

```
docker build -t multimico/isobuilder:latest .
```

## Run the image builder

```
docker run -it --rm -v ~/Documents/data/isobuilder/:/data -e RELEASE=21.10 -e EXTENSION=ZHAW multimico/isobuilder:latest
```