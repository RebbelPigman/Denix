{ self, inputs, ... }: {

  flake.nixosConfigurations.Aurelius = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.aureliusConfiguration
	];
  };

}
