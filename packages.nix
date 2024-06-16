{config,lib, pkgs,...}:
{
	environment.systemPackages = with pkgs;[
		vim
		neovim
		wget
		htop
		konsole
		git
		];

}
