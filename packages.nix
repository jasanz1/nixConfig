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
		erlang
 		elixir
 		rebar3
		#text editing
		vim
		neovim
		vimer
		tmux
		tmux-sessionizer
		bash
		bc
		coreutils
		gawk
		git
		jq
		playerctl
		#other
		dolphin
		mpv
		qutebrowser
		wget
		htop
		konsole
		git
		];

}
