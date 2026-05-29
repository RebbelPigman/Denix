{ self, inputs, ... }: {
  flake.nixosModules.kdeUtilities = { pkgs, ... }: {
    environment.systemPackages = with pkgs ; [
      kdePackages.kolourpaint
      kdePackages.gwenview 
	  kdePackages.dolphin
	  kdePackages.francis
	  kdePackages.dragon
	  kdePackages.kamoso
	  kdePackages.okular
      kdePackages.elisa
      kdePackages.qt6ct
	  kdePackages.kalk
	  kdePackages.kate
	  kdePackages.ark
      adw-gtk3
      nwg-look
	  karp
    ];
	
  };
}
