{ self, inputs, lib, ... }: {

  flake.homeConfigurations.rebbAurelius = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
    };
    extraSpecialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
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

  flake.homeModules.aureliusHome = { pkgs, pkgs-unstable, lib, ... }: {
    imports = [
      self.homeModules.catfish
      self.homeModules.plasma
      self.homeModules.karousel
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
