{config,lib,pkgs,inputs,...}:{
  # Define a user account. Don't forget to set a password with ‘passwd’.
   programs.git ={
      enable = true;
   };
   users.users.jacob = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
       tree
       discord
       brave
     ];
   };
	home-manager = {
	extraSpecialArgs = {inherit inputs;};
	users = {
		"jacob" = import ./home.nix;
	};
	};
}
