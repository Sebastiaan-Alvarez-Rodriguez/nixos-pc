{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.wpaperd;
  pkg = pkgs.wpaperd;
in {
  config = lib.mkIf cfg.enable { # seb: NOTE https://github.com/anufrievroman/waypaper would also be nice.
    assertions = [
      {
        assertion = config.my.home.gm.manager == "wayland";
        message = "wpaperd module requires wayland graphics manager (set my.home.gm.manager = \"wayland\")";
      }
    ];
    
    programs.wpaperd = { # seb: TODO https://stackoverflow.com/questions/21830670
      enable = true;
      package = pkg;
      settings = {
        default = {
          path = builtins.fetchurl { # Nice ones available from https://steamcommunity.com/sharedfiles/filedetails/?id=2917197433
            url = "https://w.wallhaven.cc/full/p9/wallhaven-p9586j.png"; # url must have an extension in order for wpaperd to understand it.
            sha256 = "07181c8d3e3a33b09acfb65adeb1d30b8efbf15a3c0300954893263708d0c855";
          };
          # duration = "30m";
          apply-shadow = true;
          sorting = "random";
        };
      };
    };

    systemd.user.services.wpaperd = {
      Unit.After = [ "river-session.target" ];
      Service = {
        ExecStart = "${pkg}/bin/wpaperd";
      };
    };
  };
}
