#!/bin/sh
#
# Build and test a 32-bit Git in a Docker container

. ${0%/*}/lib-travisci.sh

docker exec --interactive --tty \
	--env DEVELOPER \
	--env DEFAULT_TEST_TARGET \
	--env GIT_PROVE_OPTS \
	--env GIT_TEST_OPTS \
	--env GIT_TEST_CLONE_2GB \
	Linux32 \
	/usr/src/git/ci/run-linux32-build.sh $(id -u $USER)

check_unignored_build_artifacts

save_good_tree
