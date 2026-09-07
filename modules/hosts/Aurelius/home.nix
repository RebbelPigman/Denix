{ self, inputs, lib, ... }: {

  flake.homeConfigurations.rebbAurelius = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
    };
    extraSpecialArgs = {
      inherit inputs;
    };
    modules = [
      self.homeModules.aureliusHome
      {
        home = {
          username = "rebb";
          homeDirectory = "/home/rebb";
        };
      }
    ];
  };

  flake.homeModules.aureliusHome = { pkgs, inputs, lib, ... }:
  let
    pkgs-unstable = import inputs.nixpkgs-unstable {
      inherit (pkgs) system;
      config.allowUnfree = true;
    };
  in {
    imports = [
      self.homeModules.catfish
      self.homeModules.tela
    ];

    programs.bash.enable = true;
    home = {
      stateVersion = "26.05";
      packages = with pkgs-unstable; [
        neovim
        anki
        google-chrome
        obsidian
        dropbox
        brave
      ];
    };

    programs.fish.shellAliases.python =
      "cd ~/Python && nix-shell --run \"python\"";

    programs.kitty.themeFile = "Catppuccin-Mocha";
  };
}
