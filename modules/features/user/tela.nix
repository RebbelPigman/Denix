{ self, inputs, ... }: {
  # GTK + Qt icon theme for niri hosts.
  # Import once from the host home module (aureliusHome).
  # Do not also add this to home-manager.sharedModules — gtk.iconTheme.package
  # is unique and a double attach fails the rebuild.
  flake.homeModules.tela = { pkgs, lib, config, ... }:
  let
    homeDir = config.home.homeDirectory;
    noctaliaPalette = "${homeDir}/.config/qt6ct/colors/noctalia.conf";
    qt6ctConf = pkgs.writeText "qt6ct.conf" ''
      [Appearance]
      color_scheme_path=${noctaliaPalette}
      custom_palette=true
      icon_theme=Tela-circle-dark
      standard_dialogs=default
      style=Fusion

      [Fonts]
      fixed="BlexMono,12,-1,5,50,0,0,0,0,0"
      general="BlexMono,12,-1,5,50,0,0,0,0,0"

      [Interface]
      activate_item_on_single_click=1
      buttonbox_layout=0
      cursor_flash_time=1000
      dialog_buttons_have_icons=1
      double_click_interval=400
      gui_effects=@Invalid()
      keyboard_scheme=2
      menus_have_icons=true
      show_shortcuts_in_context_menus=true
      stylesheets=@Invalid()
      toolbutton_style=4
      underline_shortcut=1
      wheel_scroll_lines=3

      [Troubleshooting]
      force_raster_widgets=1
      ignored_applications=@Invalid()
    '';
  in {
    gtk = {
      enable = true;
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        # Dark session under niri/noctalia. Plasma keeps its own iconTheme.
        name = "Tela-circle-dark";
        package = pkgs.tela-circle-icon-theme;
      };
    };

    # qt6ct is the niri wrapper's platform theme. Dolphin is Qt6 — qt5ct leaves
    # Fusion chrome half-themed. Do not manage qt6ct.conf via xdg.configFile
    # (store symlink; qt6ct cannot Apply). Noctalia's qt template owns the palette.
    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style.name = "Fusion";
    };

    home.packages = [
      pkgs.qt6Packages.qt6ct
      pkgs.libsForQt5.qt5ct
    ];

    home.activation.qt6ctConf = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      conf=${lib.escapeShellArg "${homeDir}/.config/qt6ct/qt6ct.conf"}
      conf5=${lib.escapeShellArg "${homeDir}/.config/qt5ct/qt5ct.conf"}
      run mkdir -p ${lib.escapeShellArg "${homeDir}/.config/qt6ct"}
      run mkdir -p ${lib.escapeShellArg "${homeDir}/.config/qt5ct"}
      if [ -L "$conf" ]; then
        run rm -f "$conf"
      fi
      # Always refresh Appearance so a stale qt5ct / light Tela pin cannot stick.
      run cp ${qt6ctConf} "$conf"
      run chmod u+w "$conf"
      # Qt5 apps still read qt5ct. Same palette + dark icons.
      if [ -L "$conf5" ]; then
        run rm -f "$conf5"
      fi
      run cp ${qt6ctConf} "$conf5"
      run chmod u+w "$conf5"
    '';

    # Force qt6ct for Qt6 (Dolphin). HM qtct alone can leave qt5ct in the session.
    home.sessionVariables = {
      GTK_ICON_THEME = "Tela-circle-dark";
      GTK_THEME = "adw-gtk3-dark";
      # HM qt.platformTheme qtct still emits qt5ct. Dolphin is Qt6.
      QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
      QT_QPA_PLATFORM = "wayland;xcb";
    };
  };
}
