{config,lib, pkgs,...}:
{
	environment.systemPackages = with pkgs;[
		# programing
		gcc

		#text editing
		vim
		neovim

		#other
		wget
		htop
		konsole
		git
		];

}
