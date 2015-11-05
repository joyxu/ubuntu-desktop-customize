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

# Clean up old stuff
for d in "$MOUNT" "$BUILD" "$FTPARCHIVE"; do
  if [ -e "$d" ]; then
    rm -rf "$d"
  fi
done

# Ensure the folders we need exist
for d in "$MOUNT" "$BUILD" "$INDICES" "$FTPARCHIVE"; do
  if [ ! -e "$d" ]; then
    mkdir -p "$d"
  fi
done

# sync with latest image
mount -o loop $ORIG $MOUNT 2>/dev/null
rsync -av $MOUNT/ $BUILD/ >/dev/null
umount $MOUNT

# Delete old keyring, if it exists
if [ -e "$BUILD/pool/main/u/ubuntu-keyring" ]; then
  rm -rf "$BUILD/pool/main/u/ubuntu-keyring"
fi

# Add our keyring
mkdir -p "$BUILD/pool/main/u/ubuntu-keyring"
cp "$BASEDIR"/ubuntu-keyring/ubuntu-keyring*deb "$BUILD"/pool/main/u/ubuntu-keyring/

# Build extras repo
for SUFFIX in extra.main main main.debian-installer restricted restricted.debian-installer; do
  wget -N -P "$INDICES" http://archive.ubuntu.com/ubuntu/indices/override.$DISTRO.$SUFFIX >/dev/null
done

if [ ! -f "$FTPARCHIVE/apt.conf" ]; then
  cat "$BUILD/dists/$DISTRO/Release" | egrep -v "^ " | egrep -v "^(Date|MD5Sum|SHA1|SHA256)" | sed 's/: / "/' | sed 's/^/APT::FTPArchive::Release::/' | sed 's/$/";/' > $FTPARCHIVE/apt.conf
fi

if [ ! -f "$FTPARCHIVE/apt-ftparchive-deb.conf" ]; then
  echo "Dir {
  ArchiveDir \"$BUILD\";
};

TreeDefault {
  Directory \"pool/\";
};

BinDirectory \"pool/main\" {
  Packages \"dists/$DISTRO/main/binary-$ARCH/Packages\";
  BinOverride \"$INDICES/override.$DISTRO.main\";
  ExtraOverride \"$INDICES/override.$DISTRO.extra2.main\";
};

Default {
  Packages {
    Extensions \".deb\";
    Compress \". gzip\";
  };
};

Contents {
  Compress \"gzip\";
};" > $FTPARCHIVE/apt-ftparchive-deb.conf
fi

if [ ! -f "$FTPARCHIVE/apt-ftparchive-udeb.conf" ]; then
  echo "Dir {
  ArchiveDir \"$BUILD\";
};

TreeDefault {
  Directory \"pool/\";
};

BinDirectory \"pool/main\" {
  Packages \"dists/$DISTRO/main/debian-installer/binary-$ARCH/Packages\";
  BinOverride \"$INDICES/override.$DISTRO.main.debian-installer\";
};

Default {
  Packages {
    Extensions \".udeb\";
    Compress \". gzip\";
  };
};

Contents {
  Compress \"gzip\";
};" > $FTPARCHIVE/apt-ftparchive-udeb.conf
fi

if [ ! -f $FTPARCHIVE/apt-ftparchive-extras.conf ]; then
        echo "Dir {
  ArchiveDir \"$BUILD\";
};

TreeDefault {
  Directory \"pool/\";
};

BinDirectory \"pool/extras\" {
  Packages \"dists/$DISTRO/extras/binary-$ARCH/Packages\";
};

Default {
  Packages {
    Extensions \".deb\";
    Compress \". gzip\";
  };
};

Contents {
  Compress \"gzip\";
};" > "$FTPARCHIVE"/apt-ftparchive-extras.conf
fi

if [ ! -f "$FTPARCHIVE/release.conf" ]; then
  echo "APT::FTPArchive::Release::Origin "Ubuntu";
APT::FTPArchive::Release::Label "Ubuntu";
APT::FTPArchive::Release::Suite "$DISTRO";
APT::FTPArchive::Release::Version "$VERSION";
APT::FTPArchive::Release::Codename "$DISTRO";
APT::FTPArchive::Release::Architectures "$ARCH";
APT::FTPArchive::Release::Components "main restricted extras";
APT::FTPArchive::Release::Description "Ubuntu $VERSION";
" > "$FTPARCHIVE"/release.conf
fi

# Add extra packages
mkdir -p "$BUILD/pool/extras/"
rsync -az "$BASEDIR/extras/" "$BUILD/pool/extras/"
mkdir -p "$BUILD/dists/$DISTRO/extras/"

rm $BUILD/dists/$DISTRO/Release*
for component in main extras; do
  if [ ! -d "$BUILD/dists/$DISTRO/$component/binary-$ARCH" ]; then
    mkdir -p "$BUILD/dists/$DISTRO/$component/binary-$ARCH/"
  fi
  apt-ftparchive packages "$BUILD/pool/$component/" > "$BUILD/dists/$DISTRO/$component/binary-$ARCH/Packages"
  gzip -c "$BUILD/dists/$DISTRO/$component/binary-$ARCH/Packages" | \
    tee "$BUILD/dists/$DISTRO/$component/binary-$ARCH/Packages.gz" > /dev/null
done

apt-ftparchive -c "$FTPARCHIVE/apt.conf" release $BUILD/dists/$DISTRO > $BUILD/dists/$DISTRO/Release
gpg --output $BUILD/dists/$DISTRO/Release.gpg -ba $BUILD/dists/$DISTRO/Release


mkisofs -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -hide-rr-moved -o $IMAGE -R $BUILD/
