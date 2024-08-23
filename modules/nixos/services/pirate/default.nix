# The total autonomous media delivery system.
# Relevant link: https://youtu.be/I26Ql-uX6AM
{ config, lib, ... }: let
  cfg = config.my.services.pirate;

  ports = {
    bazarr = 6767;
    lidarr = 8686;
    radarr = 7878;
    sonarr = 8989;
  };

  mkService = service: {
    services.${service} = {
      enable = true;
      group = "media";
    };
  };

  mkRedirection = service: {
    my.services.nginx.virtualHosts.${service} = {
      port = ports.${service};
    };
  };

  mkFail2Ban = service: lib.mkIf cfg.${service}.enable {
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

  mkFullConfig = service: lib.mkIf cfg.${service}.enable (lib.mkMerge [
    (mkService service)
    (mkRedirection service)
  ]);
in {
  options.my.services.pirate = with lib; {
    enable = mkEnableOption "Media automation";

    bazarr = {
      enable = mkEnableOption "Bazarr - For radarr & sonarr subtitles";
    };

    lidarr = {
      enable = mkEnableOption "Lidarr - For music";
    };

    radarr = {
      enable = mkEnableOption "Radarr - For movies";
    };

    sonarr = {
      enable = mkEnableOption "Sonarr - For shows";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.enable -> (cfg.bazarr.enable || cfg.lidarr.enable || cfg.radarr.enable || cfg.sonarr.enable);
          message = "No service is enabled (bazarr=${builtins.toString cfg.bazarr.enable}, lidarr=${builtins.toString cfg.lidarr.enable}, radarr=${builtins.toString cfg.radarr.enable}, sonarr=${builtins.toString cfg.sonarr.enable})";
        }
        {
          assertion = cfg.bazarr.enable -> (cfg.radarr.enable || cfg.sonarr.enable);
          message = "Enabled bazarr, which provides subtitles for radarr and sonarr, but forgot to enable any of (radarr, sonarr).";
        }
      ];
      # Set-up media group
      users.groups.media = { };
    }
    # Bazarr does not log authentication failures...
    (mkFullConfig "bazarr")

    (mkFullConfig "lidarr")
    (mkFail2Ban "lidarr")
    # Radarr for movies
    (mkFullConfig "radarr")
    (mkFail2Ban "radarr")
    # Sonarr for shows
    (mkFullConfig "sonarr")
    (mkFail2Ban "sonarr")
  ]);
}
