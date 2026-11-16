{ self, inputs, ... }: {
  # Shared Home Manager fish + kitty.
  # Import from a host home module:
  #   flake.homeModules.aureliusHome = { pkgs, lib, ... }: {
  #     imports = [ self.homeModules.catfish ];
  #     # host-only overlays below
  #   };
  flake.homeModules.catfish = { pkgs, lib, config, ... }: {
    programs.fish = {
      enable = true;
      shellAliases = {
        ff = "fastfetch";
        yz = "yazi";
        vi = "nvim";
        vim = "nvim";
      };
      shellAbbrs = {
        # hostName matches the flake attr on both current hosts
        nixos-test = "/run/wrappers/bin/sudo -n /run/current-system/sw/bin/nixos-rebuild test --flake ~/Dropbox/Projects/Denix";
        nixos-switch = "/run/wrappers/bin/sudo -n /run/current-system/sw/bin/nixos-rebuild switch --flake ~/Dropbox/Projects/Denix";
        nixos = "cd ~/Dropbox/Projects/Denix && hermes chat --toolsets terminal,file";
        program = "cd ~/Dropbox/Projects && hermes -p programmer chat --toolsets terminal,file";
        obsidian-hermes = "cd ~/Dropbox/Obsidian && hermes -p obsidian chat --toolsets terminal,file";
        hermes = "hermes chat";
        git-acp = {
          expansion = "git add -A && git commit -m \"%\" && env GIT_SSH_COMMAND='ssh -F ~/.ssh/config -o BatchMode=yes -o IdentitiesOnly=yes' git push";
          setCursor = true;
        };
      };
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';
    };

    programs.kitty = {
      enable = true;
      settings = {
        font_family = "BlexMono Nerd Font Mono";
        bold_font = "auto";
        italic_font = "auto";
        clear_all_shortcuts = "yes";
        confirm_os_window_close = 0;
        shell_integration = "enabled";
        shell = "fish";
        enabled_layouts = "tall";
      };
      themeFile = "Catppuccin-Mocha";
      extraConfig = ''
        include themes/noctalia.conf
        map control+shift+v paste_from_clipboard
        map control+shift+c copy_to_clipboard
        map alt+j next_window
        map alt+k previous_window
        map alt+h previous_tab
        map alt+l next_tab
        map alt+control+h move_tab_backward
        map alt+control+l move_tab_forward
        map alt+control+j move_window_forward
        map alt+control+k move_window_backward
        map control+shift+t set_tab_title
        map alt+t new_tab
        map alt+q close_tab
        map alt+v launch --location=split
        map alt+y launch yazi
        map alt+b launch lynx
        map alt+return launch nvim
      '';
    };

    home.packages = [
      pkgs.neovim
      pkgs.visidata
    ];

    # Mocha accents on the terminal background. visidata 3.4 has no hex;
    # a 256-color bg (235) reads grey next to kitty Mocha (#1e1e2e). Empty
    # color_default keeps kitty's bg.
    home.file.".visidatarc".text = ''
      from visidata import vd, options
      vd.themes["catppuccin-mocha"] = dict(
          color_default="",
          color_default_hdr="bold 183",
          color_bottom_hdr="underline 189",
          color_current_row="reverse",
          color_current_col="183",
          color_current_hdr="bold reverse",
          color_column_sep="243",
          color_key_col="183",
          color_edit_cell="111 blue",
          color_selected_row="on 183",
          color_note_row="223 yellow",
          color_note_type="111 blue",
          color_warning="216 yellow",
          color_error="211 red",
          color_status="bold 189",
          color_menu="189",
          color_menu_active="reverse 183",
          color_menu_help="243",
          color_active_status="reverse 183",
          color_inactive_status="243",
          color_working="bold 151 green",
          color_add_pending="151 green",
          color_change_pending="reverse 223 yellow",
          color_delete_pending="211 red",
          plot_colors="111 151 223 211 183 216",
      )
      options.theme = "catppuccin-mocha"
    '';


    # Mutable checkout so a later push to that repo lands on the next activation.
    # Do not clobber a checkout whose origin is not this repo.
    home.activation.pullNvim = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      url=https://github.com/RebbelPigman/nvim
      dest="$HOME/.config/nvim"
      git=${pkgs.git}/bin/git
      export GIT_TERMINAL_PROMPT=0
      run mkdir -p "$HOME/.config"
      if [ ! -e "$dest" ]; then
        if ! $git clone "$url" "$dest"; then
          echo "pullNvim: clone failed, left $dest absent" >&2
        fi
      elif [ -d "$dest/.git" ]; then
        origin=$($git -C "$dest" remote get-url origin 2>/dev/null || true)
        case "$origin" in
          *RebbelPigman/nvim*)
            if ! $git -C "$dest" pull --ff-only; then
              echo "pullNvim: pull failed, left $dest as-is" >&2
            fi
            ;;
          *)
            echo "pullNvim: left $dest (origin is not RebbelPigman/nvim)" >&2
            ;;
        esac
      else
        echo "pullNvim: left $dest (not a git checkout)" >&2
      fi
    '';
  };
}
