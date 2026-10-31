{ self, inputs, lib, ... }: {

  flake.homeConfigurations.rebbAurelius = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      # legacy `system` is rewritten to localSystem. Do not pass `system`.
      localSystem = "x86_64-linux";
      config.allowUnfree = true;
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

  flake.homeModules.aureliusHome = { pkgs, inputs, lib, ... }: {
    imports = [
      self.homeModules.catfish
      self.homeModules.tela
      self.homeModules.jupyter
      self.homeModules.grokbot
    ];

    programs.bash.enable = true;
    home = {
      stateVersion = "26.05";
      packages = with pkgs; [
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
