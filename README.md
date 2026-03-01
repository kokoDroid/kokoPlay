<p align="center">
  <a href="https://bazzite.gg/"><img src="/repo_files/kokoplay-logo.svg?raw=true" alt="KokoPlay"/></a>
</p>

# KokoPlay

A custom Fedora Atomic image designed for gaming, development and daily use.
Primary goal is gaming OS which will better fit my needs.
Work in progress. 

## Base System

It is based on Bazzite (KDE version)

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

Lutris is removed in flavor of faugus launcher.

It also adds just files to install more currated flatpaks and brews.
It adds support to map directories from Local NAS and mount them during boot. 
There will be mapping for Proton drive added which is unsupported by Proton on Linux, so it is work in progress.
Read me file will be updated during progress.

Just recipes:
 - [kokoPlay]
 - kokoplay-install-brews                            # Install selected Homebrews
 - kokoplay-install-flatpaks                         # Install selected Flatpaks apps
 - kokoplay-install-nas                              # Install local NAS support and mount persistent directory
 - kokoplay-mount-cifs-sudo                          # Make NAS mountable without root password during boot
 - kokoplay-mount-dir                                # Mount additional directory to installed local NAS


## Using the image

There is installation disk "install.iso" for download

<https://sourceforge.net/projects/kokoplayos/files/Releases/1.0.8/>

Please use Fedora Image Writer to make bootable ISO disk and install KokoPlay OS.

OR install Bazzite image than rebase via

```bash
sudo bootc switch ghcr.io/kokodroid/kokoplay:latest
```
If you rebase from bazzite please apply kokoplay theme manually with layout to get
transparent panel.

## Verification

Image is signed via cosign key.

## Acknowledgments

This project is based on the Universal Blue image template and builds upon the great work of the Universal Blue community.

## Disclaimer

This software comes with no warranty. Use on your own responsibility.

