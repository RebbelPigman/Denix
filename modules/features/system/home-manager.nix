{ self, inputs, ... }: {

  flake.nixosModules.myHomeManager = { pkgs, ... }: {
    imports = [
      inputs.home-manager.nixosModules.default
    ];

    home-manager = {
      # false: HM evaluates its own pkgs from the home-manager input's nixpkgs
      # true would pin every home.packages / programs.* package to the NixOS pkgs set
      useGlobalPkgs = false;
      useUserPackages = true;
      backupFileExtension = "backup";
      extraSpecialArgs = {
        inherit inputs;
      };
    };
  };

}
