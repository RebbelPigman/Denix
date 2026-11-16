{ self, inputs, ... }: {
  flake.nixosModules.core = { pkgs, lib, ... }:
  let
    batTheme = pkgs.fetchurl {
      name = "catppuccin-mocha.tmTheme";
      url = "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme";
      hash = "sha256-OVVm8IzrMBuTa5HAd2kO+U9662UbEhVT8gHJnCvUqnc=";
    };
    btopTheme = pkgs.fetchurl {
      name = "catppuccin_mocha.theme";
      url = "https://raw.githubusercontent.com/catppuccin/btop/main/themes/catppuccin_mocha.theme";
      hash = "sha256-THRpq5vaKCwf9gaso3ycC4TNDLZtBB5Ofh/tOXkfRkQ=";
    };
    atuinTheme = pkgs.fetchurl {
      name = "catppuccin-mocha-mauve.toml";
      url = "https://raw.githubusercontent.com/catppuccin/atuin/main/themes/mocha/catppuccin-mocha-mauve.toml";
      hash = "sha256-X66L7YmWQ4ClPeQoFhXkkWXPrmpLwWfHcDNbvnc+K3g=";
    };
    yaziFlavors = pkgs.fetchFromGitHub {
      owner = "yazi-rs";
      repo = "flavors";
      rev = "38c08d8eb9ea0d28c8c911a249a08f27ba2151ac";
      hash = "sha256-lITDt1QvL54u6gbJiGixPyP6lk72f3rkiNPDrUg6G8I=";
    };
    btopThemes = pkgs.runCommand "btop-themes" { } ''
      mkdir -p $out
      cp ${btopTheme} $out/catppuccin_mocha.theme
    '';
    btopConf = pkgs.writeText "btop.conf" ''
      color_theme = "catppuccin_mocha"
      theme_background = True
      truecolor = True
    '';
    swaylockConf = pkgs.writeText "swaylock.config" ''
      ignore-empty-password
      color=1e1e2e
      inside-color=1e1e2e
      inside-clear-color=1e1e2e
      inside-caps-lock-color=1e1e2e
      inside-ver-color=1e1e2e
      inside-wrong-color=1e1e2e
      key-hl-color=a6e3a1
      bs-hl-color=f38ba8
      caps-lock-key-hl-color=fab387
      caps-lock-bs-hl-color=f38ba8
      layout-bg-color=1e1e2e
      layout-border-color=1e1e2e
      layout-text-color=cdd6f4
      line-color=1e1e2e
      line-clear-color=1e1e2e
      line-caps-lock-color=1e1e2e
      line-ver-color=1e1e2e
      line-wrong-color=1e1e2e
      ring-color=cba6f7
      ring-clear-color=f9e2af
      ring-caps-lock-color=fab387
      ring-ver-color=89b4fa
      ring-wrong-color=f38ba8
      separator-color=1e1e2e
      text-color=cdd6f4
      text-clear-color=cdd6f4
      text-caps-lock-color=cdd6f4
      text-ver-color=cdd6f4
      text-wrong-color=cdd6f4
    '';
  in {
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

    # Future work. ungoogled-chromium 153 reads ExtensionInstallForcelist and
    # does not install. Do not turn this back on until an id directory appears
    # under ~/.config/chromium/Default/Extensions.
    # Vimium dbepggeogbaibhgnhhndojpepiihcmeb
    # Quillbot iidnbdjijdkbmajdffnidomddglmieko
    # Stylus clngdbkpkpeebahjckkjfobafhncgmne
    # Proton Pass ghmbeldphafepmbegfdlkpapadhbakde
    # programs.chromium = {
    #   enable = true;
    #   extensions = [ ];
    # };

    programs.bat = {
      enable = true;
      settings.theme = "Catppuccin Mocha";
    };

    programs.atuin = {
      enable = true;
      daemon.enable = false;
      enableFishIntegration = false;
      enableBashIntegration = false;
      enableZshIntegration = false;
      settings.theme.name = "catppuccin-mocha-mauve";
    };

    environment.systemPackages = with pkgs; [
    # Critical packages for system Function
	  kitty
      (vim-full.customize {
        name = "vim";
        vimrcConfig.customRC = ''
          set termguicolors
          set background=dark
          colorscheme catppuccin_mocha
        '';
        vimrcConfig.packages.catp = {
          start = [ vimPlugins.catppuccin-vim ];
        };
      })
	  git  wget
      yazi  lynx
    # Nice to Have Terminal Utilities
      fzf  eza  dust  tldr  zellij
	  atop  htop  powertop  fastfetch
	  brightnessctl
      (lib.hiPrio (writeShellScriptBin "btop" ''
        exec ${lib.getExe btop} --config ${btopConf} --themes-dir ${btopThemes} "$@"
      ''))
      (lib.hiPrio (writeShellScriptBin "swaylock" ''
        exec ${lib.getExe swaylock} --config ${swaylockConf} "$@"
      ''))
    # Nice to Have GUIs
  	  ungoogled-chromium
      mpv
      imv
    ];

    environment.etc."bat/themes/Catppuccin Mocha.tmTheme".source = batTheme;
    environment.etc."atuin/themes/catppuccin-mocha-mauve.toml".source = atuinTheme;
    environment.etc."mpv/mpv.conf".text = ''
      background-color='#1e1e2e'
      osd-color='#cdd6f4'
      osd-border-color='#1e1e2e'
      osd-shadow-color='#181825'
    '';
    environment.etc.imv_config.text = ''
      [options]
      background = 1e1e2e
    '';
    environment.etc."zellij/config.kdl".text = ''
      theme "catppuccin-mocha"
    '';
    environment.etc."fastfetch/config.jsonc".text = ''
      {
        "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
        "logo": { "color": { "1": "magenta", "2": "blue" } },
        "display": { "color": { "keys": "magenta", "title": "blue" } }
      }
    '';

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
      flavors.catppuccin-mocha = "${yaziFlavors}/catppuccin-mocha.yazi";
      settings = {
        theme.flavor.dark = "catppuccin-mocha";
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
      ZELLIJ_CONFIG_DIR = "/etc/zellij";
      FZF_DEFAULT_OPTS = "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --color=border:#313244,label:#cdd6f4";
    };
  };
}
