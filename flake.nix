{
  description = "Nix flake";

  inputs = {
    # NixOS + system packages (desk, game, niri wrapper, …)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Home Manager user packages (home.packages, programs.*)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Module API stays on the 26.05 release; package set is unstable.
    # Bare github:nix-community/home-manager tracks master (26.11+).
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
}
