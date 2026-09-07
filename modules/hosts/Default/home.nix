{ self, inputs, lib, ... }: {

  flake.homeConfigurations.john = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
    };
    extraSpecialArgs = {
      inherit inputs;
    };
    modules = [
      self.homeModules.johnModule # required
      {
        home = {
		  username = "john";
          homeDirectory = "/home/john";
		};
      }
    ];
  };

  flake.homeModules.johnModule = { pkgs, lib, ... }: {
	# Enter main home manager setting here
    programs.bash.enable = true;
  };
}
