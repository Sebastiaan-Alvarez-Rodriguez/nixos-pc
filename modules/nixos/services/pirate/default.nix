# The total autonomous media storage & delivery system.
{ config, lib, ... }: let
  cfg = config.my.services.pirate;

  descriptions = {
    bazarr = "For radarr & sonarr subtitles";
    lidarr = "For music";
    radarr = "For movies";
    sonarr = "For shows";
  };

  ports = {
    bazarr = 6767;
    lidarr = 8686;
    radarr = 7878;
    sonarr = 8989;
  };

  mkConfig = service: lib.mkIf cfg.${service}.enable {
    services.${service} = {
      inherit (cfg) enable package user group;
    };

    my.services.nginx.virtualHosts.${service} = {
      port = ports.${service};
    };

    services.fail2ban.jails = {
      ${service} = ''
        enabled = true
        filter = ${service}
        action = iptables-allports
      '';
    };

    environment.etc = {
      "fail2ban/filter.d/${service}.conf".text = ''
        [Definition]
        failregex = ^.*\|Warn\|Auth\|Auth-Failure ip <HOST> username .*$
        journalmatch = _SYSTEMD_UNIT=${service}.service
      '';
    };
  };


  mkDefaultOptions = service: with lib; {
    enable = mkEnableOption (builtins.getAttr service descriptions);

    package = mkOption {
      type = types.package;
      default = pkgs.${service};
      description = "${service} package to use";
    };

    user = mkOption {
      type = types.string;
      default = "${service}";
      description = "User under which ${service} runs";
    };

    group = mkOption {
      type = types.string;
      default = "media";
      description = "Group under which ${service} runs";
    };
  };
in {
  options.my.services.pirate = with lib; {
    bazarr = mkDefaultOptions "bazarr";
    lidarr = mkDefaultOptions "lidarr";
    radarr = mkDefaultOptions "radarr";
    sonarr = mkDefaultOptions "sonarr";
  };

  config = (lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.bazarr.enable -> (cfg.radarr.enable || cfg.sonarr.enable);
          message = "Enabled bazarr, which provides subtitles for radarr and sonarr, but forgot to enable any of (radarr, sonarr).";
        }
      ];
      users.groups.media = { }; # Set-up media group. NOTE: Do not forget to allow write permission of media group to media folder(s).
    }

    (mkConfig "bazarr") # NOTE: Bazarr does not log authentication failures...
    (mkConfig "lidarr")
    (mkConfig "radarr")
    (mkConfig "sonarr")
  ]);
}
