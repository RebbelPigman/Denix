{ self, inputs, ... }: {

  flake.nixosConfigurations.Unison = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.unisonConfiguration
	];
  };

}
