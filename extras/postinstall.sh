#!/bin/bash

# install extra packages
find /install -name "*.deb"|while read package; do
  dpkg -i $package
done
