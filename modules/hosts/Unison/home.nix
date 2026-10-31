{ self, inputs, lib, ... }: {

  flake.homeConfigurations.rebbUnison = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      # legacy `system` is rewritten to localSystem. Do not pass `system`.
      localSystem = "x86_64-linux";
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

  flake.homeModules.unisonHome = { pkgs, inputs, lib, ... }: {
    imports = [
      self.homeModules.catfish
      self.homeModules.hermes
      self.homeModules.jupyter
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
