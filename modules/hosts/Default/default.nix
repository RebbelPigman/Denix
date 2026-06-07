{ self, inputs, ... }: {

  flake.nixosConfigurations.Default = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.defaultConfiguration
	];
  };

}
