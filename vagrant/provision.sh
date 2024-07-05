#!/usr/bin/env bash

set -xeuo pipefail

export TK5_RC="/etc/profile.d/tk5rc.sh"
sudo touch "${TK5_RC}"
sudo chmod 755 "${TK5_RC}"

echo 'alias l="ls -al --color=auto"' | sudo tee -a "${TK5_RC}"

export GROUP_ID=1000
export USER_ID=1000
export APP_ROOT="/app"
export HERCULES_ROOT="${APP_ROOT}/hercules"
export HERCULES_EXT_PKG="${HERCULES_ROOT}/extpkgs"
export MVS_TK5_ROOT="${APP_ROOT}/mvs-tk5"

sudo apt-get update
sudo NEEDRESTART_MODE=a apt-get -y -q install git wget time
sudo NEEDRESTART_MODE=a apt-get -y -q install build-essential cmake flex gawk m4 autoconf automake libtool-bin libltdl-dev
sudo NEEDRESTART_MODE=a apt-get -y -q install libbz2-dev zlib1g-dev
sudo NEEDRESTART_MODE=a apt-get -y -q install libcap2-bin
sudo NEEDRESTART_MODE=a apt-get -y -q install c3270 unzip

sudo mkdir -p "${APP_ROOT}"
sudo chown -R "${USER_ID}:${GROUP_ID}" "${APP_ROOT}"

mkdir -p "${HERCULES_ROOT}"
pushd "${HERCULES_ROOT}"
git clone https://github.com/SDL-Hercules-390/hyperion.git

"${HERCULES_ROOT}/hyperion/util/bldlvlck"

mkdir -p "${HERCULES_EXT_PKG}"
pushd "${HERCULES_EXT_PKG}"

# clone the repository
git clone https://github.com/SDL-Hercules-390/gists.git
pushd "${HERCULES_EXT_PKG}/gists/"
sed -i 's/cpu             =  x86/cpu             =  aarch64/g' "${HERCULES_EXT_PKG}/gists/extpkgs.sh.ini"

# the installation script will clone ext packages and build for us
./extpkgs.sh clone c d s t

# update LIBRARY_PATH and CPATH to include the ext binaries
echo "export LIBRARY_PATH=${HERCULES_EXT_PKG}/gists/lib" | sudo tee -a "${TK5_RC}"
echo "export CPATH=${HERCULES_EXT_PKG}/gists/include" | sudo tee -a "${TK5_RC}"
export LIBRARY_PATH="${HERCULES_EXT_PKG}/gists/lib"
export CPATH="${HERCULES_EXT_PKG}/gists/include"

pushd "${HERCULES_ROOT}/hyperion"

# the enable-extpkgs flag specifies the location where to fin ext packages. This is redundant to the LIBRARY_PAHT CPATH env variable. Doesn't harm to add here though
./configure --enable-extpkgs="${HERCULES_EXT_PKG}/gists"

# Build
# This step is pretty fast under arm architecture virtual machie. However it takes ~2 hours under the emulated amd architecture
make

sudo make install

# Add libherc.so library path to LD_LIBRARY_PATH
echo 'export LD_LIBRARY_PATH=/usr/local/lib' | sudo tee -a "${TK5_RC}"
export LD_LIBRARY_PATH=/usr/local/lib

# sudo ./hercules
# sudo ./herclin
# herclin -f "${HERCULES_ROOT}/hyperion/hercules.cnf"

pushd /tmp
wget --no-check-certificate https://www.prince-webdesign.nl/images/downloads/mvs-tk5.zip
unzip mvs-tk5.zip
mv mvs-tk5 "${MVS_TK5_ROOT}"

# set it to console mode so it allows us to run command at the console
pushd "${MVS_TK5_ROOT}"
chmod -R +x ./*

echo "CONSOLE" > "${MVS_TK5_ROOT}/unattended/mode"

sudo chown -R "${USER_ID}:${GROUP_ID}" "${APP_ROOT}"
