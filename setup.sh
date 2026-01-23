#!/usr/bin/env bash

sudo nixos-rebuild switch --flake /etc/nixos/#$1

git clone https://github.com/jasanz1/.Dotfiles.git ~/.Dotfiles

rm -rf ~/.config

ln -s ~/.Dotfiles/.config ~/.config

git clone https://github.com/jasanz1/Astrovimconfig.git ~/.config/nvim
