{ self, inputs, ... }: {

  flake.nixosModules.sway = { pkgs, lib, ... }: {
    programs.sway = {
      enable = true;
      extraOptions = [
        "--config"
        "${self.packages.${pkgs.stdenv.hostPlatform.system}.mySwayConfig}"
      ];
      wrapperFeatures.gtk = true;
      extraPackages = with pkgs; [
        slurp grim waybar mako
      ];
      extraSessionCommands = ''
        export QT_QPA_PLATFORMTHEME=qt6ct
        export QT_QPA_PLATFORM="wayland;xcb"
        export QT_SCALE_FACTOR=1
        export QT_AUTO_SCREEN_SCALE_FACTOR=0
        export GDK_SCALE=1
        export GDK_DPI_SCALE=1
        export GTK_THEME=adw-gtk3-dark
        export GTK_ICON_THEME=Tela-circle
        export GTK_USE_PORTAL=1
        export NIXOS_OZONE_WL=1
      '';
    };

    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
    xdg.portal.config.sway.default = lib.mkForce [ "wlr" "gtk" ];
    environment.systemPackages = [ pkgs.tela-circle-icon-theme ];
  };

  perSystem = { pkgs, lib, ... }:
  let
    kitty = lib.getExe pkgs.kitty;
    fuzzel = lib.getExe pkgs.fuzzel;
    grim = lib.getExe pkgs.grim;
    slurp = lib.getExe pkgs.slurp;
    waybar = lib.getExe pkgs.waybar;
    mako = lib.getExe pkgs.mako;
    makoctl = "${pkgs.mako}/bin/makoctl";
    makoHint = pkgs.writeShellApplication {
      name = "waybar-mako";
      runtimeInputs = [ pkgs.mako pkgs.coreutils pkgs.gnugrep ];
      text = ''
        n=0
        if out=$(makoctl list 2>/dev/null); then
          n=$(printf '%s\n' "$out" | grep -c '"id"' || true)
        fi
        if [ "$n" -gt 0 ]; then
          printf '{"text":"","class":"unread","alt":"unread","tooltip":"%s notification(s)"}\n' "$n"
        else
          printf '{"text":"","class":"empty","alt":"empty","tooltip":"no notifications"}\n'
        fi
      '';
    };
    wpctl = "${pkgs.wireplumber}/bin/wpctl";
    brightnessctl = lib.getExe pkgs.brightnessctl;
    swaymsg = "${pkgs.sway}/bin/swaymsg";

    waybarConfig = pkgs.writeText "waybar-config" ''
      {
        "layer": "top",
        "position": "right",
        "width": 56,
        "spacing": 4,
        "modules-left": ["sway/workspaces", "cpu", "memory"],
        "modules-center": ["clock"],
        "modules-right": ["custom/notifications", "network", "bluetooth", "battery"],
        "sway/workspaces": {
          "disable-scroll": true,
          "all-outputs": true,
          "format": "{icon}",
          "tooltip-format": "{name}",
          "persistent-workspaces": {
            "Browse": [],
            "Desk": [],
            "Drawr": [],
            "Side": []
          },
          "format-icons": {
            "Browse": "",
            "Desk": "",
            "Drawr": "",
            "Side": "",
            "default": ""
          }
        },
        "cpu": {
          "format": "\n{usage}",
          "interval": 5
        },
        "memory": {
          "format": "\n{percentage}",
          "interval": 5
        },
        "clock": {
          "format": "{:%H\n%M}",
          "tooltip-format": "{:%Y-%m-%d %a}"
        },
        "custom/notifications": {
          "exec": "${makoHint}/bin/waybar-mako",
          "interval": 2,
          "return-type": "json",
          "on-click": "${makoctl} dismiss -a",
          "on-click-right": "${makoctl} restore",
          "format": "{text}"
        },
        "network": {
          "format-wifi": "",
          "format-ethernet": "",
          "format-disconnected": "",
          "tooltip-format": "{ifname} {essid} {ipaddr}"
        },
        "bluetooth": {
          "format": "",
          "format-off": "",
          "format-disabled": "",
          "format-connected": "",
          "tooltip-format": "{status}"
        },
        "battery": {
          "format": "{icon}",
          "format-charging": "",
          "format-icons": ["", "", "", "", ""],
          "tooltip-format": "{capacity}%"
        }
      }
    '';

    waybarStyle = pkgs.writeText "waybar-style.css" ''
      * {
        font-family: "BlexMono Nerd Font Mono", "BlexMono Nerd Font", sans-serif;
        font-size: 13px;
        min-height: 0;
      }
      window#waybar { background: #181825; color: #cba6f7; border: none; }
      tooltip { background: #1e1e2e; color: #cdd6f4; border: 1px solid #cba6f7; }
      #workspaces, #workspaces button, #workspaces button label {
        font-size: 28px; min-height: 28px; min-width: 28px;
      }
      #workspaces button {
        padding: 8px 0; margin: 2px 4px; color: #6c7086;
        background: transparent; border: none; border-radius: 8px;
      }
      #workspaces button.visible { color: #cba6f7; }
      #workspaces button.focused, #workspaces button.active {
        color: #181825; background: #cba6f7;
      }
      #workspaces button.urgent { color: #181825; background: #f38ba8; }
      #cpu, #memory, #network, #bluetooth, #battery, #custom-notifications { font-size: 28px; }
      #clock { font-size: 13px; }
      #clock, #cpu, #memory, #network, #bluetooth, #battery, #custom-notifications {
        padding: 8px 0; margin: 2px 4px; color: #cba6f7;
      }
      #network.disconnected, #battery.critical, #bluetooth.off, #bluetooth.disabled { color: #f38ba8; }
      #custom-notifications.empty { color: #6c7086; }
      #custom-notifications.unread { color: #f9e2af; }
    '';

    waybarDir = pkgs.runCommand "my-waybar" { } ''
      mkdir -p $out
      cp ${waybarConfig} $out/config
      cp ${waybarStyle} $out/style.css
    '';

    swayConfig = pkgs.writeText "sway-config" ''
      include /etc/sway/config.d/*
      font pango:BlexMono Nerd Font Mono 10
      floating_modifier Mod4
      default_border pixel 3
      default_floating_border pixel 3
      gaps inner 4
      gaps outer 0
      smart_gaps off
      focus_follows_mouse yes
      mouse_warping container
      output * bg #181825 solid_color
      set $mod Mod4
      set $term ${kitty}
      set $menu ${fuzzel}
      set $bg #181825
      set $surface #1e1e2e
      set $accent #cba6f7
      client.focused          $accent $bg $accent $accent $accent
      client.focused_inactive $surface $bg $surface $surface $surface
      client.unfocused        $surface $bg $surface $surface $surface
      client.urgent           $accent $bg $accent $accent $accent
      output eDP-1 scale 1
      output HDMI-A-1 scale 1
      output HDMI-A-2 scale 1
      output DP-1 scale 1
      output DP-2 scale 1
      output DP-3 scale 1
      input type:keyboard {
        xkb_layout us
        xkb_options caps:swapescape,compose:ralt,numpad:mac
      }
      input type:touchpad {
        tap enabled
        natural_scroll enabled
        accel_profile adaptive
        pointer_accel 0.2
      }
      set $wsH Browse
      set $wsJ Desk
      set $wsK Drawr
      set $wsL Side
      workspace $wsH
      workspace_layout tabbed
      workspace $wsJ
      workspace_layout tabbed
      workspace $wsK
      workspace_layout default
      workspace $wsL
      workspace_layout default
      workspace $wsH
      assign [app_id="^brave-browser$"] $wsH
      assign [app_id="^google-chrome$"] $wsH
      assign [app_id="^md.Obsidian$"] $wsJ
      assign [app_id="^chromium-browser$"] $wsJ
      assign [app_id="^kitty-drawr$"] $wsK
      for_window [app_id="^brave-browser$"] focus
      for_window [app_id="^google-chrome$"] focus
      for_window [app_id="^md.Obsidian$"] focus
      for_window [app_id="^chromium-browser$"] focus
      for_window [app_id="^kitty-drawr$"] floating disable, focus
      for_window [app_id="^kitty$"] floating enable, resize set width 60 ppt height 80 ppt, move position center
      for_window [app_id="^nemo$"] floating enable, resize set width 60 ppt height 80 ppt, move position center
      for_window [app_id="^qalculate-gtk$"] floating enable, resize set width 60 ppt height 80 ppt, move position center
      for_window [app_id="^anki$"] floating enable, resize set width 60 ppt height 80 ppt, move position center
      for_window [app_id="^mpv$"] floating enable
      for_window [app_id="^imv$"] floating enable
      bindsym $mod+Return exec $term
      bindsym $mod+Shift+Return workspace $wsK; exec $term --class kitty-drawr
      bindsym $mod+Alt+Return exec qalculate-gtk
      bindsym $mod+d exec $menu
      bindsym $mod+b exec brave
      bindsym $mod+Alt+b exec chromium
      bindsym $mod+Ctrl+b exec google-chrome
      bindsym $mod+e exec nemo
      bindsym $mod+i exec obsidian
      bindsym $mod+q kill
      bindsym $mod+Shift+q exec ${swaymsg} exit
      bindsym $mod+Shift+r reload
      bindsym $mod+h focus left
      bindsym $mod+j focus down
      bindsym $mod+k focus up
      bindsym $mod+l focus right
      bindsym $mod+Ctrl+h move left
      bindsym $mod+Ctrl+j move down
      bindsym $mod+Ctrl+k move up
      bindsym $mod+Ctrl+l move right
      bindsym $mod+Alt+h workspace $wsH
      bindsym $mod+Alt+j workspace $wsJ
      bindsym $mod+Alt+k workspace $wsK
      bindsym $mod+Alt+l workspace $wsL
      bindsym $mod+Ctrl+Alt+h move container to workspace $wsH
      bindsym $mod+Ctrl+Alt+j move container to workspace $wsJ
      bindsym $mod+Ctrl+Alt+k move container to workspace $wsK
      bindsym $mod+Ctrl+Alt+l move container to workspace $wsL
      bindsym $mod+space floating toggle
      bindsym $mod+Alt+space focus mode_toggle
      bindsym $mod+f fullscreen toggle
      bindsym $mod+minus resize shrink width 20 ppt
      bindsym $mod+equal resize grow width 20 ppt
      bindsym $mod+1 workspace $wsH
      bindsym $mod+2 workspace $wsJ
      bindsym $mod+3 workspace $wsK
      bindsym $mod+4 workspace $wsL
      bindsym $mod+Shift+1 move container to workspace $wsH
      bindsym $mod+Shift+2 move container to workspace $wsJ
      bindsym $mod+Shift+3 move container to workspace $wsK
      bindsym $mod+Shift+4 move container to workspace $wsL
      bindsym $mod+F1 exec $term python
      bindsym $mod+F2 exec $term hermes
      bindsym $mod+F3 exec $term yazi
      bindsym $mod+F4 exec $term
      bindsym $mod+F5 exec $term
      bindsym $mod+F6 exec $term
      bindsym $mod+F7 exec $term
      bindsym $mod+F8 exec $term
      bindsym $mod+F9 exec $term
      bindsym $mod+F10 exec $term htop
      bindsym $mod+F11 exec $term atop
      bindsym $mod+F12 exec $term btop
      bindsym Print exec ${grim} -g "$(${slurp})" "$HOME/Pictures/shot-$(date +%Y%m%d-%H%M%S).png"
      bindsym XF86AudioRaiseVolume exec ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 0.05+
      bindsym XF86AudioLowerVolume exec ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 0.05-
      bindsym XF86AudioMute exec ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindsym XF86AudioMicMute exec ${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindsym XF86MonBrightnessUp exec ${brightnessctl} --class=backlight set +5%
      bindsym XF86MonBrightnessDown exec ${brightnessctl} --class=backlight set 5%-
      exec ${mako}
      exec ${waybar} -c ${waybarDir}/config -s ${waybarDir}/style.css
    '';
  in {
    packages.mySwayConfig = swayConfig;
    packages.myWaybar = waybarDir;
  };
}
