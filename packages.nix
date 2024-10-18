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
		erlang_27
 		elixir
 		rebar3
 		zig
		lua-language-server
		gnumake
		cmake
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
		xclip
		qutebrowser
		wget
		htop
		konsole
		git
		];

}
