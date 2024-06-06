{ config, lib, pkgs, ... }:
let
  cfg = config.my.home.gtk;
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
        package = inputs.self.packages.${pkgs.system}.breeze-obsidian-cursor-theme;
        name = "Breeze_Obsidian";
      };
      iconTheme = {
        package = pkgs.numix-icon-theme-circle;
        name = "Numix-Circle-Light";
      };
    };
    # For good measure
    home.file.".icons/default".source = "${inputs.self.packages.${pkgs.system}.breeze-obsidian-cursor-theme}/share/icons/Breeze_Obsidian";
  };
}
