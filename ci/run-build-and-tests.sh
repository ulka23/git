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
case "$jobname" in
linux-gcc-4.8)
	# Don't run the tests; we only care about whether Git can be
	# built with GCC 4.8, as it errors out on some undesired (C99)
	# constructs that newer compilers seem to quietly accept.
	;;
*)
	cd t
	./t9999-rebase-racy-todo-reread.sh -x
	;;
esac

check_unignored_build_artifacts

save_good_tree
