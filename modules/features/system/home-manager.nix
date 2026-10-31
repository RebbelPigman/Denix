{ self, inputs, ... }: {

  flake.nixosModules.myHomeManager = { pkgs, ... }: {
    imports = [
      inputs.home-manager.nixosModules.default
    ];

    home-manager = {
      # true: HM uses the NixOS pkgs. core already sets allowUnfree.
      # A second import of the same nixpkgs input is a second eval.
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      # Replace an existing *.backup instead of failing activation
      overwriteBackup = true;
      extraSpecialArgs = {
        inherit inputs;
      };
    };
  };

}
