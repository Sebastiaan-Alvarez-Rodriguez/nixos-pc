{ config, lib, pkgs, inputs, ... }:
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
        package = pkgs.custompkgs.breeze-obsidian-cursor;
        name = "Breeze_Obsidian";
      };
      iconTheme = {
        package = pkgs.numix-icon-theme-circle;
        name = "Numix-Circle-Light";
      };
    };
    # For good measure
    # seb: NOTE was: home.file.".icons/default".source = "${inputs.self.packages.${pkgs.system}.breeze-obsidian-cursor-theme}/share/icons/Breeze_Obsidian";
    home.file.".icons/default".source = "${pkgs.custompkgs.breeze-obsidian-cursor}/share/icons/Breeze_Obsidian";
  };
}
