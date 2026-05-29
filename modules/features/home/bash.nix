
{ self, inputs, ... }: {

  flake.homeModules.bash = { pkgs, ... }: {
    programs.bash = {
      enable = true;
      shellAliases = {
        ff = "fastfetch";
		noctalia-save = "nix run nixpkgs#noctalia-shell ipc call state all > ~/.nixos/modules/features/noctalia.json";
		nixos-test = "nixos-rebuild test --cores 4 --sudo --flake ~/.nixos#Lenovus";
		nixos-switch = "nix-collect-garbage --delete-older-than 30d && nixos-rebuild switch --cores 4 --sudo --flake ~/.nixos#Lenovus";
		nixos-edit = "cd ~/.nixos && nvim";
		notes = "cd ~/Dropbox/Obsidian && nvim";
		tasks = "cd ~/Dropbox/Obsidian/ToDo && nvim ToDoList.md";
      };
    };
  };
}
