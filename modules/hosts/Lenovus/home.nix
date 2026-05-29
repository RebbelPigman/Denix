{ self, inputs, lib, ... }: {

  flake.homeConfigurations.rebb = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
    modules = [
      self.homeModules.rebbModule
#      self.homeModules.kitty
#      self.homeModules.nemo
      {
        home = {
		  username = "rebb";
          homeDirectory = "/home/rebb";
		};
      }
    ];
  };

  flake.homeModules.rebbModule = { pkgs, lib, ... }: {
    programs.bash.enable = true;
    home = {
      stateVersion = "26.05";
      packages = with pkgs; [
		brave neovim anki
		dropbox obsidian google-chrome # non free
	  ];
    };
	gtk = {
      enable = true;
#      colorScheme = "dark";
	  iconTheme = {
		name = "Tela-Circle";
		package = pkgs.tela-circle-icon-theme;		
	  };
	};

#kitty module content
    programs = {
 	  fish = {
        enable = true;
		shellAliases = {
		  ff = "fastfetch";
		  yz = "yazi";
		  vi = "nvim";
		  vim = "nvim";
		};
		shellAbbrs = {
		  nixos-test = "nixos-rebuild test --sudo --flake ~/.nixos#Lenovus";
		  nixos-switch = "nixos-rebuild switch --sudo --flake ~/.nixos#Lenovus";
		};
        interactiveShellInit = ''
          set fish_greeting # Disable greeting
        '';
        plugins = [
          { name = "grc"; src = lib.getExe' pkgs.fishPlugins.grc.src "grc"; }
        ];
      };
      kitty = {
        enable = true;
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
          map alt+j scroll_line_down 
   		  map alt+k scroll_line_up 
   		  map alt+t new_tab 
   		  map alt+q close_tab
   		  map alt+h previous_tab 
   		  map alt+l next_tab 
   		  map control+alt+h move_tab_backward
   		  map control+alt+l move_tab_forward
   		  map control+shift+t set_tab_title 
		  map control+k neighboring_window up
		  map control+j neighboring_window down
		  map control+h neighboring_window left
		  map control+l neighboring_window right
   		  map alt+control+k move_window up
   		  map alt+control+j move_window down
   		  map alt+control+h move_window left
   		  map alt+control+l move_window right
   		  map alt+v launch --location=split
		  map alt+y launch yazi
		  map alt+b launch lynx
		  map alt+return launch nvim
        '';
	  };
    };
  };
}
