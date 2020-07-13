#!/bin/bash
set -e -v

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
container=$(buildah from joequant/cauldron)
buildah config --label maintainer="Joseph C Wang <joequant@gmail.com>" $container
buildah config --user root $container
mountpoint=$(buildah mount $container)
rootfsDir=$mountpoint
name=joequant/cacher
releasever=cauldron
LANG=C
LANGUAGE=C
LC_ALL=C

if [ -z $buildarch ]; then
	# Attempt to identify target arch
	buildarch="$(rpm --eval '%{_target_cpu}')"
fi

. $scriptDir/proxy.sh

reposetup="--disablerepo=* --enablerepo=mageia-$buildarch --enablerepo=updates-$buildarch"

cp $scriptDir/startup.sh $rootfsDir/sbin/startup.sh
chmod a+rwx $rootfsDir/sbin/startup.sh
(
dnf --installroot="$rootfsDir" \
    --forcearch="$buildarch" \
    --setopt=install_weak_deps=False --best -v -y \
    --nodocs --allowerasing \
    --releasever="$releasever" \
    --nogpgcheck \
    --refresh \
    install \
    squid \
    openssl \
    distcc-server \
    gcc-c++ \
    nodejs \
    ccache \
    python3-pip
)


buildah run $container -- pip3 install devpi-server --prefix /usr
buildah run $container -- npm install -g git-cache-http-server verdaccio

buildah copy $container $scriptDir/squid.conf /etc/squid
buildah copy $container $scriptDir/storeid.conf /etc/squid

mkdir $rootfsDir/var/spool/ccache
chmod a+rwx $rootfsDir/var/spool/ccache

cat >> $rootfsDir/root/.bashrc <<EOF
export CCACHE_DIR=/var/spool/ccache
export PATH=/usr/lib64/ccache/bin:/bin:/sbin
EOF

rpm --rebuilddb --root $rootfsDir
buildah config --cmd "/sbin/startup.sh" $container
buildah commit --format docker --rm $container $name