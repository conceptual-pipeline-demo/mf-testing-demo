[TOC]

## tl;dl

- Create VM
    ```
    brew install qemu
    brew install --cask vagrant
    vagrant plugin install vagrant-qemu
    vagrant up
    ```
- start Mainframe
    ```
    vagrant ssh

    # in the VM
    cd /app/mvs-tk5
    ./mvs
    ```
- connect to Mainframe
    ```
    brew install x3270
    c3270 127.0.0.1:53270
    ```
