{ self, inputs, ... }: {
  # Karousel + Geometry Change. Imported from nixosModules.plasma.
  # Script settings / shortcuts are Home Manager (plasma-manager).
  flake.nixosModules.karousel = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      kdePackages.karousel
      kwin-script-geometry-change
    ];
  };

  flake.homeModules.karousel = { ... }: {
    imports = [
      inputs.plasma-manager.homeManagerModules.plasma-manager
    ];

    programs.plasma = {
      enable = true;

      shortcuts.kwin = {
        karousel-column-move-end = "Meta+Ctrl+Shift+End";
        karousel-column-move-left = [ "Meta+Ctrl+H" "Meta+Ctrl+Left" ];
        karousel-column-move-right = [ "Meta+Ctrl+L" "Meta+Ctrl+Right" ];
        karousel-column-move-start = "Meta+Ctrl+Shift+Home";
        karousel-column-move-to-column-1 = "Meta+Ctrl+Shift+1";
        karousel-column-move-to-column-2 = "Meta+Ctrl+Shift+2";
        karousel-column-move-to-column-3 = "Meta+Ctrl+Shift+3";
        karousel-column-move-to-column-4 = "Meta+Ctrl+Shift+4";
        karousel-column-move-to-column-5 = "Meta+Ctrl+Shift+5";
        karousel-column-move-to-column-6 = "Meta+Ctrl+Shift+6";
        karousel-column-move-to-column-7 = "Meta+Ctrl+Shift+7";
        karousel-column-move-to-column-8 = "Meta+Ctrl+Shift+8";
        karousel-column-move-to-column-9 = "Meta+Ctrl+Shift+9";
        karousel-column-move-to-desktop-1 = "Meta+Ctrl+Shift+F1";
        karousel-column-move-to-desktop-2 = "Meta+Ctrl+Shift+F2";
        karousel-column-move-to-desktop-3 = "Meta+Ctrl+Shift+F3";
        karousel-column-move-to-desktop-4 = "Meta+Ctrl+Shift+F4";
        karousel-column-move-to-desktop-5 = "Meta+Ctrl+Shift+F5";
        karousel-column-move-to-desktop-6 = "Meta+Ctrl+Shift+F6";
        karousel-column-move-to-desktop-7 = "Meta+Ctrl+Shift+F7";
        karousel-column-move-to-desktop-8 = "Meta+Ctrl+Shift+F8";
        karousel-column-move-to-desktop-9 = "Meta+Ctrl+Shift+F9";
        karousel-column-move-to-desktop-10 = "Meta+Ctrl+Shift+F10";
        karousel-column-move-to-desktop-11 = "Meta+Ctrl+Shift+F11";
        karousel-column-move-to-desktop-12 = "Meta+Ctrl+Shift+F12";
        karousel-column-move-to-next-desktop = [ "Meta+Ctrl+J" "Meta+Ctrl+Down" ];
        karousel-column-move-to-previous-desktop = [ "Meta+Ctrl+K" "Meta+Ctrl+Up" ];
        karousel-column-toggle-stacked = "Meta+X";
        karousel-column-width-decrease = "Meta+-";
        karousel-column-width-increase = "Meta+Ctrl++";
        karousel-columns-squeeze-right = "Meta+Ctrl+D";
        karousel-cycle-preset-widths = "Meta+=";
        karousel-focus-end = "Meta+End";
        karousel-focus-left = [ "Meta+H" "Meta+Left" ];
        karousel-focus-right = [ "Meta+L" "Meta+Right" ];
        karousel-focus-start = "Meta+Home";
        karousel-grid-scroll-end = "Meta+Alt+End";
        karousel-grid-scroll-focused = "Meta+C";
        karousel-grid-scroll-left = "Meta+Alt+PgUp";
        karousel-grid-scroll-left-column = "Meta+Alt+A";
        karousel-grid-scroll-right = "Meta+Alt+PgDown";
        karousel-grid-scroll-right-column = "Meta+Alt+D";
        karousel-grid-scroll-start = "Meta+Alt+Home";
        karousel-screen-switch = "Meta+Ctrl+Return";
        karousel-tail-move-to-desktop-1 = "Meta+Ctrl+Alt+Shift+F1";
        karousel-tail-move-to-desktop-2 = "Meta+Ctrl+Alt+Shift+F2";
        karousel-tail-move-to-desktop-3 = "Meta+Ctrl+Alt+Shift+F3";
        karousel-tail-move-to-desktop-4 = "Meta+Ctrl+Alt+Shift+F4";
        karousel-tail-move-to-desktop-5 = "Meta+Ctrl+Alt+Shift+F5";
        karousel-tail-move-to-desktop-6 = "Meta+Ctrl+Alt+Shift+F6";
        karousel-tail-move-to-desktop-7 = "Meta+Ctrl+Alt+Shift+F7";
        karousel-tail-move-to-desktop-8 = "Meta+Ctrl+Alt+Shift+F8";
        karousel-tail-move-to-desktop-9 = "Meta+Ctrl+Alt+Shift+F9";
        karousel-tail-move-to-desktop-10 = "Meta+Ctrl+Alt+Shift+F10";
        karousel-tail-move-to-desktop-11 = "Meta+Ctrl+Alt+Shift+F11";
        karousel-tail-move-to-desktop-12 = "Meta+Ctrl+Alt+Shift+F12";
        karousel-window-move-end = "Meta+Shift+End";
        karousel-window-move-start = "Meta+Shift+Home";
        karousel-window-move-to-column-1 = "Meta+Shift+1";
        karousel-window-move-to-column-2 = "Meta+Shift+2";
        karousel-window-move-to-column-3 = "Meta+Shift+3";
        karousel-window-move-to-column-4 = "Meta+Shift+4";
        karousel-window-move-to-column-5 = "Meta+Shift+5";
        karousel-window-move-to-column-6 = "Meta+Shift+6";
        karousel-window-move-to-column-7 = "Meta+Shift+7";
        karousel-window-move-to-column-8 = "Meta+Shift+8";
        karousel-window-move-to-column-9 = "Meta+Shift+9";
        karousel-window-move-up = "Meta+Shift+W";
        karousel-window-toggle-floating = "Meta+Space";
      };

      configFile.kwinrc = {
        Plugins = {
          karouselEnabled = true;
          kwin4_effect_geometry_changeEnabled = true;
        };
        Script-karousel = {
          gapsInnerHorizontal = 4;
          gapsInnerVertical = 4;
          gapsOuterBottom = 8;
          gapsOuterLeft = 32;
          gapsOuterRight = 32;
          gapsOuterTop = 8;
          gestureScrollInvert = true;
          presetWidths = "30%, 50%, 70%, 85%, 100%";
          windowRules = ''
            [
                {
                    "class": "(org\\.kde\\.)?plasmashell",
                    "tile": false
                },
                {
                    "class": "(org\\.kde\\.)?polkit-kde-authentication-agent-1",
                    "tile": false
                },
                {
                    "class": "(org\\.kde\\.)?kded6",
                    "tile": false
                },
                {
                    "class": "(org\\.kde\\.)?kcalc",
                    "tile": false
                },
                {
                    "class": "(org\\.kde\\.)?kfind",
                    "tile": true
                },
                {
                    "class": "(org\\.kde\\.)?kruler",
                    "tile": false
                },
                {
                    "class": "(org\\.kde\\.)?krunner",
                    "tile": false
                },
                {
                    "class": "(org\\.kde\\.)?yakuake",
                    "tile": false
                },
                {
                    "class": "wl-copy|wl-paste",
                    "caption": "wl-clipboard",
                    "tile": false
                },
                {
                    "class": "kitty",
                    "tile": false
                },
                {
                    "class": "steam",
                    "caption": "Steam Big Picture Mode",
                    "tile": false
                },
                {
                    "class": "zoom",
                    "caption": "Zoom Cloud Meetings|zoom|zoom <2>",
                    "tile": false
                },
                {
                    "class": "jetbrains-.*",
                    "caption": "splash",
                    "tile": false
                },
                {
                    "class": "jetbrains-.*",
                    "caption": "Unstash Changes|Paths Affected by stash@.*",
                    "tile": true
                }
            ]
          '';
        };
      };
    };
  };
}
