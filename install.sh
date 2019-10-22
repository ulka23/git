#!/bin/sh

set -ex

from=$(pwd)

cp -v p4d p4 /usr/local/bin

cd /usr/local

tar fxz "$from"/gmp-6.1.2_2-installed.tar.gz
tar fxz "$from"/isl-0.21-installed.tar.gz
tar fxz "$from"/libmpc-1.1.0-installed.tar.gz
tar fxz "$from"/mpfr-4.0.2-installed.tar.gz
tar fxz "$from"/gcc-9.2.0_1-installed.tar.gz
tar fxz "$from"/git-lfs-2.8.0-installed.tar.gz
