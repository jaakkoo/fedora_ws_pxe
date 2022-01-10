# Fedora WS PXE boot

A simple make wrapper to fetch fedora ws35 and pxe boot it in qemu-kvm

## Dependencies

- qemu-kvm
- syslinux-nonlinux
- python3

## Usage

`make run` will fetch the image and pxe boot it.

Note! The pxe boot assumes that `virbr0` interface has the ip 192.168.122.1
