{ self, inputs, ... }: {
  
  flake.nixosModules.niri = {pkgs, lib, ...}: {
    programs.niri = {
      enable = true;
	  package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };

    environment.systemPackages = [ pkgs.tela-circle-icon-theme ];

    # Do not also set home-manager.sharedModules to homeModules.tela.
    # aureliusHome / rebbModule already import it; gtk.iconTheme.package
    # is unique and a second attach fails the rebuild.
  };
  
  perSystem = { pkgs, lib, ... }: {
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      settings = {
	    environment = {
          QT_QPA_PLATFORMTHEME = "qt6ct";
          QT_QPA_PLATFORM = "wayland;xcb";
          QT_SCALE_FACTOR = "1";
          QT_AUTO_SCREEN_SCALE_FACTOR = "0";
          GDK_SCALE = "1";
          GDK_DPI_SCALE = "1";
          GTK_THEME = "adw-gtk3-dark";
          GTK_ICON_THEME = "Tela-circle";
          GTK_USE_PORTAL = "1";
      # QT_STYLE_OVERRIDE = "kvantum";
		};
		outputs = {
		  "eDP-1".scale = 1.0;
		  "HDMI-A-1".scale = 1.0;
		  "HDMI-A-2".scale = 1.0;
		  "DP-1".scale = 1.0;
		  "DP-2".scale = 1.0;
		  "DP-3".scale = 1.0;
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
		  empty-workspace-above-first = {};
		  background-color = "#181825";
		  always-center-single-column = {};
		  center-focused-column = "on-overflow";
		  default-column-width.proportion = 0.5;
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
		animations.slowdown = 0.7;
		gestures.hot-corners.top-right = {};

		workspaces = {
		  "Browser" = {};
		  "Desk" = {};
		  "Drawr" = {};
		};

		window-rules = [ 
  		  {
  		    geometry-corner-radius = 12;
			clip-to-geometry = true;
          }
	      {
            matches = [ 
			  { app-id = "^mpv$"; }
			  { app-id = "^imv$"; }
			  { app-id = "^anki$"; }
			];
            open-floating = true;
          } 
	      {
            matches = [ 
			  { app-id = "^nemo$"; }
			  { app-id = "^org.kde.kate$"; }
			];
			opacity = 0.90;
          } 
	      {
            matches = [ 
			  { app-id = "^kitty$"; }
			  { app-id = "^anki$"; }
			  { app-id = "^qalculate-gtk$"; }
			];
            open-floating = true;
			opacity = 0.90;
            default-column-width.proportion = 0.60;
            default-window-height.proportion = 0.80;
			background-effect.xray = true;
          } 
	      {
            matches = [ 
			  { app-id = "^vlc$"; }
			];
            default-column-width.proportion = 0.80;
          } 
		  {
		    matches = [ 
			  { app-id = "^brave-browser$"; }
			  { app-id = "^google-chrome$"; }
			];
            default-column-width.proportion = 0.80;
			open-on-workspace = "Browser";
		  }
		  {
		    matches = [ 
			  { app-id = "^md.Obsidian$"; } 
			  { app-id = "^chromium-browser$"; } 
			];
			open-maximized-to-edges = true;
			open-on-workspace = "Desk";
			opacity = 0.90 ;
		  }
		  {
		    matches = [ 
			  { app-id = "^kitty-drawr$"; } 
			];
			open-floating = false;
			default-column-width.proportion = 0.80;
			open-on-workspace = "Drawr";
			opacity = 0.90 ;
		  }
		  {
		    matches = [
			  { app-id = "^steam$"; }
			  { app-id = "^vesktop$"; }
			];
            default-column-width.proportion = 0.70;
			open-on-workspace = "Drawr";
		  }
		];
		binds = {
		  "Print".screenshot = {};
		  "Mod+Return".spawn = lib.getExe pkgs.kitty;
		  "Mod+Shift+Return".spawn-sh = ''niri msg action focus-workspace "Drawr"; exec ${lib.getExe pkgs.kitty} --class kitty-drawr'';
		  "Mod+Alt+Return".spawn = "qalculate-gtk";
		  "Mod+D".spawn = lib.getExe pkgs.fuzzel;
		  "Mod+Shift+D".spawn-sh = "nix run nixpkgs#noctalia-shell ipc call launcher toggle";
          "Mod+S".spawn-sh = "nix run nixpkgs#noctalia-shell ipc call controlCenter toggle";
          "Mod+Alt+L".spawn-sh = "nix run nixpkgs#noctalia-shell ipc call lockScreen lock";
		  "Mod+B".spawn = "brave";
		  "Mod+Alt+B".spawn = "chromium";
		  "Mod+Ctrl+B".spawn = "google-chrome";
		  "Mod+F1".spawn-sh = "kitty python";
		  "Mod+F2".spawn-sh = "kitty hermes";
		  "Mod+F3".spawn-sh = "kitty yazi";
		  "Mod+F4".spawn-sh = "kitty ";
		  "Mod+F5".spawn-sh = "kitty --directory ~/Nixos hermes chat --toolsets terminal,file";
		  "Mod+F6".spawn-sh = "kitty ";
		  "Mod+F7".spawn-sh = "kitty ";
		  "Mod+F8".spawn-sh = "kitty ";
		  "Mod+F9".spawn-sh = "kitty ";
		  "Mod+F10".spawn-sh = "kitty htop";
		  "Mod+F11".spawn-sh = "kitty atop";
		  "Mod+F12".spawn-sh = "kitty btop";
		  "Mod+E".spawn = "nemo";
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
		  "Mod+6".focus-workspace = 6;
		  "Mod+7".focus-workspace = 7;
		  "Mod+8".focus-workspace = 8;
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
