#!/usr/bin/bash


apt-get install -y \
   curl \
   wget \
   btrfs-progs \
   git \
   go-md2man \
   iptables \
   libassuan-dev \
   libbtrfs-dev \
   libc6-dev \
   libdevmapper-dev \
   libglib2.0-dev \
   libgpgme-dev \
   libgpg-error-dev \
   libprotobuf-dev \
   libprotobuf-c-dev \
   libseccomp-dev \
   libselinux1-dev \
   libsystemd-dev \
   pkg-config \
   make \
   libapparmor-dev \
   gcc \
   cmake \
   uidmap \
   libostree-dev \
   slirp4netns

wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source ~/.bash_profile

git clone https://github.com/containers/conmon
cd conmon
export GOCACHE="$(mktemp -d)"
make
make podman

git clone https://github.com/opencontainers/runc.git $GOPATH/src/github.com/opencontainers/runc
cd $GOPATH/src/github.com/opencontainers/runc
make BUILDTAGS="selinux seccomp"
cp runc /usr/bin/runc

git clone https://github.com/containernetworking/plugins.git $GOPATH/src/github.com/containernetworking/plugins
cd $GOPATH/src/github.com/containernetworking/plugins
./build_linux.sh
sudo mkdir -p /usr/libexec/cni
sudo cp bin/* /usr/libexec/cni

sudo mkdir -p /etc/cni/net.d
curl -qsSL https://raw.githubusercontent.com/containers/libpod/master/cni/87-podman-bridge.conflist | sudo tee /etc/cni/net.d/99-loopback.conf

mkdir -p /etc/containers
curl -L -o /etc/containers/registries.conf https://src.fedoraproject.org/rpms/containers-common/raw/main/f/registries.conf
curl -L -o /etc/containers/policy.json https://src.fedoraproject.org/rpms/containers-common/raw/main/f/default-policy.json


TAG=$(curl -s https://api.github.com/repos/containers/podman/releases/latest|grep tag_name|cut -d '"' -f 4)
rm -rf podman*
wget https://github.com/containers/podman/archive/refs/tags/${TAG}.tar.gz
tar xvf ${TAG}.tar.gz
cd podman*/
make BUILDTAGS="selinux seccomp"
make install PREFIX=/usr
