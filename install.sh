#!/bin/sh

set -ex

from=$(pwd)

cp -v p4d p4 /usr/local/bin

cd /usr/local

for tgz in "$from"/*.tar.gz
do
	tar fxz "$tgz"
done
