#!/bin/sh
#
# Build and test Git
#

. ${0%/*}/lib.sh

case "$CI_OS_NAME" in
windows*) cmd //c mklink //j t\\.prove "$(cygpath -aw "$cache_dir/.prove")";;
*) ln -s "$cache_dir/.prove" t/.prove;;
esac

make
cd t
./t5319-multi-pack-index.sh -r 1-16 --stress --stress-limit=1000

check_unignored_build_artifacts

save_good_tree
