{ self, inputs, lib, ... }: {

  flake.homeConfigurations.rebb = inputs.home-manager.lib.homeManagerConfiguration {
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
      self.homeModules.rebbModule
      {
        home = {
          username = "rebb";
          homeDirectory = "/home/rebb";
        };
      }
    ];
  };

  flake.homeModules.rebbModule = { pkgs, pkgs-unstable, lib, ... }: {
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

    programs.fish = {
      shellAbbrs.git-acp.position = "anywhere";
      interactiveShellInit = ''
        if status is-interactive && command -q fastfetch
          fastfetch
        end
      '';
      plugins = [
        { name = "grc"; src = pkgs.fishPlugins.grc.src; }
      ];
    };
  };
}
