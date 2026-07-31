# A Hyprland shell/bar 'wayle'.
# Provides a shell containing a bar with power menu, notification handler, and wifi/bluetooth handling etc.
{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.wm.hyprland.wayle;
in {
  options.my.home.wm.hyprland.wayle = with lib; {
    enable = mkEnableOption "Use wayle theme for hyprland";

    extra-config = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Extra lines to append to config of wayle.
        Note: Using the wayle settings menu, it is possible to change config at runtime.
        Default runtime config location: ~/.config/wayle/runtime.toml
        Default base config location: ~/.config/wayle/config.toml
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.wayle = { # 
      enable = true;
      autoInstallDependencies = true;
      settings = {
        styling = {
          theme-provider = "wayle";
          palette = lib.mkIf config.my.home.stylix.enable { # stylix style integration
            bg = config.lib.stylix.colors.withHashtag.base00;
            surface = config.lib.stylix.colors.withHashtag.base01;
            elevated = config.lib.stylix.colors.withHashtag.base02;
            fg = config.lib.stylix.colors.withHashtag.base05;
            fg-muted = config.lib.stylix.colors.withHashtag.base04;
            primary = config.lib.stylix.colors.withHashtag.base0D; # Blue / Accent
            red = config.lib.stylix.colors.withHashtag.base08;
            yellow = config.lib.stylix.colors.withHashtag.base0A;
            green = config.lib.stylix.colors.withHashtag.base0B;
            blue = config.lib.stylix.colors.withHashtag.base0D;
          };
        };
      } // cfg.extra-config;
    };

    my.home.wm.hyprland.binds.extras = [
      { key = "${config.my.home.wm.hyprland.binds.modkey} + SHIFT + Z"; cat = "Launcher"; sub = "wayle"; desc = "restart wayle panel"; action = "hl.dsp.exec_cmd([[wayle panel restart]])"; }
      { key = "${config.my.home.wm.hyprland.binds.modkey} + Z"; cat = "Launcher"; sub = "wayle"; desc = "open wayle settings"; action = "hl.dsp.exec_cmd([[wayle panel settings]])"; }
    ];
  };
}
