<p align="center">
  <a href="https://bazzite.gg/"><img src="/repo_files/kokoplay-logo.svg?raw=true" alt="KokoPlay"/></a>
</p>

# KokoPlay

A custom Fedora Atomic image designed for gaming, development and daily use.
Primary goal is gaming OS which will better fit my needs.
Work in progress. 

## Base System

It is based on Bazzite 44 (KDE version)

## Features

It adds certain aplications by default in OS to avoid flatpak or distrobox installs.
For example Brave Browser only as native installation supports KeePassXC plugin properly.
It fixes no text issue on native Brave Brower or VSCode installation (based on Electron).
It integrates bjnp-cups for access to cannon printers over net. 
There are some other apps included by default such as:
    -android-tools 
    -vscode
    -aria2 
    -bchunk 
    -bleachbit 
    -fuse-btfs 
    -fuse-devel 
    -fuse3-devel 
    -neovim 
    -nmap 
    -util-linux 
    -wireshark 
    -thefuck 
    -yakuake 
    -yt-dlp
    -kleopatra
    -keepassxc
    -alien
    -rclone
    -faugus-launcher
    -cockpit
    -opensnitch

Lutris is removed in flavor of faugus launcher.

It also adds just files to install selected flatpaks and brews.
It adds support to map directories from Local NAS and mount them during boot. 
Proton drive support added (alpha). 
Now you can mount proton disk manually or automatically during boot.
Plan is to add support for sync and backup features, so it is work in progress.
Read me file will be updated during progress.
(Update: Proton started to use captcha which rclone does not support.
Proton Drive may not be usable anymore.)

Just recipes:

 - [kokoPlay]
 - kokoplay-install-brews                            # Install selected Homebrews
 - kokoplay-install-flatpaks                         # Install selected Flatpaks apps
 - kokoplay-install-nas                              # Install local NAS support parameters
 - kokoplay-mount-cifs-sudo                          # Make NAS mountable without root password during boot
 - kokoplay-mount-dir                                # Mount additional directory to installed local NAS [alias: kpmd]
 - kokoplay-randomize-mac-always                     # Randomize wifi mac
 - kokoplay-randomize-mac-never                      # Do not randomize wifi mac

 - [kokoPlay-Certilia]
 - kokoplay-certilia-brave-setup                     # Install and configure certilia (CRO) with Brave browser in docker container
 - kokoplay-certilia-firefox-setup                   # Install and configure certilia (CRO) with Firefox in docker container
 - kokoplay-certilia-remove                          # Remove certilia docker container and delete image

 - [kokoPlay-proton]
 - kokoplay-proton-cleanup                           # Proton drive clean up and reset
 - kokoplay-proton-create-secret                     # Proton drive encrypted DB creation for credentials [alias: pcs]
 - kokoplay-proton-help                              # Proton drive help
 - kokoplay-proton-mount                             # Proton drive mount
 - kokoplay-proton-mount-on-boot                     # Proton drive set mount on boot
 - kokoplay-proton-mount-on-boot-disable             # Proton drive set mount on boot disable
 - kokoplay-proton-rclone-config                     # Proton drive remote configuration
 - kokoplay-proton-rclone-config-delete              # Proton drive rclone config delete
 - kokoplay-proton-unmount                           # Proton drive unmount

 There is kokoplay config GUI app in Menu for ujust commands above.


## Installing the image

There are installation disk images "install.iso" available for download.

For AMD or Intel GPU use
<https://sourceforge.net/projects/kokoplayos/files/Releases/amd/>

Use latest release available, for example, in subdirectory 1.0.9:
<https://sourceforge.net/projects/kokoplayos/files/Releases/amd/1.0.9/bootiso/install.iso>

For nvidia legacy GPU up to 10xx GTX use latest image from
<https://sourceforge.net/projects/kokoplayos/files/Releases/nvidia/>

For nvidia RTX 20xx and newer use latest image from
<https://sourceforge.net/projects/kokoplayos/files/Releases/nvidia-open/>

Every image has sha256.txt for verification.

Please use Fedora Image Writer to make bootable ISO disk and install KokoPlay OS.

OR rebase from any KDE universal blue image via

```bash
sudo bootc switch ghcr.io/kokodroid/kokoplay:latest
```

```bash
sudo bootc switch ghcr.io/kokodroid/kokoplay-nvidia:latest
```

```bash
sudo bootc switch ghcr.io/kokodroid/kokoplay-nvidia-open:latest
```

If you rebase from other image please apply kokoplay theme manually with layout option to get
transparent panel.
If you have installed kokoplay via ISO disk please update immediatelly to latest version 
by clicking on "System update".
ISO disks will be updated on major changes only.

## Verification

Image is signed via cosign key.

## Acknowledgments

This project is based on the Universal Blue image template and builds upon the great work of the Universal Blue community.

## Disclaimer

This software comes with no warranty. Use on your own responsibility.

