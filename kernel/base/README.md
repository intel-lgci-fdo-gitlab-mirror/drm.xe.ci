## Licensing notes

Files in this directory were created by their respective upstreams.
The license in this repo's root does not apply for those, see upstreams for details.

## Where to get these

- Arch: https://gitlab.archlinux.org/archlinux/packaging/packages/linux/-/blob/main/config
- Ubuntu:
  - Live system: Either from `/boot/config-*`, or from `/proc/config.gz` if it exists.
  - Any kernel from repos: Download the *header* package -> data.tar.xz -> `/usr/src/linux-headers-*/.config`.
- Dragoon: 
  - Custom config based on https://github.com/torvalds/linux -> `make tinyconfig`
  - Manually tuned with `make menuconfig` to boot successfully under QEMU w/ KVM
  - Supports just the basics: ELF files, QEMU serial, initrd, keyboard, TTY
  - Useless for real hardware, useful for testing CI automation and scripting
  - Builds in ~25s on a 24-thread i9-12900 box from scratch, no ccache required!
