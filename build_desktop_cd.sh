#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

DISTRO="wily"
VERSION="15.10"
ARCH="amd64"
SCRIPT=$(readlink -f $0)
BASEDIR=`dirname $SCRIPT`
IMAGE_NAME="Ubuntu 15.10 Custom"

ORIG="$BASEDIR/ubuntu-$VERSION-desktop-$ARCH.iso"
MOUNT="$BASEDIR/mount"
BUILD="$BASEDIR/build"
IMAGE="$BASEDIR/ubuntu-$VERSION-desktop-$ARCH-custom.iso"

set -e

function clean {
  # Clean up old stuff
  for d in "$MOUNT" "$BUILD" "$IMAGE"; do
    if [ -e "$d" ]; then
      rm -rf "$d"
    fi
  done
}

function create_required_folders {
  # Ensure the folders we need exist
  for d in "$MOUNT" "$BUILD"; do
    if [ ! -e "$d" ]; then
      mkdir -p "$d"
    fi
  done
}

function download_base_image {
  wget -N -P "$BASEDIR" "http://releases.ubuntu.com/$VERSION/ubuntu-$VERSION-desktop-$ARCH.iso"
}

function extract_base_image {
  # sync with latest image
  mount -o loop $ORIG $MOUNT 2>/dev/null
  rsync -a $MOUNT/ $BUILD/ >/dev/null
  umount $MOUNT
}

function update_preseed {
  cp -f "$BASEDIR"/ubuntu.seed "$BUILD"/preseed/ubuntu.seed
  pushd "$BUILD"
  local checksum=$(md5sum ./preseed/ubuntu.seed)
  sed -i -- "s:[^\s]+\s+\./preseed/ubuntu\.seed:$checksum:g" "$BUILD"/md5sum.txt
  popd
}

function install_extras {
  if [ ! -d "$BUILD"/extras ]; then
    mkdir -p "$BUILD"/extras
  fi
  rsync -a "$BASEDIR"/extras/ "$BUILD"/extras
  pushd "$BUILD"
  find ./extras -type f -print0 | xargs -0 md5sum >> md5sum.txt
  popd
}

function build_cd_image {
  mkisofs -D -r -V "$IMAGE_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $IMAGE $BUILD
}

function build {
  create_required_folders
  download_base_image
  extract_base_image
  update_preseed
  install_extras
  build_cd_image
}

clean
build
