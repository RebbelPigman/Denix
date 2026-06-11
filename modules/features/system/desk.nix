{ self, inputs, ... }: {
  flake.nixosModules.desk = { pkgs, ... }: {
    environment.systemPackages = with pkgs ; [
#      kdePackages.gwenview 
#	   kdePackages.dolphin
#      kdePackages.francis
#      kdePackages.kamoso
#      kdePackages.dragon
#      kdePackages.okular
#      kdePackages.elisa
#      kdePackages.kate
      kdePackages.kolourpaint
      kdePackages.qt6ct
	  kdePackages.kalk
	  kdePackages.ark
	  qalculate-gtk
	  libreoffice
	  pdfarranger
	  texstudio
	  adw-gtk3
      nwg-look
	  zathura
	  rmpc
	  vlc
    ];
	
  };
}
