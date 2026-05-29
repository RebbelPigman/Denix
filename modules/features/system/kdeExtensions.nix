{ self, inputs, ... }: {
  flake.nixosModules.kdeExtensions = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      kdePackages.konqueror
      kdePackages.calligra
      kdePackages.kdenlive
	  kdePackages.kontact
	  kdePackages.kwave
	  krita
    ];
  };
}

