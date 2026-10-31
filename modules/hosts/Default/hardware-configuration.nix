{ self, inputs, ... }: {

  flake.nixosModules.defaultHardware = { config, lib, pkgs, modulesPath, ... }: {
    # Paste filesystem / initrd here. hostPlatform is the minimum so the attr evaluates.
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
