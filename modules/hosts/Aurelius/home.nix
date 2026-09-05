{ self, inputs, lib, ... }: {

  flake.homeConfigurations.rebbAurelius = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    extraSpecialArgs = {
      inherit inputs;
      pkgs-unstable = import inputs.nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      pkgs-stable = import inputs.nixpkgs {
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

  flake.homeModules.aureliusHome = { pkgs, lib, ... }: {
    programs.bash.enable = true;
    home = {
      stateVersion = "26.05";
      packages = with pkgs; [
        prismlauncher
        vesktop
        vlc qbittorrent
        kdePackages.kolourpaint
        neovim kitty
        brave google-chrome
        obsidian dropbox anki
      ];
    };

    programs = {
 	  fish = {
        enable = true;
		shellAliases = {
		  ff = "fastfetch";
		  yz = "yazi";
		  vi = "nvim";
		  vim = "nvim";
		  python = "cd ~/Python && nix-shell --run \"python\"";
		  #jupyterlab = "cd ~/Python && nix-shell -p jupyter --run \"jupyter lab\"";
		};
		shellAbbrs = {
		  nixos-test = "nixos-rebuild test --sudo --flake ~/.nixos#Aurelius";
		  nixos-switch = "nixos-rebuild switch --sudo --flake ~/.nixos#Aurelius";
		  git-acp = {
            expansion = "git add -A && git commit -m \"%\" && git push";
            setCursor = true;
          };
		};
        interactiveShellInit = ''
          set fish_greeting # Disable greeting
        '';
        plugins = [ ];
      };
      kitty = {
        enable = true;
	    themeFile = "Catppuccin-Mocha";
 	    settings = {
 		  font_family = "BlexMono Nerd Font Mono";
 		  bold_font = "auto";
          italic_font = "auto";
          clear_all_shortcuts = "yes";
          confirm_os_window_close = 0;
          shell_integration = "enabled";
 		  shell = "fish";
          enabled_layouts = "tall";
        };
   	    extraConfig = ''
   		  include themes/noctalia.conf
          map control+shift+v paste_from_clipboard
          map control+shift+c copy_to_clipboard
          map alt+j next_window
   		  map alt+k previous_window
   		  map alt+h previous_tab 
   		  map alt+l next_tab 
   		  map alt+control+h move_tab_backward
   		  map alt+control+l move_tab_forward
   		  map alt+control+j move_window_forward
		  map alt+control+k move_window_backward
   		  map control+shift+t set_tab_title 
   		  map alt+t new_tab 
   		  map alt+q close_tab
   		  map alt+v launch --location=split
		  map alt+y launch yazi
		  map alt+b launch lynx
		  map alt+return launch nvim
        '';
	  };
    };
  };
}
