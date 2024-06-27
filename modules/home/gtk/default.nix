{ config, lib, pkgs, inputs, system, ... }:
let
  cfg = config.my.home.gtk;
  breeze-obsidian-cursor = inputs.self.packages.x86_64-linux.breeze-obsidian-cursor;
in {
  options.my.home.gtk = with lib; {
    enable = mkEnableOption "GTK configuration";
  };

  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;
      theme = {
        package = pkgs.numix-gtk-theme;
        name = "Numix";
      };
      cursorTheme = {
        package = breeze-obsidian-cursor;
        name = "Breeze_Obsidian";
      };
      iconTheme = {
        package = pkgs.numix-icon-theme-circle;
        name = "Numix-Circle-Light";
      };
    };
    # For good measure
    # seb: NOTE was: home.file.".icons/default".source = "${inputs.self.packages.${pkgs.system}.breeze-obsidian-cursor-theme}/share/icons/Breeze_Obsidian";
    home.file.".icons/default".source = "${breeze-obsidian-cursor}/share/icons/Breeze_Obsidian";
  };
}
