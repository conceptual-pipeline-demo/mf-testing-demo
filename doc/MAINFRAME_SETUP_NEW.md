[TOC]

## Technology

- [UTM](https://mac.getutm.app/)
  Virtual machines for Mac. Free, supports both arm / amd architecture
- [Hercules](http://www.hercules-390.eu/)
  Hercules is an open source software implementation of the mainframe System/370 and ESA/390 architectures, in addition
  to the latest 64-bit z/Architecture. Hercules runs under Linux, Windows, Solaris, FreeBSD, and Mac OS X.
- [MVS 3.8j Turnkey 4- System](https://wotho.pebble-beach.ch/tk4-/) ([Github](https://github.com/mainframed/tk4/tree/main))
  Operation system built to run under Hercules emulator
- [x3270](http://x3270.bgp.nu/)
  Terminal emulator that runs over a TELNET connection. Runs on most Unix-like operation systems (in our case Mac OS)

## Download and install virtual machine

### UTM

Download and install UTM virtual machine https://mac.getutm.app/

> Note: UTM is chose over Virtualbox since it is designed to be compatible to Apple Silicon and supports multiple OS
> architecture.

### Ubuntu Server distribution

Download Ubuntu Server for arm ISO image from https://ubuntu.com/download/server

The LTS version used in this demo is `ubuntu-24.04-live-server-arm64`. Download
link: https://ubuntu.com/download/server/arm

> Note: The ARM architecture distribution has a better compatilibility to OSX however demands a local build of Hercules
> binaries and MVS binaries in later stages. I was able to build Hercules but failed to run MVS TK4- in aarch64
> compatible
> mode. So switched to MVS TK5 from Rob Prins instead.

### Install and start the VM

Create a new virtual machine using the ISO image downloaded. Bootstraping the OS following the stpes. The default
network mode is "shared network", which is similar to NAT. Keep it the default option and it should configure the
netcard automatically when bootstraping.

Continue the installation with default settings except for OnenSSH. It is preferred to install OpenSSH so that we can
ssh into the virtual host from our OSX terminal, which is little more friendly than the UTM window.

After all packages are installed, the boot program will attempt to restart the system. If the system freezes on reboot,
that might because the VM is waiting the ISO to be unmounted. Try selecting the disk icon on top right and click "eject"
CD/DVD ISO. Then restart the VM by clicking the backward play button on the top left.

If everything goes right, the session should ask you to provide username and password to login with the password set
earlier.

```bash
# Then insetall net tools 
sudo apt-get install net-tools
# get IP address, in my case, 192.168.64.4
ifconfig
```

```bash
# I prefer to use my iTerm terminal + ssh for better searching / multi-pane visual. 
# Switch back to OSX iTerm now we should be able to ssh to the vm
# I'm using my github private key as the public key were loaded form github when bootstraping
ssh -i ~/.ssh/github/github ubuntu@192.168.64.4
```

## Install Hercules

Detailed instruction is available here: https://sdl-hercules-390.github.io/html/hercinst.html. All of the steps listed
below are a over-simplified version of the official instruction. Please don't hesitate to go back to official guide if
anything doesn't work.

1. Building from source (as it is risky to used the pre-compiled binaries)
   ```bash
   # Step 0, install required packages
   sudo apt-get -y install git wget time
   sudo apt-get -y install build-essential cmake flex gawk m4 autoconf automake libtool-bin libltdl-dev
   sudo apt-get -y install libbz2-dev zlib1g-dev
   sudo apt-get -y install libcap2-bin
   
   # Step 1, clone the source code repository
   mkdir -p /home/ubuntu/hercules
   cd hercules
   git clone https://github.com/SDL-Hercules-390/hyperion.git
   ```

2. Verify you have all of the correct versions of the more important packages installed:

   ```bash
   # Step 2, check the environment before source build
   cd hyperion
   ./util/bldlvlck
   ```

3. Build the external packages
   Note, this step is mandatory for a non-Intel x86/x64 architecture build, and is supposed to be optional in our cases.
   But for safety, we still run a manually build for each of the external packages in order to create the static link
   libraries that Hercules will need to link with

    - The external packages are:

        - crypto: https://github.com/sdl-hercules-390/crypto.git

        - decNumber: https://github.com/sdl-hercules-390/decNumber.git

        - SoftFloat: https://github.com/sdl-hercules-390/SoftFloat.git

        - telnet: https://github.com/sdl-hercules-390/telnet.git

   ```bash
   # Step 3, build external packages
   
   mkdir -p /home/ubuntu/hercules/extpkgs
   cd ~/hercules/extpkgs
   
   # clone the repository
   git clone https://github.com/SDL-Hercules-390/gists.git
   cd gists/
   
   # update configurations if needed. 
   # cpu type should be changed to aarch64 when building for arm architecture.
   vim extpkgs.sh.ini
   
   # the installation script will clone ext packages and build for us
   ./extpkgs.sh clone c d s t
   
   # update LIBRARY_PATH and CPATH to include the ext binaries
   echo 'export LIBRARY_PATH=/home/ubuntu/hercules/extpkgs/gists/lib:$LIBRARY_PATH' >> ~/.bashrc
   echo 'export CPATH=/home/ubuntu/hercules/extpkgs/gists/include:$CPATH' >> ~/.bashrc
   source ~/.bashrc
   ```

4. configure and build hercules
   ```bash
   cd /home/ubuntu/hercules/hyperion
   
   # the enable-extpkgs flag specifies the location where to fin ext packages. This is redundant to the LIBRARY_PAHT CPATH env variable. Doesn't harm to add here though
   ./configure --enable-extpkgs=/home/ubuntu/hercules/extpkgs/gists
   
   # Build
   # This step takes ~2 hours under the emulated amd architecture
   # It should be fairly fast under arm architecture virtual machine, a few minutes only
   make
   ```

5. Install the program
   ```bash
   # Install the program
   sudo make install
   
   # Add libherc.so library path to LD_LIBRARY_PATH
   echo 'export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
   source ~/.bashrc
   ```

6. Now we should be able to run Hercules
   ```bash
   sudo ./hercules
   sudo ./herclin
   
   # Or, run anywhere with .cnf file provided as an absolute path
   cd /home/ubuntu
   herclin -f /home/ubuntu/hercules/hyperion/hercules.cnf
   ```

   The user guide, and differences between `hercules` and `herclin` excutables can bd
   found [here](https://sdl-hercules-390.github.io/html/hercinst.html). Short version, `hercules` is the semi-graphical
   panel, `herclin` is the standard command-line style without a "fancy" dashboard.

Congratulations! We're done with Hercules.

## Install MVS TK5 OS

What is MVS TK5: https://www.prince-webdesign.nl/index.php/software/mvs-3-8j-turnkey-5
Instruction and user manual can be found on the above link.

> Note:
> For some unknown reason TK5 package doesn't work for me in amd64 OS.
> Choosing TK5 over TK4- as we're installing on an Ubuntu arm OS

```bash
# download the pre-built zip of tk5 
# or download to your pc and scp to the vm
sudo apt-get install unzip
wget --no-check-certificate https://www.prince-webdesign.nl/images/downloads/mvs-tk5.zip
unzip mvs-tk5.zip

# set it to console mode so it allows us to run command at the console
# IMPORTANT, run ./set_console_mode script IN unattended directory. Otherwise the generated mode file will not be recognized
cd mvs-tk5
chmod -R +x ./*
cd unattended
./set_console_mode
```

```bash
# Run MVS
# The script is smart enough to pick up the correct ver excutable based on you OS architecture
# wait ~3 minutes until you see the TK5 screen
./mvs
```

![image-TK5-console](./images/TK5-console.png)

## Connect via 3270 terminal

I prefer to install the 3270 terminal on my OSX system as it will be easier to setup and faster execution. Also
Potentially more friendly for future automation.

Start another terminal window and

```bash
# Install x3270 client
brew install x3270
```

```
# Connect to Hercules
c3270 192.168.64.4:3270
```

> Interestingly, x3270 executable (the graphical UI) doesn't come in the Homebrew x3270 package...
> The ‘x’ in the name indicates X Window System. Which is no longer compatible on macOS. Because of this, the Homebrew
> x3270 package no longer comes with the x3270 X Window System executable. It comes with c3270 instead.

![TK5_c3270_login](./images/TK5_c3270_login.png)

Click 'Enter' and login with the default user (More info about the deafult users, refer
to [TK5 user guide](https://www.prince-webdesign.nl/images/downloads/TK5-Introduction-and-User-ManualTSOLOGON%20REJECTED.%20USERID,%20HERC01,IN%20USE.pdf))

```properties
username=herc01
password=CUL8TR
```

Finally, we're in

![TK5_logged_in](./images/TK5_logged_in.png)

## Run a demo

Now, can follow the step to step instructions in this
blog: https://bradrigg456.medium.com/run-your-own-mainframe-using-hercules-mainframe-emulator-and-mvs-3-8j-tk4-e8a85ebecd62
to send your first COBOL task to mainframe.

To be continued...