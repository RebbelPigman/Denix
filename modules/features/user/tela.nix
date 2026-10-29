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
      icon_theme=Tela-circle
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
      iconTheme = {
        # Directory name from tela-circle-icon-theme (standard variant).
        # Dark session: "Tela-circle-dark".
        # Plasma rice match: "Tela-circle-purple-dark" + colorVariants = [ "purple" ].
        name = "Tela-circle";
        package = pkgs.tela-circle-icon-theme;
      };
    };

    # qt6ct is the niri wrapper's platform theme. Do not manage qt6ct.conf
    # via xdg.configFile — that is a store symlink and qt6ct cannot Apply.
    # Do not manage colors/noctalia.conf either: noctalia's qt template writes it.
    qt = {
      enable = true;
      platformTheme.name = "qtct";
    };

    home.activation.qt6ctConf = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      conf=${lib.escapeShellArg "${homeDir}/.config/qt6ct/qt6ct.conf"}
      run mkdir -p ${lib.escapeShellArg "${homeDir}/.config/qt6ct"}
      if [ -L "$conf" ]; then
        run rm -f "$conf"
      fi
      if [ ! -f "$conf" ] || ! grep -q 'color_scheme_path=.*/qt6ct/colors/noctalia.conf' "$conf"; then
        run cp ${qt6ctConf} "$conf"
        run chmod u+w "$conf"
      fi
    '';

    home.sessionVariables.GTK_ICON_THEME = "Tela-circle";
  };
}
