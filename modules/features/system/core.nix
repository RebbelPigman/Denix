{ self, inputs, ... }: {
  flake.nixosModules.core = { pkgs, ... }: {
    imports = [
      self.nixosModules.sway
    ];

    # No Xorg. ly must not start or list an X session.
    # plasmax11.desktop still exists in the plasma session package;
    # an empty xsessions dir keeps it out of ly.
    services.displayManager.ly = {
      enable = true;
      x11Support = false;
      settings = {
        x_cmd = "";
        xauth_cmd = "";
        xsessions = "${pkgs.runCommand "no-xsessions" { } ''
          mkdir -p $out
        ''}";
      };
    };
    services.gnome.gnome-keyring.enable = true;
    services.xserver.enable = false;

    networking.networkmanager.enable = true;

    nixpkgs.config.allowUnfree = true;

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # Hermes Agent flake has no cache.nixos.org hits; CI pushes to this public cache.
      extra-substituters = [ "https://hermes-agent.cachix.org" ];
      extra-trusted-public-keys = [
        "hermes-agent.cachix.org-1:jN3pjR50Mxi4SESKC/FIMNM6/LCosvPk2VUwzVvebzU="
      ];
      connect-timeout = 30;
      stalled-download-timeout = 300;
    };

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
	  kitty  vim
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
		      run = ''${pkgs.ungoogled-chromium}/bin/chromium --new-window "$@"'';
			  desc = "Open in Chromium";
			  orphan = true;
			}];
            play = [{
		      run = ''${pkgs.mpv}/bin/mpv "$@"'';
			  desc = "Play in mpv";
			  orphan = true; }
            ];
          };
        };
      };
    };
	environment.sessionVariables = {
      TERMINAL = "kitty";
      EDITOR = "vim";
      VISUAL = "vim";
    };
  };
}
