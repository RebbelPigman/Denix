{ self, inputs, ... }: {

  flake.nixosConfigurations.Lenovus = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.lenovusConfiguration
	];
  };

}
