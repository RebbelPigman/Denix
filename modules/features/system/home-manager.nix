{ self, inputs, ... }: {

  flake.nixosModules.myHomeManager = { pkgs, ... }: {
    imports = [
      inputs.home-manager.nixosModules.default
    ];

    home-manager = {
      # false: HM evaluates its own pkgs from the home-manager input's nixpkgs
      # (same unstable channel as NixOS; still a separate eval so HM can set allowUnfree)
      useGlobalPkgs = false;
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
