# A FLOSS media server
{ config, lib, ... }: let
  cfg = config.my.services.jellyfin;
in {
  options.my.services.jellyfin = with lib; {
    enable = mkEnableOption "Jellyfin Media Server";
    port = mkOption {
      type = types.port;
      default = 8096;
      description = "Internal port for webui";
    };
  };

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      group = "media";
    };

    users.groups.media = { }; # Set-up media group

    systemd.services.jellyfin = {
      serviceConfig = { # Loose umask to make Jellyfin metadata more broadly readable
        UMask = lib.mkForce "0002";
      };
    };

    my.services.nginx.virtualHosts = {
      jellyfin = {
        inherit (cfg) port;
        extraConfig = {
          locations."/" = {
            extraConfig = ''
              proxy_buffering off;
            '';
          };
          # Too bad for the repetition...
          locations."/socket" = {
            proxyPass = "http://127.0.0.1:${toString cfg.port}/";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
