#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

DISTRO="vivid"
VERSION="15.04"
ARCH="amd64"
SCRIPT=$(readlink -f $0)
BASEDIR=`dirname $SCRIPT`

ORIG="$BASEDIR/ubuntu-$VERSION-desktop-$ARCH.iso"
MOUNT="$BASEDIR/mount"
BUILD="$BASEDIR/build"
IMAGE="$BASEDIR/ubuntu-$VERSION-desktop-$ARCH-custom.iso"
INDICES="$BASEDIR/indices"
FTPARCHIVE="$BASEDIR/apt-ftparchive"

set -e

function clean {
  # Clean up old stuff
  for d in "$MOUNT" "$BUILD" "$FTPARCHIVE"; do
    if [ -e "$d" ]; then
      rm -rf "$d"
    fi
  done
}

function create_required_folders {
  # Ensure the folders we need exist
  for d in "$MOUNT" "$BUILD" "$INDICES" "$FTPARCHIVE"; do
    if [ ! -e "$d" ]; then
      mkdir -p "$d"
    fi
  done
}

function extract_base_image {
  # sync with latest image
  mount -o loop $ORIG $MOUNT 2>/dev/null
  rsync -av $MOUNT/ $BUILD/ >/dev/null
  umount $MOUNT
}

function update_preseed {
  cp -f "$BASEDIR"/ubuntu.seed "$BUILD"/preseed/ubuntu.seed
  pushd "$BUILD"
  checksum=$(md5sum ./preseed/ubuntu.seed)
  sed -i -- "s:[^\s]+\s+\./preseed/ubuntu\.seed:$CHECKSUM:g" "$BUILD"/md5sum.txt
}

function build_cd_image {
  mkisofs -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -hide-rr-moved -o $IMAGE -R $BUILD/
}

function build {
  create_required_folders
  extract_base_image
  update_preseed
  build_cd_image
}

clean
build
