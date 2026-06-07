{ self, inputs, ... }: {
  
  flake.nixosModules.niri = {pkgs, lib, ...}: {
    programs.niri = {
      enable = true;
	  package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };
  };
  
  perSystem = { pkgs, lib, ... }: {
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      settings = {
	    environment = {
          QT_QPA_PLATFORMTHEME = "qt6ct";
          QT_QPA_PLATFORM = "wayland;xcb";
          GTK_THEME = "adw-gtk3-dark";
          GTK_USE_PORTAL = "1";
      # QT_STYLE_OVERRIDE = "kvantum";
		};	
		spawn-at-startup = [
          (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.myNoctalia)
		  "dropbox"
        ];
		xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

		input = {
		  keyboard.xkb = {
		    layout = "us";
            options = "caps:swapescape,compose:ralt,numpad:mac";
		  };
		  touchpad = {
		    tap = {};
			natural-scroll = {};
			accel-speed = 0.2;
		  };
		  warp-mouse-to-focus = {};
		  focus-follows-mouse = {};
		};
		cursor = {
		  xcursor-theme = "Kitty";
          xcursor-size = 24;
		  hide-when-typing = {};
		  hide-after-inactive-ms = 3000;
		};

		layout = {
#		  empty-workspace-above-first = {};
		  always-center-single-column = {};
		  center-focused-column = "on-overflow";
		  default-column-width.proportion = 0.7;
		  focus-ring = {
		    width = 3;
			inactive-color = "#1e1e2e";
			active-color = "#cba6f7";
		  };
		  gaps = 12;
		};

		overview = {
		  backdrop-color = "#181825";
		  workspace-shadow.off = {};
		};

		hotkey-overlay.skip-at-startup = {};
		prefer-no-csd = {};
		animations.slowdown = 0.5;
		gestures.hot-corners.top-right = {};

		workspaces = {
#		  "¹󰄛" = {};
#		  "²" = {};
#		  "³󱌧" = {};
#		  "⁴" = {};
#		  "⁵" = {};
#		  "⁶󰭟" = {};
		  "1-Game" = {};
		  "2-Web" = {};
		  "3-Term" = {};
		  "4-Work" = {};
		  "5-Other" = {};
		  "6-Stash" = {};
#		  "01-Term" = { name = "󰄛"; };
#		  "02-Web" = { name = ""; };
#		  "03-Game" = { name = "󱌧"; };
#		  "04-Work" = { name = ""; };
#		  "05-Other" = { name = ""; };
#		  "06-Stash" = { name = "󰭟"; };
		};

		window-rules = [ 
  		  {
  		    geometry-corner-radius = 12;
			clip-to-geometry = true;
          }
	      {
            matches = [ { app-id = "^kitty$"; } ];
            open-floating = true;
			opacity = 0.90;
            default-column-width.proportion = 0.60;
            default-window-height.proportion = 0.80;
          } 
		  {
		    matches = [ 
			  { app-id = "^brave-browser$"; }
			  { app-id = "^google-chrome$"; }
			];
            default-column-width.proportion = 0.80;
			open-on-workspace = "2-Web";
		  }
		  {
		    matches = [ { app-id = "^obsidian$"; } ];
			open-maximized-to-edges = true;
			open-on-workspace = "4-Work";
			opacity = 0.90 ;
		  }
		];
		binds = {
		  "Print".screenshot = {};
		  "Mod+Return".spawn = lib.getExe pkgs.kitty;
		  "Mod+D".spawn = lib.getExe pkgs.fuzzel;
		  "Mod+Shift+D".spawn-sh = "nix run nixpkgs#noctalia-shell ipc call launcher toggle";
          "Mod+S".spawn-sh = "nix run nixpkgs#noctalia-shell ipc call controlCenter toggle";
          "Mod+Alt+L".spawn-sh = "nix run nixpkgs#noctalia-shell ipc call lockScreen lock";
		  "Mod+B".spawn = "brave";
		  "Mod+E".spawn-sh = "kitty yazi";
		  "Mod+I".spawn = "obsidian";
		  "Mod+Q".close-window = {};
		  "Mod+Shift+Q".quit = {};
		  "Mod+O".toggle-overview = {};
		  "Mod+H".focus-column-left = {};
		  "Mod+L".focus-column-right = {};
		  "Mod+Ctrl+H".move-column-left = {};
		  "Mod+Ctrl+L".move-column-right = {};
		  "Mod+Shift+H".consume-or-expel-window-left = {};
		  "Mod+Shift+L".consume-or-expel-window-right = {};
		  "Mod+K".focus-window-or-workspace-up = {};
		  "Mod+J".focus-window-or-workspace-down = {};
          "Mod+Ctrl+K".move-window-up-or-to-workspace-up = {};
          "Mod+Ctrl+J".move-window-down-or-to-workspace-down = {};
		  "Mod+1".focus-workspace = 1;
		  "Mod+2".focus-workspace = 2;
		  "Mod+3".focus-workspace = 3;
		  "Mod+4".focus-workspace = 4;
		  "Mod+5".focus-workspace = 5;
		  "Mod+Space".toggle-window-floating = {};
		  "Mod+Alt+Space".switch-focus-between-floating-and-tiling = {};
		  "Mod+Minus".set-column-width = "-20%";
		  "Mod+Equal".set-column-width = "+20%";
		  "Mod+Alt+V".set-column-width = "30%";
		  "Mod+V".set-column-width = "50%";
		  "Mod+Shift+V".set-column-width = "60%";
		  "Mod+Shift+ALt+V".set-column-width = "70";
		  "Mod+Ctrl+V".set-column-width = "80%";
		  "Mod+Alt+F".set-column-width = "100%";
		  "Mod+F".maximize-window-to-edges = {};
		  "Mod+Shift+F".fullscreen-window = {};
		  "XF86AudioRaiseVolume".spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+";
		  "XF86AudioLowerVolume".spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-";
          "XF86AudioMute".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86AudioMicMute".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          "XF86MonBrightnessUp".spawn-sh = "brightnessctl --class=backlight set +5%";
          "XF86MonBrightnessDown".spawn-sh = "brightnessctl --class=backlight set 5%-";
        };
      };
    };
  };
}

