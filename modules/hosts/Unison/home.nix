{ self, inputs, lib, ... }: {

  flake.homeConfigurations.rebbUnison = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    extraSpecialArgs = {
      inherit inputs;
    };
    modules = [
      self.homeModules.unisonHome
      {
        home = {
          username = "rebb";
          homeDirectory = "/home/rebb";
        };
      }
    ];
  };

  flake.homeModules.unisonHome = { pkgs, inputs, lib, ... }:
  let
    pkgs-unstable = import inputs.nixpkgs {
      inherit (pkgs) system;
      config.allowUnfree = true;
    };
  in {
    imports = [
      self.homeModules.catfish
      self.homeModules.tela
      self.homeModules.hermes
      self.homeModules.jupyter
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
