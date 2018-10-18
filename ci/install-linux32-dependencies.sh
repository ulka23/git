#!/bin/sh
#
# Download and run Docker image to build and test 32-bit Git
#

. ${0%/*}/lib-travisci.sh

docker pull daald/ubuntu32:xenial

# Use the following command to debug the docker build locally:
# $ docker run -itv "${PWD}:/usr/src/git" --entrypoint /bin/bash daald/ubuntu32:xenial
# root@container:/# /usr/src/git/ci/run-linux32-build.sh <host-user-id>

container_cache_dir=/tmp/travis-cache

docker run \
	--detach --interactive --tty \
	--env cache_dir="$container_cache_dir" \
	--volume "${PWD}:/usr/src/git" \
	--volume "$cache_dir:$container_cache_dir" \
	--name Linux32 \
	daald/ubuntu32:xenial \
	/bin/bash

# Update packages to the latest available versions
docker exec --interactive --tty Linux32 \
	linux32 --32bit i386 sh -c '
		apt update >/dev/null &&
		apt install -q -y build-essential libcurl4-openssl-dev \
			libssl-dev libexpat-dev gettext python
	'
