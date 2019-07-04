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
make test
case "$jobname" in
linux-gcc)
	export GIT_TEST_SPLIT_INDEX=yes
	export GIT_TEST_FULL_IN_PACK_ARRAY=true
	export GIT_TEST_OE_SIZE=10
	export GIT_TEST_OE_DELTA_SIZE=5
	export GIT_TEST_COMMIT_GRAPH=1
	export GIT_TEST_MULTI_PACK_INDEX=1
	make test
	;;
linux-clang)
	PATH="$P4_OLD_DIR:$GIT_LFS_OLD_DIR:$PATH"
	p4 -V
	git-lfs version
	make test T='t98*.sh' GIT_PROVE_OPTS="${GIT_PROVE_OPTS%%--state=*}"
	;;
esac

check_unignored_build_artifacts

save_good_tree
