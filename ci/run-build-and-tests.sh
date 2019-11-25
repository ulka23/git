#!/bin/sh
#
# Build and test Git
#

. ${0%/*}/lib-travisci.sh

ln -s "$cache_dir/.prove" t/.prove

lscpu

make -j4
cd t
for i in $(seq 1 500)
do
	echo "  ####  $i  ####"
	./t5319-multi-pack-index.sh -r 1-14 --verbose-log -x -i
done

check_unignored_build_artifacts

save_good_tree
