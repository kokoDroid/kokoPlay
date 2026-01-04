# kokoPlay
A custom Fedora Atomic image designed for gaming, development and daily use.
Primary goal is gaming OS which will better fit my needs.
Work in progress. 

# Base System
It is based on Bazzite (KDE version)

# Features

It adds certain aplications by default in OS to avoid flatpak or distrobox installs.
For example Brave Browser only as native installation supports KeePassXC plugin properly.
It fixes no text issue on native Brave Brower or VSCode installation (based on Electron).
It integrates bjnp-cups for access to cannon printers over net. These package is not suported by Fedora any more.
There are many other apps included by default. It also adds just files to install more currated flatpaks and brews.
It adds support to map directories from Local NAS and mount them during boot. 
For now it supports recipe to map one NAS directory. 
There will be mapping for Proton drive added which is unsupported by Proton on Linux, so it is work in progress.
Read me file will be updated during progress.

# Using the image

Install Bazzite image than rebase via

sudo bootc switch ghcr.io/kokodroid/kokoplay:latest

# Verification

Image is signed via cosign key.

# Acknowledgments

This project is based on the Universal Blue image template and builds upon the great work of the Universal Blue community.

