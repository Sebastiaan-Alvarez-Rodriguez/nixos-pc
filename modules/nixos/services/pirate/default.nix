# The total autonomous media storage & delivery system.
{ config, lib, pkgs, ... }: let
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
      inherit (cfg.${service}) enable package user group;
    };

    my.services.nginx.virtualHosts.${service} = {
      port = ports.${service};
    };

    services.fail2ban.jails.${service} = {
      enabled = true;
      settings = {
        filter = "${service}";
        action = "iptables-allports";
      };
    };

    environment.etc."fail2ban/filter.d/${service}.conf".text = ''
      [Definition]
      failregex = ^.*\|Warn\|Auth\|Auth-Failure ip <HOST> username .*$
      journalmatch = _SYSTEMD_UNIT=${service}.service
    '';
  };


  mkDefaultOptions = service: with lib; {
    enable = mkEnableOption (builtins.getAttr service descriptions);

    package = mkOption {
      type = types.package;
      default = pkgs.${service};
      description = "${service} package to use";
    };

    user = mkOption {
      type = types.str;
      default = "${service}";
      description = "User under which ${service} runs";
    };

    group = mkOption {
      type = types.str;
      default = "media";
      description = "Group under which ${service} runs";
    };
  };
in {
  options.my.services.pirate = with lib; {
    bazarr = (mkDefaultOptions "bazarr") // {
      backup-path = mkOption {
        type = with types; nullOr path;
        default = "/var/lib/bazarr/backup";
      };
    };
    lidarr = mkDefaultOptions "lidarr" // {
      backup-path = mkOption {
        type = with types; nullOr path;
        default = "/var/lib/lidarr/.config/Lidarr/Backups";
      };
    };
    radarr = mkDefaultOptions "radarr" // {
      backup-path = mkOption {
        type = with types; nullOr path;
        default = "/var/lib/radarr/.config/Radarr/Backups";
      };
    };

    sonarr = mkDefaultOptions "sonarr"; # seb TODO: check if sonarr requires any backups

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
    };
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
      my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [] ++
        (lib.optional cfg.bazarr.enable cfg.bazarr.backup-path) ++
        (lib.optional cfg.lidarr.enable cfg.lidarr.backup-path) ++
        (lib.optional cfg.radarr.enable cfg.radarr.backup-path);
      };
    }

    (mkConfig "bazarr") # NOTE: Bazarr does not log authentication failures...
    (mkConfig "lidarr")
    (mkConfig "radarr")
    (mkConfig "sonarr")

    (lib.mkIf cfg.lidarr.enable {
      my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.lidarr.backup-path ]; };
    })
  ]);
}
