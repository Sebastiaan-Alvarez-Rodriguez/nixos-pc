{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.wpaperd;
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.home.gm.manager == "wayland";
        message = "wpaperd module requires wayland graphics manager (set my.home.gm.manager = \"wayland\")";
      }
    ];

    programs.wpaperd = {
      enable = true;
      settings = {
        default = {
          path = ../../res/background; # seb: NOTE was absolute path: "${config.home.homeDirectory}/Pictures/Wallpapers"
          duration = "30m";
          apply-shadow = true;
          sorting = "random";
        };
      };
    };

    systemd.user.services.wpaperd = { # NOTE user services: https://haseebmajid.dev/posts/2023-10-08-how-to-create-systemd-services-in-nix-home-manager/
      Install.after = [ "river-session.target" ]; # seb: TODO used to be just 'after'
      serviceConfig = {
        # ExecStart = "${pkgs.strip-dkim}/bin/strip-dkim";
      };
    };
  };
}
