# A FLOSS media server
{ config, lib, ... }: let
  cfg = config.my.services.snapserver;
in {
  options.my.services.snapserver = {
    enable = lib.mkEnableOption "snapserver Media Server";
  };

  config = lib.mkIf cfg.enable {
    services.snapserver = {
      enable = true;
      group = "media";
    };

    my.services.nginx.virtualHosts.snapserver = {
      port = 8096;
      extraConfig = {
        locations."/" = {
          extraConfig = ''
            proxy_buffering off;
          '';
        };
        # Too bad for the repetition...
        locations."/socket" = {
          proxyPass = "http://127.0.0.1:8096/";
          proxyWebsockets = true;
        };
      };
    };
  };
}
