{ self, inputs, ... }: {
  flake.nixosModules.core = { pkgs, ... }: {
    services = {
      displayManager.ly.enable = true;
      gnome.gnome-keyring.enable = true;
      xserver = {
        enable = true;
        windowManager.i3 = {
		  enable = true;
		  extraPackages = with pkgs; [
            rofi
		  ];
		  configFile = pkgs.writeText "i3-config" ''
		    font pango:BlexMono Nerd Font Mono 10
			set $mod Mod4
			bindsym $mod+Return exec st
			bindsym $mod+q kill
			bindsym $mod+d exec --no-startup-id rofi -show drun
			bindsym $mod+b exec chromium
			bindsym $mod+h focus left
			bindsym $mod+j focus down
			bindsym $mod+k focus up
			bindsym $mod+l focus right
			bindsym $mod+Shift+h move left
			bindsym $mod+Shift+j move down
			bindsym $mod+Shift+k move up
			bindsym $mod+Shift+l move right
			bindsym $mod+c split h
			bindsym $mod+v split v
			bindsym $mod+f fullscreen
			bindsym $mod+space floating toggle
			bindsym $mod+1 workspace 1
			bindsym $mod+2 workspace 2
			bindsym $mod+3 workspace 3
			bindsym $mod+4 workspace 4
			bindsym $mod+Shift+1 move container to workspace 1
			bindsym $mod+Shift+2 move container to workspace 2
			bindsym $mod+Shift+3 move container to workspace 3
			bindsym $mod+Shift+4 move container to workspace 4
			bindsym $mod+Shift+r restart
			bindsym $mod+Shift+q exit
			mode "resize" {
              bindsym h resize shrink width 10 px or 10 ppt
		      bindsym j resize grow height 10 px or 10 ppt
              bindsym k resize shrink height 10 px or 10 ppt
              bindsym l resize grow width 10 px or 10 ppt
			  bindsym Return mode "default"
			  bindsym Escape mode "default"
		    }
		    bindsym $mod+r mode "resize"
		  '';
        };
      };
    };

    networking.networkmanager.enable = true;

    nixpkgs.config.allowUnfree = true;

    nix.settings.experimental-features = [ "nix-command" "flakes"];

    security.polkit.enable = true;

	fonts = {
      enableDefaultPackages = true;
      fontDir.enable = true;
      packages = with pkgs; [
        nerd-fonts.blex-mono      # Latin + Nerd icons
        sarasa-gothic             # CJK
	  ];
      fontconfig = {
        enable = true;
        defaultFonts = {
          monospace = [
            "BlexMono"           # Primary: Latin + all Nerd Font symbols
            "Sarasa Mono J"      # Fallback: Japanese characters (double-width)
          ];
          sansSerif = [ "BlexMono" "Sarasa Gothic J" ];
          serif     = [ "BlexMono" "Sarasa Gothic J" ];
          emoji     = [ "Symbols Nerd Font" ];
        };
      };
    };

    environment.systemPackages = with pkgs; [
    # Critical packages for system Function
	  st  vim
	  git  wget
      yazi  lynx
    # Nice to Have Terminal Utilities
      fzf  eza  bat  dust  tldr  atuin  zellij
	  atop  btop  htop  powertop  fastfetch
	  brightnessctl
    # Nice to Have GUIs
  	  ungoogled-chromium
      mpv
      imv
    ];

  # Seting Chromium, vim, imv and mpv as defaults system wide
	xdg.mime.enable = true;
	xdg.mime.defaultApplications = {
      # === Web / Default ===
      "text/html" = "chromium-browser.desktop";
      "x-scheme-handler/http" = "chromium-browser.desktop";
      "x-scheme-handler/https" = "chromium-browser.desktop";
      "x-scheme-handler/about" = "chromium-browser.desktop";
      "x-scheme-handler/unknown" = "chromium-browser.desktop";

      # === Images ===
      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/svg+xml" = "imv.desktop";
      "image/bmp" = "imv.desktop";
      "image/tiff" = "imv.desktop";
      "image/avif" = "imv.desktop";
      "image/heic" = "imv.desktop";
      "image/*" = "imv.desktop";

      # === Audio ===
      "audio/mpeg" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "audio/wav" = "mpv.desktop";
      "audio/aac" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/mp4" = "mpv.desktop";
      "audio/webm" = "mpv.desktop";
      "audio/*" = "mpv.desktop";

      # === Video ===
      "video/mp4" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/ogg" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";   # .mkv
      "video/quicktime" = "mpv.desktop";   # .mov
      "video/x-msvideo" = "mpv.desktop";   # .avi
      "video/mp2t" = "mpv.desktop";        # .ts
      "video/*" = "mpv.desktop";

      # === Text ===
	  "text/plain" = "vim.desktop";
      "text/*" = "vim.desktop";
      "application/json" = "vim.desktop";
      "application/x-shellscript" = "vim.desktop";
      "application/xml" = "vim.desktop";
      "application/yaml" = "vim.desktop";
      "application/toml" = "vim.desktop";
	};

  # Setting up yazi to open things propperly
	programs.yazi = {
      enable = true;
      settings = {
        yazi = {
        # === Text ===
					opener = {
            edit = [{
		      run = ''${pkgs.vim}/bin/vim "$@"'';
			  desc = "Edit with Vim";
			  block = true; }
            ];
  
		  # === Media ===
            open = [{
		      run = ''${pkgs.chromium}/bin/chromium --new-window "$@"'';
			  desc = "Open in Chromium";
			  orphan = true;
			}];
            play = [{
		      run = ''${pkgs.chromium}/bin/chromium --new-window "$@"'';
			  desc = "Play in Chromium";
			  orphan = true; }
            ];
          };
        };
      };
    };
	environment.sessionVariables = {
      TERMINAL = "st";
      EDITOR = "vim";
      VISUAL = "vim";
    };
  };
}
