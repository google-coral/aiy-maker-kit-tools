# AIY Maker Kit system image tools

This repository contains scripts to create a Raspberry Pi OS system image
with library requirements for the Coral USB Accelerator, plus various settings
to enable the AIY Maker Kit.

If you want to set up the AIY Maker Kit using this image, follow the
[AIY Maker Kit setup guide](https://aiyprojects.withgoogle.com/maker/).

If you just want the image file, you can get it from
[this repo's releases page](https://github.com/google-coral/aiy-maker-kit-tools/releases)


## Build the Raspberry Pi system image

If you want to build the system image yourself, first clone this repo:

```
git clone https://github.com/google-coral/aiy-maker-kit-tools.git
```

**Note:** If you're on macOS, you need to install `coreutils` (run either
`brew install coreutils` or `sudo port install coreutils`).

Then you can build the SD card image using Docker by running this command
from the repo root (on Linux or Mac):

```
make docker-release
```

Or build it without Docker with this command (on Linux only):

```
# You might need to install a few tool dependencies first:
# sudo apt-get install zerofree qemu qemu-user-static binfmt-support

make release
```

Either way, the image is saved in the `out` directory.


## Update an existing Raspberry Pi image

As an alternative to flashing a new system image, you can use the `setup.sh`
script from this repo to install all the libraries required for the Coral USB
Accelerator and the Maker Kit projects.

However, this script is not guaranteed to work on all system configurations. If
you use this script, you might encounter a variety of failures when using the
[`aiymakerkit` APIs](https://github.com/google-coral/aiy-maker-kit).
In particular, as of this writing, there are known issues on the Bullseye
version of RPI OS, which is why our system image is built with Buster.

If you accept these risks, you can install the required libraries by running
this command from your Raspberry Pi:

```
bash <(curl https://raw.githubusercontent.com/google-coral/aiy-maker-kit-tools/main/setup.sh)
```

The unusual command format is necessary so the script can accept user input.
