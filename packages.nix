{config,lib, pkgs,...}:
{
	environment.systemPackages = with pkgs;[
		# programing
		gcc
		cargo
		rustc
		go
		nodejs_22
		ripgrep
		lazygit
		gdu
		bottom
		python3
		tree-sitter  		
		gh
		gleam
		#text editing
		vim
		neovim
		tmux
		bash
		bc
		coreutils
		gawk
		git
		jq
		playerctl
		#other
		dolphin
		wget
		htop
		konsole
		git
		];

}
