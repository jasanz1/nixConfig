#!/bin/bash

sudo nixos-rebuild switch --flake /etc/nixos/#default

git clone https://github.com/jasanz1/.Dotfiles.git ~/.Dotfiles

ln -s ~/.Dotfiles/.config ~/.config

git clone https://github.com/jasanz1/Astrovimconfig.git ~/.config/nvim
