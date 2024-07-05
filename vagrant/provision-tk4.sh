#!/usr/bin/env bash

set -xeuo pipefail
export BASHRC_PATH="/home/vagrant/.bashrc"

echo 'alias l="ls -al --color=auto"' >> ~/.bashrc
alias l="ls -al --color=auto"

export GROUP_ID=1000
export APP_ROOT="/app"
export HERCULES_ROOT="${APP_ROOT}/hercules"
export HERCULES_EXT_PKG="${HERCULES_ROOT}/extpkgs"
export MVS38_ROOT="${APP_ROOT}/mvs38"

sudo apt-get update
sudo NEEDRESTART_MODE=a apt-get -y -q install git wget time
sudo NEEDRESTART_MODE=a apt-get -y -q install build-essential cmake flex gawk m4 autoconf automake libtool-bin libltdl-dev
sudo NEEDRESTART_MODE=a apt-get -y -q install libbz2-dev zlib1g-dev
sudo NEEDRESTART_MODE=a apt-get -y -q install libcap2-bin
sudo NEEDRESTART_MODE=a apt-get -y -q install c3270 unzip

sudo mkdir -p "${APP_ROOT}"

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
echo "export LIBRARY_PATH=${HERCULES_EXT_PKG}/gists/lib" >> "${HOME}/.bashrc"
echo "export CPATH=${HERCULES_EXT_PKG}/gists/include" >> "${HOME}/.bashrc"
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
echo 'export LD_LIBRARY_PATH=/usr/local/lib' >> ~/.bashrc
export LD_LIBRARY_PATH=/usr/local/lib

# sudo ./hercules
# sudo ./herclin
# herclin -f "${HERCULES_ROOT}/hyperion/hercules.cnf"

pushd /tmp
wget --no-check-certificate https://wotho.pebble-beach.ch/tk4-/tk4-_v1.00_current.zip
unzip tk4-_v1.00_current.zip -d "${MVS38_ROOT}"

# set it to console mode so it allows us to run command at the console
pushd "${MVS38_ROOT}"

echo "CONSOLE" > "${MVS38_ROOT}/unattended/mode"

sed -i 's/if [[ ${a:0:3} == '\''arm'\'' ]];then/if [[ ${a:0:3} == "arm" ]] || [[${a:0:5} == "aarch"]];then/g' "${MVS38_ROOT}/mvs"

cat <<EOT > "${MVS38_ROOT}/mvs_aarch"
#!/bin/bash
#**********************************************************************
#***                                                                ***
#*** Script:  mvs                                                   ***
#***                                                                ***
#*** Purpose: IPL OS/VS2-MVS 3.8j (TK4- unattended operations)      ***
#***                                                                ***
#*** Updated: 2014/12/22                                            ***
#***                                                                ***
#**********************************************************************
#
# set environment
#
a=\`uname -m\`
if [[ \${a:0:3} == 'arm' ]] || [[ \${a:0:5} == 'aarch' ]];then
   hf=\`readelf -A /proc/self/exe | grep Tag_ABI_VFP_args\`
   if [[ \${hf:2:3} == 'Tag' ]];then arch='arm';else arch='arm_softfloat';fi
else if [[ \$a == 'x86_64' ]];then arch=64;else arch=32;fi;fi
system=\`uname -s | awk '{print tolower(\$0)}'\`
case \$system in
linux)
   force_arch=
   export LD_LIBRARY_PATH=hercules/\$system/\$arch/lib:hercules/\$system/\$arch/lib/hercules:\$LD_LIBRARY_PATH
   ;;
darwin)
   if [[ \$arch == '32' ]];then force_arch='arch -arch i386';else force_arch=;fi
   export DYLD_LIBRARY_PATH=hercules/\$system/lib:hercules/\$system/lib/hercules:\$DYLD_LIBRARY_PATH
   ;;
*)
   echo "System \$system not supported."
   exit
   ;;
esac
MODE=\`head -1 unattended/mode 2>/dev/null\`
DAEMON="-d"
if [[ \$MODE == 'CONSOLE' ]]; then unset DAEMON; fi
#
# source configuration variables
#
if [ -f local_conf/tk4-.parm ]; then . local_conf/tk4-.parm; fi
if [[ \${arch:0:3} == 'arm'   && \$REP101A == '' ]];then export REP101A=specific;fi
if [[ \$REP101A == 'specific' && \$CMD101A == '' ]];then export CMD101A=02;fi
#
# IPL OS/VS2-MVS 3.8j
#
export HERCULES_RC=scripts/ipl.rc
\$force_arch hercules \$DAEMON -f conf/tk4-.cnf >log/3033.log
EOT

chmod 755 "${MVS38_ROOT}/mvs_aarch"
#"${MVS38_ROOT}/mvs_aarch"

sudo chown "${USER_ID}:${GROUP_ID}" "${APP_ROOT}"
