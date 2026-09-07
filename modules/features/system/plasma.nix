{ self, inputs, ... }: {
  # NixOS: Plasma 6 + KDE extras + theme packages.
  # Home: workspace / fonts / desktops / shortcuts / window rules.
  # Karousel + geometry-change live in nixosModules.karousel / homeModules.karousel.
  flake.nixosModules.plasma = { pkgs, ... }: {
    imports = [
      self.nixosModules.desk
      self.nixosModules.karousel
    ];

    services.desktopManager.plasma6.enable = true;

    programs.kdeconnect.enable = true;

    environment.systemPackages = with pkgs; [
      kdePackages.filelight
      kdePackages.partitionmanager
      kdePackages.ksystemlog
      kdePackages.kcharselect
      kdePackages.isoimagewriter
      tela-circle-icon-theme
      (catppuccin-kde.override {
        flavour = [ "mocha" ];
        accents = [ "mauve" ];
      })
    ];

    # Any HM user on a host that imports this module gets the rice.
    # aureliusHome also imports the home modules so standalone
    # homeConfigurations.rebbAurelius sees them too.
    home-manager.sharedModules = [
      self.homeModules.plasma
      self.homeModules.karousel
    ];
  };

  flake.homeModules.plasma = { pkgs, config, ... }: {
    imports = [
      inputs.plasma-manager.homeManagerModules.plasma-manager
    ];

    programs.plasma = {
      enable = true;

      workspace = {
        # Store style already on the machine; package it if ~/.local/share
        # plasma/desktoptheme/Scratchy should survive a clean home.
        theme = "Scratchy";
        colorScheme = "CatppuccinMocha";
        iconTheme = "Tela-circle-purple-dark";
        windowDecorations.theme = "Breeze";
        wallpaper = "${config.home.homeDirectory}/.wallpaper";
      };

      fonts = {
        general = {
          family = "BlexMono Nerd Font";
          pointSize = 10;
        };
        fixedWidth = {
          family = "BlexMono Nerd Font Mono";
          pointSize = 10;
        };
        small = {
          family = "BlexMono Nerd Font";
          pointSize = 8;
        };
        toolbar = {
          family = "BlexMono Nerd Font";
          pointSize = 10;
        };
        menu = {
          family = "BlexMono Nerd Font";
          pointSize = 10;
        };
        windowTitle = {
          family = "BlexMono Nerd Font";
          pointSize = 10;
        };
      };

      kwin = {
        virtualDesktops = {
          rows = 4;
          names = [ "Web" "Main" "Back" "Term" ];
        };
        effects.hideCursor.enable = true;
      };

      kscreenlocker.timeout = 30;

      shortcuts = {
        ksmserver."Lock Session" = [ "Screensaver" "Meta+Alt+L" ];
        ksmserver."Log Out" = "Ctrl+Alt+Del";
        "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Alt+K";
        kaccess."Toggle Screen Reader On and Off" = "Meta+Alt+S";
        kwin = {
          "Activate Window Demanding Attention" = "Meta+Ctrl+A";
          "Edit Tiles" = "Meta+T";
          Expose = [ "Ctrl+F9" "Meta+F9" ];
          ExposeAll = [ "Launch (C)" "Ctrl+F10" "Meta+F10" ];
          ExposeClass = [ "Ctrl+F7" "Meta+F7" ];
          "Grid View" = "Meta+G";
          "Kill Window" = [ "Meta+Shift+Q" "Meta+Ctrl+Esc" ];
          MoveMouseToCenter = "Meta+F6";
          MoveMouseToFocus = "Meta+F5";
          Overview = "Meta+O";
          "Suspend Compositing" = "Alt+Shift+F12";
          "Switch Window Down" = "Meta+Alt+Down";
          "Switch Window Left" = "Meta+Alt+Left";
          "Switch Window Right" = "Meta+Alt+Right";
          "Switch Window Up" = "Meta+Alt+Up";
          "Switch to Desktop 1" = "Meta+F1";
          "Switch to Desktop 2" = "Ctrl+F2";
          "Switch to Desktop 3" = "Ctrl+F3";
          "Switch to Desktop 4" = "Meta+F4";
          "Switch to Next Desktop" = [ "Meta+J" "Meta+Down" ];
          "Switch to Previous Desktop" = [ "Meta+K" "Meta+Up" ];
          "Walk Through Windows" = [ "Alt+Tab" "Meta+Tab" ];
          "Walk Through Windows (Reverse)" = [ "Alt+Shift+Tab" "Meta+Shift+Tab" ];
          "Walk Through Windows of Current Application" = [ "Alt+`" "Meta+`" ];
          "Walk Through Windows of Current Application (Reverse)" = [ "Alt+~" "Meta+~" ];
          "Window Close" = [ "Alt+F4" "Meta+Q" ];
          "Window Fullscreen" = "Meta+F";
          "Window Maximize" = "Meta+PgUp";
          "Window Minimize" = "Meta+PgDown";
          "Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
          "Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
          "Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
          "Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
          "Window Operations Menu" = "Alt+F3";
          "Window Restore" = "Meta+Backspace";
          "Window to Next Screen" = "Meta+Shift+Right";
          "Window to Previous Screen" = "Meta+Shift+Left";
          disableInputCapture = "Meta+Shift+Esc";
          view_actual_size = "Meta+0";
          view_zoom_in = "Meta++";
        };
        org_kde_powerdevil.powerProfile = [ "Battery" "Meta+B" ];
        plasmashell = {
          "activate application launcher" = [ "Alt+F1" "Meta+Shift+D" ];
          "activate task manager entry 1" = "Meta+1";
          "activate task manager entry 2" = "Meta+2";
          "activate task manager entry 3" = "Meta+3";
          "activate task manager entry 4" = "Meta+4";
          "activate task manager entry 5" = "Meta+5";
          "activate task manager entry 6" = "Meta+6";
          "activate task manager entry 7" = "Meta+7";
          "activate task manager entry 8" = "Meta+8";
          "activate task manager entry 9" = "Meta+9";
          clipboard_action = "Meta+Ctrl+X";
          cycle-panels = "Meta+Alt+P";
          "next activity" = "Meta+A";
          "previous activity" = "Meta+Shift+A";
          "show dashboard" = "Ctrl+F12";
          show-on-mouse-pos = "Meta+V";
        };
        "services/kitty.desktop"._launch = "Meta+Return";
        "services/org.kde.krunner.desktop"._launch = "Meta+D";
      };

      configFile = {
        kdeglobals.General = {
          AccentColor = "184,117,220";
          LastUsedCustomAccentColor = "184,117,220";
          XftAntialias = true;
          XftHintStyle = "hintslight";
          XftSubPixel = "none";
        };
        kdeglobals.KDE.contrast = 7;
        kdeglobals.KDE.frameContrast = 0.2;
        plasmarc.Theme.name = "Scratchy";
        kwinrc.Windows = {
          DelayFocusInterval = 150;
          FocusPolicy = "FocusFollowsMouse";
        };
        kwinrc.ElectricBorders.Top = "KRunner";
        kwinrc.Xwayland.Scale = 1;
        kwinrc."org.kde.kdecoration2".theme = "Breeze";
        kscreenlockerrc.Daemon.LockGrace = 300;
        kscreenlockerrc."Greeter/Wallpaper/org.kde.image/General" = {
          Image = "${config.home.homeDirectory}/.wallpaper";
          PreviewImage = "${config.home.homeDirectory}/.wallpaper";
        };
        kxkbrc.Layout = {
          Options = "caps:swapescape";
          ResetOldOptions = true;
        };
        kcminputrc.Mouse = {
          X11LibInputXAccelProfileFlat = true;
          cursorSize = 48;
        };
        katerc."KTextEditor Renderer"."Color Theme" = "Catppuccin Mocha";
        plasma-localerc.Formats.LANG = "en_ZA.UTF-8";

        # Opacity + kitty placement from the live kwinrulesrc dump.
        kwinrulesrc.General = {
          count = 6;
          rules = "db7bd38e-f124-4fa7-8109-c20999584e48,39f71359-d2dc-47bc-bd94-84b57fbf7a65,086d49aa-4a6d-401c-b1a7-09799ee1306b,e2798c88-f00a-448d-ab98-714736a2b9aa,74a64d3d-8d3e-4cc6-a2fb-43c4db39895e,b3eaf168-3e12-417b-b04c-66c4a342afd4";
        };
        kwinrulesrc."db7bd38e-f124-4fa7-8109-c20999584e48" = {
          Description = "Application settings for org.kde.konsole";
          opacityactive = 90;
          opacityactiverule = 2;
          opacityinactive = 75;
          opacityinactiverule = 2;
          wmclass = "konsole org.kde.konsole";
          wmclasscomplete = true;
          wmclassmatch = 1;
        };
        kwinrulesrc."39f71359-d2dc-47bc-bd94-84b57fbf7a65" = {
          Description = "Application settings for org.kde.dolphin";
          opacityactive = 90;
          opacityactiverule = 2;
          opacityinactive = 80;
          opacityinactiverule = 2;
          wmclass = "dolphin org.kde.dolphin";
          wmclasscomplete = true;
          wmclassmatch = 1;
        };
        kwinrulesrc."086d49aa-4a6d-401c-b1a7-09799ee1306b" = {
          Description = "Application settings for org.kde.okular";
          opacityactive = 90;
          opacityactiverule = 2;
          opacityinactive = 80;
          opacityinactiverule = 2;
          wmclass = "okular org.kde.okular";
          wmclasscomplete = true;
          wmclassmatch = 1;
        };
        kwinrulesrc."e2798c88-f00a-448d-ab98-714736a2b9aa" = {
          Description = "Application settings for anki";
          opacityactive = 90;
          opacityactiverule = 2;
          opacityinactive = 70;
          opacityinactiverule = 2;
          wmclass = "python3.14 anki";
          wmclasscomplete = true;
          wmclassmatch = 1;
        };
        kwinrulesrc."74a64d3d-8d3e-4cc6-a2fb-43c4db39895e" = {
          Description = "Application settings for kitty";
          opacityactive = 90;
          opacityactiverule = 2;
          opacityinactive = 50;
          opacityinactiverule = 2;
          position = "320,60";
          positionrule = 3;
          size = "1280,960";
          sizerule = 3;
          wmclass = "kitty";
          wmclassmatch = 1;
        };
        kwinrulesrc."b3eaf168-3e12-417b-b04c-66c4a342afd4" = {
          Description = "Application settings for obsidian";
          opacityactive = 90;
          opacityactiverule = 2;
          opacityinactive = 70;
          opacityinactiverule = 2;
          wmclass = "electron obsidian";
          wmclasscomplete = true;
          wmclassmatch = 1;
        };
      };
    };
  };
}
