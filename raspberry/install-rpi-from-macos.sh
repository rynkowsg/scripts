#!/usr/bin/env bash

set -x

# STEP 1: Set destination disk
DISK="/dev/disk2"

# STEP 2: Update links from RPi website:
# https://www.raspberrypi.org/software/operating-systems/
FULL_IMG_URL="https://downloads.raspberrypi.org/raspios_full_armhf/images/raspios_full_armhf-2021-03-25/2021-03-04-raspios-buster-armhf-full.zip"
MIDI_IMG_URL="https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2021-03-25/2021-03-04-raspios-buster-armhf.zip"
LITE_IMG_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-03-25/2021-03-04-raspios-buster-armhf-lite.zip"

# STEP 3: Set the URL you need
URL="${FULL_IMG_URL}"
ZIP_NAME="$(basename "${URL}")"
IMG_NAME="${ZIP_NAME%.*}.img"

# Downloads and unzips
wget -c "${URL}"
unzip "${ZIP_NAME}"

# Format SD card
diskutil eraseDisk FAT32 NO_NAME "${DISK}"

# Copy data to the SD card
diskutil unmountDisk "${DISK}"
pv -tpreb "${IMG_NAME}" | dd of="${DISK}" bs=4m conv=notrunc,noerror

# Eject SDcard
diskutil eject "${DISK}"

# End
set +x

################
### COMMENTS ###
################

# how to take basename: https://stackoverflow.com/a/2664746

# How to show progress when using dd:
# LINUX
# -  dd bs=1m if=2021-03-04-raspios-buster-armhf-lite.img of="${DISK}" status=progress
# MAC
# - dd if=2021-03-04-raspios-buster-armhf-lite.img | pv | dd of="${DISK}" bs=4m
# - pv -tpreb 2021-03-04-raspios-buster-armhf-lite.img | dd of="${DISK}" bs=4m conv=notrunc,noerror
# - (pv -n 2021-03-04-raspios-buster-armhf-lite.img | dd of=/dev/disk2 bs=4m conv=notrunc,noerror) 2>&1 | dialog --gauge "Coping image to ${DISK}, please wait..." 10 70 0
#     -n - print number from 1 to 100 to the output
#     printed numbers are piped to the dialog app
