{ self, inputs, ... }: {
  # System packages only. Script settings live in flake.homeModules.karousel
  # (modules/features/user/karousel.nix).
  flake.nixosModules.karousel = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      kdePackages.karousel
      kwin-script-geometry-change
    ];
  };
}
