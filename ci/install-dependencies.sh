#!/usr/bin/env bash
#
# Install dependencies required to build and test Git on Linux and macOS
#

. ${0%/*}/lib.sh

P4_BASE_URL=http://filehost.perforce.com/perforce/
GIT_LFS_LATEST_URL=https://github.com/git-lfs/git-lfs/releases/latest
GIT_LFS_BASE_URL=https://github.com/github/git-lfs/releases/download

case "$jobname" in
linux-clang|linux-gcc)
	sudo apt-add-repository -y "ppa:ubuntu-toolchain-r/test"
	sudo apt-get -q update
	sudo apt-get -q -y install language-pack-is libsvn-perl apache2
	case "$jobname" in
	linux-gcc)
		sudo apt-get -q -y install gcc-8
		;;
	linux-clang)
		mkdir --parents "$P4_OLD_DIR"
		pushd "$P4_OLD_DIR"
			wget --quiet "${P4_BASE_URL}r$LINUX_P4_OLD_VERSION/bin.linux26x86_64/p4d"
			wget --quiet "${P4_BASE_URL}r$LINUX_P4_OLD_VERSION/bin.linux26x86_64/p4"
			chmod u+x p4d
			chmod u+x p4
		popd

		mkdir --parents "$GIT_LFS_OLD_DIR"
		pushd "$GIT_LFS_OLD_DIR"
			wget --quiet "$GIT_LFS_BASE_URL/v$LINUX_GIT_LFS_OLD_VERSION/git-lfs-linux-amd64-$LINUX_GIT_LFS_OLD_VERSION.tar.gz"
			tar --extract --gunzip --file "git-lfs-linux-amd64-$LINUX_GIT_LFS_OLD_VERSION.tar.gz"
			cp git-lfs-$LINUX_GIT_LFS_OLD_VERSION/git-lfs .
		;;
	esac

	p4_version=$(curl --silent --show-error "$P4_BASE_URL" |
		sed -n -e 's/.*href="r\([0-9][0-9]\.[0-9]\)\/\?".*/\1/p' |
		tail -n1)
	if test -z "$p4_version"
	then
		echo "error: couldn't figure out latest P4 version"
		exit 1
	fi
	mkdir --parents "$P4_DIR"
	pushd "$P4_DIR"
		wget --quiet "${P4_BASE_URL}r$p4_version/bin.linux26x86_64/p4d"
		wget --quiet "${P4_BASE_URL}r$p4_version/bin.linux26x86_64/p4"
		chmod u+x p4d
		chmod u+x p4
	popd

	git_lfs_version=$(curl --silent --show-error --head --location \
		--write-out "%{url_effective}\n" --output /dev/null \
		"$GIT_LFS_LATEST_URL" | sed -e 's%.*/v%%')
	if test -z "$git_lfs_version"
	then
		echo "error: couldn't figure out latest Git-LFS version"
		exit 1
	fi
	mkdir --parents "$GIT_LFS_DIR"
	pushd "$GIT_LFS_DIR"
		# Unfortunately, the name and contents of the Git-LFS release
		# tarballs are inconsistent across versions:
		# Up until Git-LFS 2.4.2 the tarballs were named as
		# 'git-lfs-linux-amd64-X.Y.Z.tar.gz' and included a directory
		# 'git-lfs-X.Y.Z' containing the 'git-lfs' binary.
		# Since then all release tarballs are named as
		# 'git-lfs-linux-amd64-vX.Y.Z.tar.gz' (note the 'v' in front
		# of the version number) and contain all files directly in
		# the archive's root directory.
		# Who knows what the future might bring, so let's try to deal
		# with both cases.
		git_lfs_tarball=git-lfs-linux-amd64-v$git_lfs_version.tar.gz
		if wget --quiet "$GIT_LFS_BASE_URL/v$git_lfs_version/$git_lfs_tarball"
		then
			tar --extract --gunzip --file "$git_lfs_tarball"
		else
			git_lfs_tarball=git-lfs-linux-amd64-$git_lfs_version.tar.gz
			wget --quiet "$GIT_LFS_BASE_URL/v$git_lfs_version/$git_lfs_tarball"
			tar --extract --gunzip --file "$git_lfs_tarball"
			cp git-lfs-$git_lfs_version/git-lfs .
		fi
	popd
	;;
osx-clang|osx-gcc)
	export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1
	# Uncomment this if you want to run perf tests:
	# brew install gnu-time
	test -z "$BREW_INSTALL_PACKAGES" ||
	brew install $BREW_INSTALL_PACKAGES
	brew link --force gettext
	brew install caskroom/cask/perforce
	case "$jobname" in
	osx-gcc)
		brew link gcc@8
		;;
	esac
	;;
StaticAnalysis)
	sudo apt-get -q update
	sudo apt-get -q -y install coccinelle
	;;
Documentation)
	sudo apt-get -q update
	sudo apt-get -q -y install asciidoc xmlto

	test -n "$ALREADY_HAVE_ASCIIDOCTOR" ||
	gem install --version 1.5.8 asciidoctor
	;;
esac

if type p4d >/dev/null && type p4 >/dev/null
then
	echo "$(tput setaf 6)Perforce Server Version$(tput sgr0)"
	p4d -V | grep Rev.
	echo "$(tput setaf 6)Perforce Client Version$(tput sgr0)"
	p4 -V | grep Rev.
fi
if type git-lfs >/dev/null
then
	echo "$(tput setaf 6)Git-LFS Version$(tput sgr0)"
	git-lfs version
fi
