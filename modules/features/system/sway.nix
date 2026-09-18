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
        slurp
        grim
        mako
        swaybg
        swayidle
        swaylock
        waybar
        kanshi
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
    security.pam.services.swaylock = {};
  };

  perSystem = { pkgs, lib, ... }:
  let
    kitty = lib.getExe pkgs.kitty;
    fuzzel = lib.getExe pkgs.fuzzel;
    grim = lib.getExe pkgs.grim;
    slurp = lib.getExe pkgs.slurp;
    mako = lib.getExe pkgs.mako;
    swaybg = lib.getExe pkgs.swaybg;
    swayidle = lib.getExe pkgs.swayidle;
    swaylock = lib.getExe pkgs.swaylock;
    waybar = lib.getExe pkgs.waybar;
    wpctl = "${pkgs.wireplumber}/bin/wpctl";
    brightnessctl = lib.getExe pkgs.brightnessctl;
    swaymsg = "${pkgs.sway}/bin/swaymsg";

    waybarConfig = pkgs.writeText "waybar-config" ''
      {
        "layer": "top",
        "position": "right",
        "width": 72,
        "spacing": 4,
        "reload_style_on_change": true,
        "modules-left": ["sway/workspaces"],
        "modules-center": ["clock"],
        "modules-right": ["pulseaudio", "network", "cpu", "memory", "battery", "tray"],
        "sway/workspaces": {
          "disable-scroll": true,
          "all-outputs": true,
          "format": "{icon}",
          "tooltip-format": "{name}",
          "persistent-workspaces": {
            "Browser": [],
            "Desk": [],
            "Drawr": [],
            "Side": []
          },
          "format-icons": {
            "Browser": "󰅟",
            "Desk": "󰨇",
            "Drawr": "󰇅",
            "Side": "",
            "default": ""
          }
        },
        "clock": {
          "format": "{:%H\n%M}",
          "tooltip-format": "{:%Y-%m-%d %a}"
        },
        "cpu": {
          "format": "<span font_size='26pt'>\uf2db</span>\n{usage}",
          "markup": "pango",
          "interval": 2
        },
        "memory": {
          "format": "<span font_size='26pt'>\uf538</span>\n{percentage}",
          "markup": "pango",
          "interval": 5
        },
        "pulseaudio": {
          "format": "{icon}",
          "format-muted": "\uf6a9",
          "format-icons": {
            "default": ["\uf026", "\uf027", "\uf028"]
          },
          "on-click": "pavucontrol",
          "tooltip-format": "{volume}%"
        },
        "network": {
          "format-wifi": "\uf1eb",
          "format-ethernet": "\uf6ff",
          "format-disconnected": "\uf127",
          "tooltip-format": "{ifname} {essid} {ipaddr}"
        },
        "battery": {
          "format": "{icon}",
          "format-charging": "\uf1e6",
          "format-icons": ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"],
          "tooltip-format": "{capacity}%"
        },
        "tray": {
          "icon-size": 32,
          "spacing": 4
        }
      }
    '';

    waybarStyle = pkgs.writeText "waybar-style.css" ''
      * {
        font-family: "BlexMono Nerd Font Mono", "BlexMono Nerd Font", sans-serif;
        font-size: 13px;
        min-height: 0;
      }
      window#waybar {
        background: #181825;
        color: #cba6f7;
        border: none;
      }
      tooltip {
        background: #1e1e2e;
        color: #cdd6f4;
        border: 1px solid #cba6f7;
      }
      #workspaces {
        font-size: 40px;
      }
      #workspaces button {
        padding: 8px 0;
        margin: 2px 4px;
        color: #6c7086;
        background: transparent;
        border: none;
        border-radius: 8px;
      }
      #workspaces button.visible {
        color: #cba6f7;
      }
      #pulseaudio, #network, #battery {
        font-size: 26px;
      }
      #clock, #cpu, #memory {
        font-size: 13px;
      }
      #workspaces button.focused,
      #workspaces button.active {
        color: #181825;
        background: #cba6f7;
      }
      #workspaces button.urgent {
        color: #181825;
        background: #f38ba8;
      }
      #clock, #cpu, #memory, #pulseaudio, #network, #battery, #tray {
        padding: 8px 0;
        margin: 2px 4px;
        color: #cba6f7;
      }
      #pulseaudio.muted, #network.disconnected, #battery.critical {
        color: #f38ba8;
      }
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
      gaps inner 12
      smart_gaps on
      focus_follows_mouse yes
      mouse_warping container

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

      set $ws1 Browser
      set $ws2 Desk
      set $ws3 Drawr
      set $ws4 Side

      assign [app_id="^brave-browser$"] $ws1
      assign [app_id="^google-chrome$"] $ws1
      assign [app_id="^md.Obsidian$"] $ws2
      assign [app_id="^chromium-browser$"] $ws2
      assign [app_id="^kitty-drawr$"] $ws3
      assign [app_id="^steam$"] $ws4
      assign [class="^steam$"] $ws4
      assign [app_id="^vesktop$"] $ws4

      for_window [app_id="^mpv$"] floating enable
      for_window [app_id="^imv$"] floating enable
      for_window [app_id="^anki$"] floating enable
      for_window [app_id="^kitty$"] floating enable
      for_window [app_id="^qalculate-gtk$"] floating enable
      for_window [app_id="^kitty-drawr$"] floating disable

      bindsym $mod+Return exec $term
      bindsym $mod+Shift+Return workspace $ws3; exec $term --class kitty-drawr
      bindsym $mod+Alt+Return exec qalculate-gtk
      bindsym $mod+d exec $menu
      bindsym $mod+Shift+d exec $menu
      bindsym $mod+s exec pavucontrol
      bindsym $mod+Alt+l exec ${swaylock} -f -c 181825
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
      bindsym $mod+Shift+h move left
      bindsym $mod+Shift+l move right
      bindsym $mod+space floating toggle
      bindsym $mod+Alt+space focus mode_toggle
      bindsym $mod+f resize set width 100 ppt height 100 ppt
      bindsym $mod+Shift+f fullscreen toggle
      bindsym $mod+Alt+f resize set width 100 ppt
      bindsym $mod+minus resize shrink width 20 ppt
      bindsym $mod+equal resize grow width 20 ppt
      bindsym $mod+Alt+v resize set width 30 ppt
      bindsym $mod+v resize set width 50 ppt
      bindsym $mod+Shift+v resize set width 60 ppt
      bindsym $mod+Shift+Alt+v resize set width 70 ppt
      bindsym $mod+Ctrl+v resize set width 80 ppt

      bindsym $mod+1 workspace $ws1
      bindsym $mod+2 workspace $ws2
      bindsym $mod+3 workspace $ws3
      bindsym $mod+4 workspace $ws4
      bindsym $mod+5 workspace number 5
      bindsym $mod+6 workspace number 6
      bindsym $mod+7 workspace number 7
      bindsym $mod+8 workspace number 8
      bindsym $mod+Shift+1 move container to workspace $ws1
      bindsym $mod+Shift+2 move container to workspace $ws2
      bindsym $mod+Shift+3 move container to workspace $ws3
      bindsym $mod+Shift+4 move container to workspace $ws4

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

      exec ${waybar} -c ${waybarDir}/config -s ${waybarDir}/style.css
      exec ${mako}
      exec ${swaybg} -c '#181825'
      exec dropbox
      exec ${swayidle} -w \\
        timeout 300 '${swaylock} -f -c 181825' \\
        timeout 600 '${swaymsg} "output * power off"' \\
        resume '${swaymsg} "output * power on"' \\
        before-sleep '${swaylock} -f -c 181825'
    '';
  in {
    packages.mySwayConfig = swayConfig;
    packages.myWaybar = waybarDir;
    packages.mySway = inputs.wrapper-modules.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.sway;
      flags."--config" = "${swayConfig}";
    };
  };
}
