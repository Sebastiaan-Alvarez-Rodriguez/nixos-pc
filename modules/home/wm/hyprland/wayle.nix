# A Hyprland shell/bar 'wayle'.
# Provides a shell containing a bar with power menu, notification handler, and wifi/bluetooth handling etc.
{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.wm.hyprland.wayle;
in {
  options.my.home.wm.hyprland.wayle = with lib; {
    enable = mkEnableOption "Use wayle theme for hyprland";

    await-pipewire = mkEnableOption "Add wait conditions until pipewire (and wireplumber) are ready";

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
    services.wayle = { 
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

    # this ensures Wayle waits until audio modules have started (otherwise it cannot find the audio devices and defaults to 'Dummy Device')
    # systemd.user.services.wayle.Service.ExecStartPre = lib.mkIf cfg.await-pipewire (lib.mkForce "/bin/sh -c 'while ! ${pkgs.wireplumber}/bin/wpctl status >/dev/null 2>&1; do sleep 0.2; done'");
    systemd.user.services.wayle.Service.ExecStartPre = lib.mkIf cfg.await-pipewire (lib.mkForce "/bin/sh -c 'sleep 0.5'");
    systemd.user.services.wayle.Unit.After = lib.mkIf cfg.await-pipewire (lib.mkForce [ config.wayland.systemd.target "pipewire.service" "wireplumber.service" ]);
    systemd.user.services.wayle.Unit.Wants = lib.mkIf cfg.await-pipewire (lib.mkForce [ "pipewire.service" "wireplumber.service" ]);

    my.home.wm.hyprland.binds.extras = [
      { key = "${config.my.home.wm.hyprland.binds.modkey} + SHIFT + Z"; cat = "Launcher"; sub = "wayle"; desc = "restart wayle panel"; action = "hl.dsp.exec_cmd([[wayle panel restart]])"; }
      { key = "${config.my.home.wm.hyprland.binds.modkey} + Z"; cat = "Launcher"; sub = "wayle"; desc = "open wayle settings"; action = "hl.dsp.exec_cmd([[wayle panel settings]])"; }
    ];
  };
}
