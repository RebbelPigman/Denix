{ self, inputs, ... }: {

  flake.nixosModules.myHomeManager = { pkgs, ... }: {
    imports = [
      inputs.home-manager.nixosModules.default
    ];

    home-manager = {
      # false: HM evaluates its own pkgs from nixpkgs-unstable
      # true would pin every home.packages / programs.* package to NixOS stable
      useGlobalPkgs = false;
      useUserPackages = true;
	  backupFileExtension = "backup";
      extraSpecialArgs = {
        inherit inputs;
        pkgs-unstable = import inputs.nixpkgs-unstable {
          inherit (pkgs) system;
          config.allowUnfree = true;
        };
        pkgs-stable = pkgs;
      };
      sharedModules = [
        {
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };
  };

}
