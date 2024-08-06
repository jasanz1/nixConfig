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
		#text editing
		vim
		neovim

		#other
		dolphin
		wget
		htop
		konsole
		git
		];

}
