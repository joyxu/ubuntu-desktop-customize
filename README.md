# Ubuntu Desktop Customization

Create a customized Ubuntu Desktop installer CD, without too much fluff.

## Acknowledgements

Acknowledgements to the authors and contributors of all the pages described
under Prior Art.

Additional acknowledgements to the overarching Linux and Open Source
communities.

## Prior Art

This solution is based on other work to customize an Ubuntu install.

### [Live CD Customization (Ubuntu)](https://help.ubuntu.com/community/LiveCDCustomization?action=recall&rev=196)

This page gives a walkthrough of how to customize the Ubuntu Desktop install
CD. It focuses more on customizing the "Live" parts of the CD and not so much on
the "Install" parts.

This solution skips over most of the instructions on this page (the LiveCD
is untouched, so there's no need to muck about with SquashFS), but the page
gives a bit of context as to what's different between how the Desktop CD and the Server CD work (e.g. Casper and Ubiquity).

### [Install CD Customization (Ubuntu)](https://help.ubuntu.com/community/InstallCDCustomization?action=recall&rev=71)

This page provides instructions for customizing the Ubuntu installer using the
Server ISO. It was really helpful in understanding all the steps that the script
needed to do.

The main difference between this solution and the steps described on this page
is that we don't build a repo using `apt-ftparchive` (which means we don't need
to worry about gpg signing keys). Instead, we just stick the debs into `extras/`
and install them from within a shell using `dpkg -i` after the rest of the
installer has finished.

### [Install CD Customization Scripts (Ubuntu)](https://help.ubuntu.com/community/InstallCDCustomization/Scripts?action=recall&rev=4)

This page has a couple example scripts for automating the ISO build. Much of the
build script is based on these examples.

### [Workstation Autoinstall Preseed](https://wiki.ubuntu.com/Enterprise/WorkstationAutoinstallPreseed)

This is an end-to-end example of how to preseed the whole Ubuntu install.

Encrypting the disk using a temporary password during the install and then
prompting the user to change the encryption password on first boot is a great
idea. Unfortunately, preseeding disk encryption doesn't work with Ubiquity in
Vivid (15.04) or Wily (15.10) (see [bug #1386153](https://bugs.launchpad.net/ubuntu/+source/ubiquity/+bug/1386153)).
However, it's a great example of how to do additional setup work in a
post-install hook (see [Workstation Auto Install Scripts](https://wiki.ubuntu.com/Enterprise/WorkstationAutoinstallScripts)), and
this solution totally rips off that whole concept.

### [Generic Bucket (Vagrant-Cachier)](http://fgrehm.viewdocs.io/vagrant-cachier/buckets/generic/)

The `wget` command used by the build script to download the upstream ISO totally
rips off the example on this page.

## Requirements

* root access (e.g. sudo privileges... see TODOs)
* wget (`apt-get install wget`)
* rsync (`apt-get install rsync`)
* mkisofs (`apt-get install genisoimage`)

## Usage

1. Clone this repo.
1. Add extra packages (.deb files) under `extras/`
1. Run `build_desktop_cd.sh` as the root user (e.g. `sudo build_desktop_cd.sh`)
1. Do something with the resulting `ubuntu-$VERSION-desktop-$ARCH-custom.iso`
(burn it to a disk, install it on a flash drive, etc.)

## TODOs

### Remove root/sudo requirement

Root privileges are needed to mount the upstream iso (for extracting its
contents) and to modify the preseed and md5sum files. The mounting problem could
be solved with [fuseiso](https://help.ubuntu.com/community/FuseIso), but that
wouldn't solve the file permissions problem.
