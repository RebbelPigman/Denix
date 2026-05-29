{ self, inputs, ... }: {

  flake.homeModules.kitty = { pkgs, lib, ... }: {
    programs = {
      bash.enable = true;
 	  fish = {
        enable = true;
        interactiveShellInit = ''
          set fish_greeting # Disable greeting
        '';
        plugins = [
          { name = "grc"; src = lib.getExe pkgs.fishPlugins.grc.src; }
        ];
      };
      kitty = {
        enable = true;
 	    settings = {
 		  font_family = "BlexMono Nerd Font Mono";
 		  bold_font = "auto";
          italic_font = "auto";
          clear_all_shortcuts = "yes";
          confirm_os_window_close = 0;
          shell_integration = "enabled";
 		  shell = "fish";
        };
   	    extraConfig = ''
   		  include themes/noctalia.conf
          map control+shift+v paste_from_clipboard
          map control+shift+c copy_to_clipboard
          map alt+j scroll_line_down 
   		  map alt+k scroll_line_up 
   		  map alt+t new_tab 
   		  map alt+q close_tab
   		  map alt+h previous_tab 
   		  map alt+l next_tab 
   		  map control+alt+h move_tab_backward
   		  map control+alt+l move_tab_forward
   		  map control+shift+t set_tab_title 
   		  map control+k move_window up
   		  map control+j move_window down
   		  map control+h move_window left
   		  map control+l move_window right
   		  map alt+v launch --location=vsplit
   		  map alt+c launch --location=hsplit
		  map alt+y launch yazi
		  map --allow-fallback=shifted,ascii ctrl+shift+w close_window
        '';
	  };
    };
  };
}
 
